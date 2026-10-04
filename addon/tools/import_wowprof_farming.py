#!/usr/bin/env python3
"""Import WoW-Professions.com's classic farming routes into Evergreen_Farming/Farm_Data.lua.

WoW-Professions draws its mining / herbalism / leather routes on zone map images; there are no
coordinates. This script turns each image into an in-game route:

  1. download the guide pages and their route images (cached; ~1 s between requests)
  2. register the image against the zone's own world-map art (the 1002x668 zone PNGs exported from
     the WoW Forever client, see Hearthbreak's forever-port export): SIFT keypoints + RANSAC for a
     per-axis scale + offset, so image pixels map to zone coordinates (0-100)
  3. find the drawn route: pixels that differ from the warped map art AND have the route's colour
     (cream, white, black, red, orange), skeletonize, build a graph, prune arrowhead spurs, walk it
     into one ordered polyline (straightest continuation at junctions, jumps over gaps); arrowheads
     vote for the direction
  4. hybrid points: for ore / herb routes, GatherMate2's spawn points of the guide's nodes within
     SNAP_YARDS of the path, ordered along it, with traced path points kept where nodes are far
     apart; leather / skinning routes keep the traced path only (areas become loops around them)
  5. write Farm_Data.lua and a verification PNG per route (route + points drawn back on the image)

The output is WoW-Professions' content: Farm_Data.lua is generated, not committed (the repo is
public). Run:  python import_wowprof_farming.py [--only durotar] [--offline]
Needs numpy, pillow, scikit-image, scipy.
"""
import argparse, html, json, math, os, re, sys, time, urllib.request
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
from scipy.spatial import cKDTree
from skimage.color import rgb2gray
from skimage.feature import SIFT, match_descriptors
from skimage.morphology import skeletonize

HERE = os.path.dirname(os.path.abspath(__file__))
SITE = "https://www.wow-professions.com"
PAGES = [  # (path under /classic/, kind)
    ("copper-ore-farming", "ore"), ("tin-ore-farming", "ore"), ("iron-ore-farming", "ore"),
    ("mithril-ore-farming", "ore"), ("thorium-ore-farming", "ore"),
    ("farming/light-leather-farming-wow-classic", "leather"), ("farming/medium-leather-farming-wow-classic", "leather"),
    ("farming/heavy-leather-farming-wow-classic", "leather"), ("farming/thick-leather-farming-wow-classic", "leather"),
    ("farming/rugged-leather-farming-wow-classic", "leather"),
    ("mining-leveling-guide-classic-wow", "mining"), ("herbalism-leveling-guide-classic-wow", "herbalism"),
    ("skinning-leveling-guide-classic-wow", "skinning"),
]
DEFAULT_ADDONS = r"E:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns"
DEFAULT_ZONES = r"E:/Project HearthBreak/tools/forever-port/export/zones"
ZONE_W, ZONE_H = 1002, 668

SNAP_YARDS = {"Ore": 60, "Herbs": 40}   # spawns this close to the drawn path are on the route
NODE_GAP_YARDS = 22    # spawns closer than this along the path: keep one (they share a spot)
PATH_GAP_YARDS = 140   # keep traced path points between nodes further apart than this (along the path)
PATH_STEP_YARDS = 110  # spacing of traced path points

# zone name -> classic uiMapID (the WoW Forever client uses the same ids)
UIMAP = {
    "Durotar": 1411, "Mulgore": 1412, "The Barrens": 1413, "Alterac Mountains": 1416, "Arathi Highlands": 1417,
    "Badlands": 1418, "Blasted Lands": 1419, "Tirisfal Glades": 1420, "Silverpine Forest": 1421,
    "Western Plaguelands": 1422, "Eastern Plaguelands": 1423, "Hillsbrad Foothills": 1424, "The Hinterlands": 1425,
    "Dun Morogh": 1426, "Searing Gorge": 1427, "Burning Steppes": 1428, "Elwynn Forest": 1429, "Deadwind Pass": 1430,
    "Duskwood": 1431, "Loch Modan": 1432, "Redridge Mountains": 1433, "Stranglethorn Vale": 1434,
    "Swamp of Sorrows": 1435, "Westfall": 1436, "Wetlands": 1437, "Teldrassil": 1438, "Darkshore": 1439,
    "Ashenvale": 1440, "Thousand Needles": 1441, "Stonetalon Mountains": 1442, "Desolace": 1443, "Feralas": 1444,
    "Dustwallow Marsh": 1445, "Tanaris": 1446, "Azshara": 1447, "Felwood": 1448, "Un'Goro Crater": 1449,
    "Moonglade": 1450, "Silithus": 1451, "Winterspring": 1452,
}
# image file name keyword -> zone (first match wins, so longer keys first)
ZONE_KEYS = [
    ("thousand-needles", "Thousand Needles"), ("dun-morogh", "Dun Morogh"), ("loch-modan", "Loch Modan"),
    ("blasted-lands", "Blasted Lands"), ("searing-gorge", "Searing Gorge"), ("alterac", "Alterac Mountains"),
    ("dustwallow", "Dustwallow Marsh"), ("eastern", "Eastern Plaguelands"), ("burning", "Burning Steppes"),
    ("hinterlands", "The Hinterlands"), ("hillsbrad", "Hillsbrad Foothills"), ("silverpine", "Silverpine Forest"),
    ("stonetalon", "Stonetalon Mountains"), ("winterspring", "Winterspring"), ("tirisfal", "Tirisfal Glades"),
    ("teldrassil", "Teldrassil"), ("darkshore", "Darkshore"), ("ashenvale", "Ashenvale"), ("barrens", "The Barrens"),
    ("arathi", "Arathi Highlands"), ("desolace", "Desolace"), ("tanaris", "Tanaris"), ("ungoro", "Un'Goro Crater"),
    ("felwood", "Felwood"), ("silithus", "Silithus"), ("stv", "Stranglethorn Vale"), ("feralas", "Feralas"),
    ("wetlands", "Wetlands"), ("duskwood", "Duskwood"), ("durotar", "Durotar"), ("mulgore", "Mulgore"),
    ("elwynn", "Elwynn Forest"), ("redridge", "Redridge Mountains"),
]

# guide item / herb names -> GatherMate2 node ids (GatherMate2/Constants.lua)
ORE_NODES = {
    "Copper Ore": [201], "Tin Ore": [202], "Iron Ore": [203], "Silver Ore": [204, 209], "Gold Ore": [205, 210],
    "Mithril Ore": [206, 207], "Truesilver Ore": [208, 211], "Thorium Ore": [214, 213, 215, 212],
}
HERBS = ["Peacebloom", "Silverleaf", "Earthroot", "Mageroyal", "Briarthorn", "Stranglekelp", "Bruiseweed",
         "Wild Steelbloom", "Grave Moss", "Kingsblood", "Liferoot", "Fadeleaf", "Goldthorn", "Khadgar's Whisker",
         "Wintersbite", "Firebloom", "Purple Lotus", "Arthas' Tears", "Sungrass", "Blindweed", "Ghost Mushroom",
         "Gromsblood", "Golden Sansam", "Dreamfoil", "Mountain Silversage", "Plaguebloom", "Icecap", "Black Lotus"]

# Per-image settings, keyed by the image's file name (without extension). Defaults come from the
# page kind (see style_for). Keys:
#   style   colours of the drawn route: any of cream, white, black, red, orange
#   areas   leather style: closed outlines are areas; the route walks around each outline
#   exclude [(x0, y0, x1, y1), ...] image pixels to ignore (labels, insets, watermark)
#   reverse walk the traced route the other way (when the arrowheads lose the vote)
#   approx  mark the route approximate (reason string)
#   drop    leave the image out (reason string)
WATERMARK = (0, 0.86, 1.0, 1.0)   # skinning maps: "WOW-PROFESSIONS.COM" along the bottom (fractions)
CONFIG = {
    "mining-leveling-mulgore": {"style": ["cream"], "exclude": [(0.835, 0.0, 1.0, 1.0)]},
    "mining-leveling-blasted-lands": {"exclude": [(0.57, 0.05, 1.0, 0.33)]},
    "mining-leveling-desolace": {"style": ["black"]},
    "classic-wow-iron-ore-farming-desolace": {"style": ["black"]},
    "mining-leveling-ashenvale": {"style": ["black"]},
    "classic-wow-thorium-farming-silithus": {"style": ["black"]},
    "dun-morogh-herbalism-leveling-m": {"style": ["black"]},
    "durotar-herbalism-leveling-m": {"style": ["black"]},
    "elwynn-forest-herbalism-leveling-m": {"style": ["black"]},
    "mulgore-herbalism-leveling-m": {"style": ["black"]},
    "teldrassil-herbalism-leveling-m": {"style": ["black"]},
    "hillsbrad-foothills-herbalism-leveling-m": {"style": ["cream", "white", "red"]},
    "wetlands-herbalism-leveling-m": {"style": ["cream", "white", "red"]},
    # skinning maps: skill labels drawn touching the route
    "feralas-skinning-map": {"exclude": [(0.27, 0.19, 0.435, 0.28), (0.62, 0.34, 0.70, 0.41), (0.645, 0.525, 0.72, 0.60)],
                             "approx": "several separate skill-range sections; follow the notes"},
    "Ungoro-skinning-map": {"exclude": [(0.26, 0.47, 0.435, 0.555)]},
    "loch-modan-skinning-map": {"exclude": [(0.575, 0.47, 0.627, 0.545)]},
}

# ---------------------------------------------------------------------------------------------- io
def fetch(url, path, offline):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return path
    if offline:
        raise SystemExit("missing from the cache (and --offline): " + url)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as r, open(path, "wb") as f:
        f.write(r.read())
    time.sleep(1.0)
    return path


def clean(s):
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s).replace("\xa0", " ").replace("\ufffd", " ")
    return re.sub(r"\s+", " ", s).strip()

# ------------------------------------------------------------------------------------------ pages
TOKEN = re.compile(r"<(h[1-4]|p|li|button)\b([^>]*)>(.*?)</\1>|<img\b([^>]*)>|<div\b([^>]*class=\"tab-content[^\"]*\"[^>]*)>", re.S | re.I)


def image_key(src):
    return os.path.splitext(os.path.basename(src))[0]


def parse_page(text, path, kind):
    """Route images on one page, each with its heading, notes and materials."""
    title = clean((re.search(r"<h1[^>]*>(.*?)</h1>", text, re.S) or [None, path])[1])
    body = text[text.find("<h1"):]
    end = body.find("Quick Links")
    if end > 0:
        body = body[:end]
    # route images sit inside <p>: split them out (but not the item icons inside "Ores in these zones")
    body = re.sub(r'(<img\b[^>]*src="/images/(?:classic|farmingmaps)/[^>]*>)', r"</p>\1", body)
    out = []
    section, sub, sec_paras, block, mats, prev_mats = "", "", [], [], [], []
    in_section_intro = True
    for m in TOKEN.finditer(body):
        tag, attrs, inner, imgattrs, divattrs = m.groups()
        if divattrs is not None:
            block, in_section_intro = [], False
            continue
        if imgattrs is not None:
            src = re.search(r'src="([^"]+)"', imgattrs)
            src = src and src.group(1)
            if not src or not re.match(r"/images/(classic|farmingmaps)/", src) or "icons" in src:
                continue
            out.append({"src": src, "key": image_key(src), "page": path, "kind": kind, "title": title,
                        "section": section, "sub": sub, "notes": list(block), "section_notes": list(sec_paras),
                        "mats": list(mats or prev_mats)})
            block, in_section_intro = [], False
            continue
        tag = tag.lower()
        t = clean(inner)
        if tag == "h1":
            continue
        if tag == "h2":
            section, sub, sec_paras, block = t, "", [], []
            prev_mats = mats or prev_mats
            mats = []
            in_section_intro = True
            continue
        if tag in ("h3", "h4"):
            sub, block, in_section_intro = t, [], False
            continue
        if tag == "button":
            in_section_intro = False
            continue
        if not t:
            continue
        found = re.match(r"(Ores|Herbs) in (these zones|[A-Z][\w' ]+)\s*:\s*(.*)", t)
        if found:
            mats = [x.strip(" .") for x in found.group(3).split(",") if x.strip(" .")]
            continue
        if in_section_intro:
            sec_paras.append(t)
        block.append(t)
    return title, out


def zone_of(key):
    k = key.lower()
    for kw, zone in ZONE_KEYS:
        if kw in k:
            return zone
    return None


def skill_range(s):
    m = re.search(r"(\d+)\s*-\s*(\d+)", s or "")
    return (int(m.group(1)), int(m.group(2))) if m else None


def gather_routes(cache, offline):
    """One entry per distinct image, merged across the pages that show it."""
    by_key, order = {}, []
    for path, kind in PAGES:
        p = fetch(SITE + "/classic/" + path, os.path.join(cache, "pages", path.replace("/", "_") + ".html"), offline)
        title, imgs = parse_page(open(p, encoding="utf-8", errors="replace").read(), path, kind)
        for e in imgs:
            e["page_title"] = title
            if e["key"] not in by_key:
                by_key[e["key"]] = []
                order.append(e["key"])
            by_key[e["key"]].append(e)
    routes = []
    for key in order:
        es = by_key[key]
        zone = zone_of(key)
        if not zone:
            print("  ! no zone for", key)
            continue
        r = {"key": key, "src": es[0]["src"], "zone": zone, "pages": [], "mats": [], "notes": "", "kinds": set()}
        farm = [e for e in es if e["kind"] in ("ore", "leather")]
        lev = [e for e in es if e["kind"] in ("mining", "herbalism", "skinning")]
        for e in es:
            r["kinds"].add(e["kind"])
            if e["page_title"] not in r["pages"]:
                r["pages"].append(e["page_title"])
        # materials: the farming page's own material, plus the leveling section's ores / herbs
        for e in farm:
            m = re.match(r"(.+?) Farming", e["page_title"])
            mat = m and m.group(1).replace(" Routes for Classic", "").strip()
            if mat and mat not in r["mats"]:
                r["mats"].append(mat)
        for e in lev:
            ms = e["mats"]
            if e["kind"] == "mining" and not ms:
                ms = [o for o in ORE_NODES if o in " ".join(e["section_notes"] + [e["section"]])] or ["Copper Ore"]
            for x in ms:
                if x not in r["mats"]:
                    r["mats"].append(x)
        # skill / level range
        for e in lev:
            rng = skill_range(e["section"])
            if rng:
                r["skill"] = rng
        for e in farm:
            for t in e["notes"]:
                m = re.search(r"(?:Mob )?[Ll]evel(?: range)?\s*:\s*(.+)", t)
                if m:
                    r["level"] = m.group(1).strip()
        # notes: the farming page's text for this zone first, then the leveling guide's
        notes = []
        for e in farm + lev:
            for t in e["notes"]:
                if re.search(r"(?:Mob )?[Ll]evel(?: range)?\s*:", t) or t in notes:
                    continue
                notes.append(t)
        if not farm:
            for e in lev:
                for t in e["section_notes"]:
                    if t not in notes and not re.match(r"(Visit|Don't forget|Learn) ", t):
                        notes.append(t)
        r["notes"] = " ".join(notes)
        r["heading"] = (farm[0]["section"] if farm else (lev[0]["sub"] or lev[0]["section"]))
        if "ore" in r["kinds"] or "mining" in r["kinds"]:
            r["category"] = "Ore"
        elif "herbalism" in r["kinds"]:
            r["category"] = "Herbs"
        else:
            r["category"] = "Leather"
        if "skinning" in r["kinds"] and not r["mats"]:
            r["mats"] = ["Skinning"]
        routes.append(r)
    return routes

# ----------------------------------------------------------------------------------- game data
def load_zones(zones_dir):
    u = json.load(open(os.path.join(HERE, "uimap_world.json")))
    pngs = {}
    for f in os.listdir(zones_dir):
        m = re.match(r"Zone_(\d+)_", f)
        if m:
            pngs[int(m.group(1))] = os.path.join(zones_dir, f)
    out = {}
    for name, mid in UIMAP.items():
        e = u.get(str(mid))
        if not e:
            continue
        r = e["region"]
        out[name] = {"map": mid, "png": pngs.get(e["area"]), "yw": r[4] - r[1], "yh": r[3] - r[0],
                     "cont": 1414 if e["map"] == 1 else 1415}
    return out


def load_gathermate(addons):
    base = os.path.join(addons, "GatherMate2_Data", "Era")
    names = {}
    const = open(os.path.join(addons, "GatherMate2", "Constants.lua"), encoding="utf-8").read()
    for n, i in re.findall(r'\[NL\["([^"]+)"\]\]\s*=\s*(\d+)', const):
        names.setdefault(int(i), n)
    nodes = {}
    for f in ("MiningData.lua", "HerbalismData.lua"):
        cur = None
        for line in open(os.path.join(base, f), encoding="utf-8"):
            m = re.match(r"\s*\[(\d+)\] = \{", line)
            if m:
                cur = int(m.group(1)); nodes.setdefault(cur, [])
                continue
            m = re.match(r"\s*\[(\d+)\] = (\d+),", line)
            if m and cur:
                c, nid = int(m.group(1)), int(m.group(2))
                nodes[cur].append((c // 1000000 / 100.0, (c // 100) % 10000 / 100.0, nid))
    return nodes, names


def node_ids_for(mats, names):
    ids = set()
    for m in mats:
        if m in ORE_NODES:
            ids.update(ORE_NODES[m])
        elif m in HERBS:
            for i, n in names.items():
                if n == m and 401 <= i <= 499:
                    ids.add(i)
    return ids

# -------------------------------------------------------------------------------- registration
_SIFT_CACHE = {}


def sift(gray):
    s = SIFT()
    s.detect_and_extract(gray)
    return s.keypoints, s.descriptors


def register(web, zone_png, target=None, key=None):
    """Fit zone_px = s * web_px + t per axis (row, col) from SIFT matches with RANSAC.
    With target (an RGB image) the fit is to that image's pixels instead of the zone art."""
    key = key or zone_png
    if key not in _SIFT_CACHE:
        z = target if target is not None else np.asarray(Image.open(zone_png).convert("RGB")).astype(float) / 255
        _SIFT_CACHE[key] = (z,) + sift(rgb2gray(z))
    z, kz, dz = _SIFT_CACHE[key]
    kw, dw = sift(rgb2gray(web))
    m = match_descriptors(dw, dz, max_ratio=0.8, cross_check=True)
    if len(m) < 4:
        return {"s": np.ones(2), "t": np.zeros(2), "inliers": 0, "matches": len(m), "rms": 99.0, "zone": z}
    a, b = kw[m[:, 0]], kz[m[:, 1]]
    rng = np.random.default_rng(0)
    best, bn = None, 0
    for _ in range(4000):
        i, j = rng.choice(len(a), 2, replace=False)
        d = a[i] - a[j]
        if abs(d[0]) < 15 or abs(d[1]) < 15:
            continue
        s = (b[i] - b[j]) / d
        if not (0.25 < s[0] < 5 and 0.25 < s[1] < 5) or abs(s[0] / s[1] - 1) > 0.2:
            continue
        t = b[i] - s * a[i]
        inl = np.linalg.norm(a * s + t - b, axis=1) < 3.0
        if inl.sum() > bn:
            bn, best = inl.sum(), inl
    if bn < 4:
        return {"s": np.ones(2), "t": np.zeros(2), "inliers": int(bn), "matches": len(a), "rms": 99.0, "zone": z}
    s, t = np.zeros(2), np.zeros(2)
    for k in (0, 1):
        A = np.c_[a[best, k], np.ones(bn)]
        s[k], t[k] = np.linalg.lstsq(A, b[best, k], rcond=None)[0]
    err = np.linalg.norm(a[best] * s + t - b[best], axis=1)
    return {"s": s, "t": t, "inliers": int(bn), "matches": len(a), "rms": float(np.sqrt((err ** 2).mean())), "zone": z}


def web_to_pct(T, rc):
    """web (row, col) array -> zone percent (x, y)."""
    zr = rc[:, 0] * T["s"][0] + T["t"][0]
    zc = rc[:, 1] * T["s"][1] + T["t"][1]
    return np.c_[zc / ZONE_W * 100, zr / ZONE_H * 100]


def pct_to_web(T, xy):
    xy = np.asarray(xy, float).reshape(-1, 2)
    zc, zr = xy[:, 0] / 100 * ZONE_W, xy[:, 1] / 100 * ZONE_H
    return np.c_[(zc - T["t"][1]) / T["s"][1], (zr - T["t"][0]) / T["s"][0]]   # (x, y) image pixels


def chain(Tref, Tb):
    """Tb maps this image to a reference image, Tref maps the reference to the zone."""
    return {"s": Tref["s"] * Tb["s"], "t": Tref["s"] * Tb["t"] + Tref["t"]}


def find_dots(web, d, route, scale):
    """Centres of the node markers drawn on the map (ore balls, herb icons): small blobs that are
    not map art and not route line. Returns image (x, y)."""
    cand = (d > 0.3) & ~ndi.binary_dilation(route, iterations=2)
    lab, n = ndi.label(cand, structure=np.ones((3, 3)))
    out = []
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        if sl is None:
            continue
        h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        comp = lab[sl] == i
        a = comp.sum()
        if 4 * scale <= max(h, w) <= 15 * scale and a >= 10 * scale * scale and a >= 0.35 * h * w:
            ys, xs = np.nonzero(comp)
            out.append((xs.mean() + sl[1].start, ys.mean() + sl[0].start))
    return np.array(out).reshape(-1, 2)


def dot_check(T, dots, nodes_pct, shape, radius):
    """How well GatherMate's spawn points land on the drawn node markers under T: matched pairs within
    radius (image px). Returns (median px, matched, spawns inside the image, pairs)."""
    if len(dots) == 0 or len(nodes_pct) == 0:
        return None, 0, 0, []
    P = pct_to_web(T, nodes_pct)
    H, W = shape
    inside = (P[:, 0] > 5) & (P[:, 0] < W - 5) & (P[:, 1] > 5) & (P[:, 1] < H - 5)
    tree = cKDTree(dots)
    d, i = tree.query(P)
    sel = inside & (d < radius)
    pairs = [(dots[i[k]], nodes_pct[k]) for k in np.nonzero(sel)[0]]
    return (float(np.median(d[sel])) if sel.any() else None), int(sel.sum()), int(inside.sum()), pairs


# ------------------------------------------------------------------------------------- overlay
def overlay_diff(web, T):
    H, W = web.shape[:2]
    rr, cc = np.mgrid[0:H, 0:W]
    zr, zc = rr * T["s"][0] + T["t"][0], cc * T["s"][1] + T["t"][1]
    Z = T["zone"]
    warp = np.stack([ndi.map_coordinates(Z[..., k], [zr, zc], order=1, mode="nearest") for k in range(3)], -1)
    inside = (zr >= 2) & (zr < ZONE_H - 2) & (zc >= 2) & (zc < ZONE_W - 2)
    fit = warp.copy()
    for k in range(3):   # the site's images are colour-graded a little: fit each channel linearly
        A = np.c_[warp[inside][:, k], np.ones(inside.sum())]
        p = np.linalg.lstsq(A, web[inside][:, k], rcond=None)[0]
        fit[..., k] = warp[..., k] * p[0] + p[1]
    d = np.abs(web - fit).sum(-1)
    d[~inside] = 0
    return d, inside


def colour_mask(web, style):
    R, G, B = web[..., 0], web[..., 1], web[..., 2]
    mx, mn = web.max(-1), web.min(-1)
    m = np.zeros(R.shape, bool)
    if "cream" in style:
        m |= (R > 0.78) & (G > 0.76) & (B > 0.38) & (B < 0.88) & (R - B > 0.10) & (np.abs(R - G) < 0.12)
    if "white" in style:
        m |= (mn > 0.78) & (mx - mn < 0.16)
    if "black" in style:
        m |= mx < 0.30
    if "red" in style:
        m |= (R > 0.45) & (G < 0.33) & (B < 0.30) & (R - G > 0.25)
    if "orange" in style:
        m |= (R > 0.80) & (G > 0.42) & (G < 0.78) & (B < 0.40) & (R - G > 0.15)
    return m


def style_for(r):
    k = r["key"]
    cfg = CONFIG.get(k, {})
    if "style" in cfg:
        return cfg["style"]
    if r["category"] == "Leather" and "skinning" not in r["kinds"]:
        return ["red"]
    if "skinning" in r["kinds"]:
        return ["cream", "orange"]
    if "herbalism" in k:
        return ["cream", "white"]
    return ["cream", "red"]


def route_mask(web, T, r, d, inside):
    """Pixels of the drawn route. d is the difference from the map art (None when the client's art
    is not the art in the image: then colour alone decides)."""
    cfg = CONFIG.get(r["key"], {})
    style = style_for(r)
    H, W = web.shape[:2]
    if d is None:
        ov = np.ones((H, W), bool)
        inset = np.zeros((H, W), bool)
        inside = ov
    else:
        ov = d > 0.28
        # screenshot insets and other pasted pictures: large areas that differ everywhere
        dens = ndi.uniform_filter(ov.astype(float), 41)
        inset = dens > 0.7
        lab, n = ndi.label(inset)
        if n:
            sizes = ndi.sum(inset, lab, range(1, n + 1))
            inset = np.r_[False, sizes > 2500][lab]
        inset = ndi.binary_dilation(inset, iterations=22)
    m = colour_mask(web, style) & ov & ~inset & inside
    # node dots (the ore / herb balls have pale highlights): small round specks, not line
    scale = W / 750.0
    lab, n = ndi.label(m, structure=np.ones((3, 3)))
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        if sl is not None and max(sl[0].stop - sl[0].start, sl[1].stop - sl[1].start) < 8 * scale:
            m[sl][lab[sl] == i] = False
    excl = list(cfg.get("exclude", []))
    if "skinning" in r["kinds"]:
        excl.append(WATERMARK)
    for x0, y0, x1, y1 in excl:
        if max(x0, y0, x1, y1) <= 1.0:
            x0, x1, y0, y1 = x0 * W, x1 * W, y0 * H, y1 * H
        m[int(y0):int(y1), int(x0):int(x1)] = False
    # the drawn line is a 2-3 px core with a dark rim and JPEG noise: thicken and smooth it so the
    # skeleton runs down the middle without a barb at every ragged pixel
    m = ndi.binary_dilation(m, structure=np.ones((3, 3)))
    m = ndi.binary_closing(m, structure=np.ones((3, 3)), iterations=2)
    lab, n = ndi.label(m, structure=np.ones((3, 3)))
    if n:
        sizes = ndi.sum(m, lab, range(1, n + 1))
        keep = np.zeros(n + 1, bool)
        keep[1:] = sizes >= 25
        m = keep[lab]
    if "red" in style and not is_area_map(r):
        m = drop_rings(m, web)
    return m, d, inset


def is_area_map(r):
    """Leather farming maps outline farming areas instead of drawing a route."""
    return r["category"] == "Leather" and "skinning" not in r["kinds"]


def drop_rings(m, web):
    """Red circles mark caves: small closed rings. Remove them (they are not route lines)."""
    R, G, B = web[..., 0], web[..., 1], web[..., 2]
    red = (R > 0.45) & (G < 0.33) & (B < 0.30) & (R - G > 0.25)
    lab, n = ndi.label(m, structure=np.ones((3, 3)))
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        if sl is None:
            continue
        h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        comp = lab[sl] == i
        if (red[sl] & comp).sum() < 0.5 * comp.sum():
            continue
        filled = ndi.binary_fill_holes(comp)
        if max(h, w) <= 34 and (filled.sum() - comp.sum()) > 0.15 * filled.sum():
            m[sl][comp] = False
    return m


def area_loops(m, min_hole=40):
    """Leather maps: closed outlines around farming areas. Returns each outline as a closed polyline
    (image x, y) around the area, or a single centre point for small circles."""
    lab, n = ndi.label(m, structure=np.ones((3, 3)))
    out = []
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        comp = lab == i
        filled = ndi.binary_fill_holes(comp)
        hole = filled & ~comp
        if hole.sum() < min_hole:
            continue
        # walk the outline's centreline: skeleton of the ring, ordered by angle around the centre
        sk = skeletonize(comp)
        ys, xs = np.nonzero(sk)
        cy, cx = np.nonzero(hole)
        cy, cx = cy.mean(), cx.mean()
        h = max(sl[0].stop - sl[0].start, sl[1].stop - sl[1].start)
        if h <= 34:
            out.append({"center": (cx, cy), "size": h})
            continue
        poly = ring_order(xs, ys)
        out.append({"loop": poly, "center": (cx, cy), "size": h})
    return out


def ring_order(xs, ys):
    """Order a ring's skeleton pixels by walking neighbours (nearest unvisited)."""
    pts = np.c_[xs, ys].astype(float)
    left = set(range(len(pts)))
    cur = int(np.argmin(pts[:, 0]))
    order = [cur]
    left.discard(cur)
    while left:
        idx = np.fromiter(left, int)
        d = np.hypot(*(pts[idx] - pts[cur]).T)
        j = idx[np.argmin(d)]
        if d.min() > 12:
            break
        order.append(j)
        left.discard(j)
        cur = j
    return pts[order]

# ---------------------------------------------------------------------------- skeleton graph
NB = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]


def build_graph(sk):
    pix = set(zip(*np.nonzero(sk)))
    def nbrs(p):
        return [(p[0] + a, p[1] + b) for a, b in NB if (p[0] + a, p[1] + b) in pix]
    deg = {p: len(nbrs(p)) for p in pix}
    nodepix = {p for p in pix if deg[p] != 2}
    # merge touching junction pixels into one node
    node_of, nodes = {}, []
    for p in nodepix:
        if p in node_of:
            continue
        stack, members = [p], []
        node_of[p] = len(nodes)
        while stack:
            q = stack.pop(); members.append(q)
            for r in nbrs(q):
                if r in nodepix and r not in node_of:
                    node_of[r] = len(nodes); stack.append(r)
        nodes.append(np.mean(members, axis=0))
    edges, used = [], set()
    for p in nodepix:
        for q in nbrs(p):
            if q in nodepix:
                if node_of[q] != node_of[p] and (p, q) not in used:
                    used.add((p, q)); used.add((q, p))
                    edges.append([node_of[p], node_of[q], [p, q]])
                continue
            if (p, q) in used:
                continue
            path, prev, cur = [p, q], p, q
            used.add((p, q))
            while cur not in nodepix:
                nx = [r for r in nbrs(cur) if r != prev and (cur, r) not in used]
                if not nx:
                    break
                used.add((cur, nx[0])); used.add((nx[0], cur))
                prev, cur = cur, nx[0]
                path.append(cur)
            used.add((path[-1], path[-2]))
            if cur in nodepix:
                edges.append([node_of[p], node_of[cur], path])
    # rings without any node
    seen = set(q for e in edges for q in e[2]) | nodepix
    for p in pix - seen:
        if p in seen:
            continue
        path, prev, cur = [p], None, p
        seen.add(p)
        while True:
            nx = [r for r in nbrs(cur) if r != prev and r not in seen]
            if not nx:
                break
            prev, cur = cur, nx[0]
            seen.add(cur); path.append(cur)
        nid = len(nodes); nodes.append(np.array(p, float))
        path.append(p)
        edges.append([nid, nid, path])
    return nodes, edges


def plen(path):
    a = np.asarray(path, float)
    return float(np.hypot(*np.diff(a, axis=0).T).sum()) if len(a) > 1 else 0.0


def prune(nodes, edges, spur):
    """Drop short dead-end branches (arrowhead barbs, JPEG noise). Returns the kept edges and the
    barbs as (junction, tip) pairs: a barb points back along the line, so the travel direction at
    that spot is from the barb's tip towards the junction and on."""
    barbs = []
    for _ in range(4):
        deg = {}
        for a, b, _p in edges:
            deg[a] = deg.get(a, 0) + 1
            deg[b] = deg.get(b, 0) + 1
        keep, changed = [], False
        for e in edges:
            a, b, p = e
            if a != b and plen(p) < spur and ((deg[a] == 1 and deg[b] >= 3) or (deg[b] == 1 and deg[a] >= 3)):
                j, tip = (b, a) if deg[a] == 1 else (a, b)
                barbs.append((nodes[j], nodes[tip]))
                deg[a] -= 1; deg[b] -= 1
                changed = True
                continue
            keep.append(e)
        edges = keep
        if not changed:
            break
    # tiny isolated bits
    deg = {}
    for a, b, _p in edges:
        deg[a] = deg.get(a, 0) + 1; deg[b] = deg.get(b, 0) + 1
    edges = [e for e in edges if not (deg[e[0]] == 1 and deg[e[1]] == 1 and plen(e[2]) < spur * 0.8)]
    return merge_deg2(edges), barbs


def merge_deg2(edges):
    """Join the two edges at every node left with exactly two (after pruning a barb)."""
    edges = [list(e) for e in edges]
    while True:
        at = {}
        for i, (a, b, p) in enumerate(edges):
            at.setdefault(a, []).append(i)
            if b != a:
                at.setdefault(b, []).append(i)
            else:
                at[a].append(i)
        k = next((k for k, v in at.items() if len(v) == 2 and v[0] != v[1]), None)
        if k is None:
            return edges
        i, j = at[k]
        a1, b1, p1 = edges[i]
        a2, b2, p2 = edges[j]
        if b1 != k:
            a1, b1, p1 = b1, a1, p1[::-1]
        if a2 != k:
            a2, b2, p2 = b2, a2, p2[::-1]
        new = [a1, b2, list(p1) + list(p2[1:])]
        edges = [e for n, e in enumerate(edges) if n not in (i, j)] + [new]


def bridge_ends(nodes, edges, maxgap):
    """Join dead ends that face each other across a small gap (arrow tips, breaks in the line, dashes)."""
    deg, out = {}, {}
    for a, b, p in edges:
        deg[a] = deg.get(a, 0) + 1
        deg[b] = deg.get(b, 0) + 1
    for a, b, p in edges:
        if a != b:
            out[a] = -direction(p)              # pointing out of the line at its start
            out[b] = -direction(p, end=True)
    ends = [k for k, d in deg.items() if d == 1]
    cand = []
    for i in range(len(ends)):
        for j in range(i + 1, len(ends)):
            a, b = ends[i], ends[j]
            v = nodes[b] - nodes[a]
            d = float(np.hypot(*v))
            if d > maxgap or d == 0:
                continue
            u = v / d
            fa, fb = float(np.dot(out[a], u)), float(np.dot(out[b], -u))
            if d > maxgap * 0.35 and (fa < 0.3 or fb < 0.3):
                continue
            cand.append((d * (2.2 - fa - fb * 0.5), a, b))
    cand.sort()
    used, new = set(), []
    for _s, a, b in cand:
        if a in used or b in used:
            continue
        used.update((a, b))
        new.append([a, b, [tuple(nodes[a]), tuple(nodes[b])]])
    return merge_deg2(edges + new), len(new)


def keep_route_parts(edges, gap, minlen, biglen):
    """Keep the biggest connected piece and the pieces near it (dashes, arrow gaps); drop far small
    fragments (map text, stray dots). Far pieces long enough to be a route of their own stay."""
    if not edges:
        return edges
    parent = {}
    def find(x):
        while parent.setdefault(x, x) != x:
            x = parent[x]
        return x
    for a, b, p in edges:
        parent[find(a)] = find(b)
    comps = {}
    for e in edges:
        comps.setdefault(find(e[0]), []).append(e)
    info = []
    for c, es in comps.items():
        pts = np.array([q for e in es for q in e[2]], float)
        info.append({"edges": es, "len": sum(plen(e[2]) for e in es), "pts": pts})
    info.sort(key=lambda c: -c["len"])
    kept = [info[0]]
    rest = info[1:]
    changed = True
    while changed:
        changed = False
        kp = np.vstack([c["pts"] for c in kept])
        tree = cKDTree(kp)
        for c in list(rest):
            d = tree.query(c["pts"])[0].min()
            if (c["len"] >= minlen and d <= gap) or c["len"] >= biglen:
                kept.append(c); rest.remove(c); changed = True
                break
    return [e for c in kept for e in c["edges"]]


def direction(path, n=8, end=False):
    a = np.asarray(path, float)
    if end:
        a = a[::-1]
    k = min(n, len(a) - 1)
    if k < 1:
        return np.zeros(2)
    v = a[k] - a[0]
    nv = np.hypot(*v)
    return v / nv if nv else v


def walk(nodes, edges):
    """Cover every edge once, straightest continuation at junctions, jumping to the nearest unvisited
    edge when stuck. Returns a list of (row, col) points and the jump count."""
    if not edges:
        return [], 0
    at = {}
    for i, (a, b, p) in enumerate(edges):
        at.setdefault(a, []).append(i)
        at.setdefault(b, []).append(i)
    deg = {k: len(v) for k, v in at.items()}
    ends = [k for k, d in deg.items() if d == 1]
    allpts = np.array([q for e in edges for q in e[2]], float)
    centre = allpts.mean(0)
    if ends:
        cur = max(ends, key=lambda k: np.hypot(*(nodes[k] - centre)))
    else:
        cur = edges[0][0]
    left = set(range(len(edges)))
    out, jumps, v = [], 0, None
    while left:
        cand = [i for i in at.get(cur, []) if i in left]
        if not cand:
            # nearest node with unvisited edges; prefer dead ends (route starts / ends)
            pos = np.asarray(out[-1], float) if out else nodes[cur]
            best, bd = None, 1e18
            for i in left:
                for k in (edges[i][0], edges[i][1]):
                    d = np.hypot(*(nodes[k] - pos)) * (0.85 if deg.get(k) == 1 else 1.0)
                    if d < bd:
                        best, bd = k, d
            cur = best
            jumps += 1
            v = None
            continue
        def score(i):
            a, b, p = edges[i]
            dv = direction(p) if a == cur else direction(p, end=True)
            return -1 if v is None else float(np.dot(v, dv))
        i = max(cand, key=score)
        a, b, p = edges[i]
        left.discard(i)
        path = p if a == cur else p[::-1]
        if a == b:   # a loop edge: walk it in the direction that turns least
            if v is not None and np.dot(v, direction(p)) < np.dot(v, direction(p[::-1])):
                path = p[::-1]
        out.extend(path)
        cur = b if a == cur else a
        v = direction(path, end=True) * -1
    return out, jumps


def rdp(pts, eps):
    pts = np.asarray(pts, float)
    if len(pts) < 3:
        return pts
    a, b = pts[0], pts[-1]
    ab = b - a
    n = np.hypot(*ab)
    if n == 0:
        d = np.hypot(*(pts - a).T)
    else:
        d = np.abs(ab[0] * (pts[:, 1] - a[1]) - ab[1] * (pts[:, 0] - a[0])) / n
    i = int(np.argmax(d))
    if d[i] > eps:
        return np.vstack([rdp(pts[:i + 1], eps)[:-1], rdp(pts[i:], eps)])
    return np.vstack([a, b])


def vote_direction(poly, barbs):
    """Sum of arrowhead votes along the polyline (image row, col). Positive = drawn direction."""
    if len(poly) < 2 or not barbs:
        return 0.0
    P = np.asarray(poly, float)
    seg = np.diff(P, axis=0)
    total = 0.0
    for j, tip in barbs:
        travel = np.asarray(j, float) - np.asarray(tip, float)   # tip -> junction
        nv = np.hypot(*travel)
        if nv == 0:
            continue
        d = np.hypot(*(P[:-1] - j).T)
        k = int(np.argmin(d))
        if d[k] > 6:
            continue
        sv = seg[k] / (np.hypot(*seg[k]) or 1)
        total += float(np.dot(sv, travel / nv))
    return total

# ---------------------------------------------------------------------------------- the route
def to_yards(xy, Z):
    return np.c_[xy[:, 0] * Z["yw"] / 100, xy[:, 1] * Z["yh"] / 100]


def resample(xy, Z, step):
    """Points every `step` yards along a zone-percent polyline."""
    if len(xy) < 2:
        return xy
    yd = to_yards(xy, Z)
    seg = np.hypot(*np.diff(yd, axis=0).T)
    s = np.r_[0, np.cumsum(seg)]
    n = max(1, int(round(s[-1] / step)))
    t = np.linspace(0, s[-1], n + 1)
    return np.c_[np.interp(t, s, xy[:, 0]), np.interp(t, s, xy[:, 1])]


def project(pt, yd, s):
    """Distance from pt (yards) to the polyline yd (yards) and the arc position of the foot."""
    a, b = yd[:-1], yd[1:]
    ab = b - a
    L2 = (ab ** 2).sum(1)
    L2[L2 == 0] = 1e-9
    u = np.clip(((pt - a) * ab).sum(1) / L2, 0, 1)
    foot = a + ab * u[:, None]
    d = np.hypot(*(foot - pt).T)
    k = int(np.argmin(d))
    return float(d[k]), float(s[k] + u[k] * np.sqrt(L2[k]))


def hybrid(xy, Z, nodes, loop, snap):
    """Spawn points near the path, ordered along it, with path points kept across long gaps."""
    yd = to_yards(xy, Z)
    s = np.r_[0, np.cumsum(np.hypot(*np.diff(yd, axis=0).T))]
    L = s[-1]
    near = []
    for x, y, nid, name in nodes:
        d, at = project(np.array([x * Z["yw"] / 100, y * Z["yh"] / 100]), yd, s)
        if d <= snap:
            near.append((at, x, y, name, d))
    near.sort()
    thin = []
    for n in near:   # several spawns at one spot (or both sides of the path): one stop
        if thin and n[0] - thin[-1][0] < NODE_GAP_YARDS and math.hypot((n[1] - thin[-1][1]) * Z["yw"] / 100,
                                                                     (n[2] - thin[-1][2]) * Z["yh"] / 100) < 2 * NODE_GAP_YARDS:
            continue
        thin.append(n)
    near = thin
    pts = []   # (arc, x, y, kind, name)
    def add_path(a0, a1):
        if a1 - a0 <= PATH_GAP_YARDS:
            return
        n = int((a1 - a0) // PATH_STEP_YARDS)
        for k in range(1, n + 1):
            a = a0 + (a1 - a0) * k / (n + 1)
            pts.append((a, float(np.interp(a, s, xy[:, 0])), float(np.interp(a, s, xy[:, 1])), "path", None))
    prev = 0.0
    if not near or near[0][0] > PATH_GAP_YARDS / 2:
        pts.append((0.0, float(xy[0, 0]), float(xy[0, 1]), "path", None))
    for at, x, y, name, d in near:
        add_path(prev, at)
        pts.append((at, x, y, "node", name))
        prev = at
    if loop:
        add_path(prev, L + (near[0][0] if near else 0))
    else:
        add_path(prev, L)
        if not near or L - near[-1][0] > PATH_GAP_YARDS / 2:
            pts.append((L, float(xy[-1, 0]), float(xy[-1, 1]), "path", None))
    pts.sort(key=lambda p: p[0])
    return [(p[1], p[2], p[3], p[4]) for p in pts], len(near)


def dedupe_nodes(raw, ids, names, Z, yards=12):
    out = []
    for x, y, nid in raw:
        if nid not in ids:
            continue
        ok = True
        for o in out:
            if math.hypot((o[0] - x) * Z["yw"] / 100, (o[1] - y) * Z["yh"] / 100) < yards:
                ok = False
                break
        if ok:
            out.append((x, y, nid, names.get(nid, str(nid))))
    return out

# ------------------------------------------------------------------------------------ process
REFS = {}   # zone -> [(image key, image, T)]: calibrated images, for images the zone art can't place
CACHE_DIR = None
HEARTHBREAK_CASC = r"E:/Project HearthBreak/tools/forever-port/casc"
LISTFILE = r"E:/Project HearthBreak/tools/forever-port/MultiConverter-bin/listfile.csv"
_ERA = {}


def era_art(Z, cache):
    """The zone's classic base map art (12 tiles, 1002x668) read from the Classic Era install through
    Hearthbreak's local CASC reader; cached as a PNG. For zones the Forever client redrew (Mulgore,
    Eastern Plaguelands): the site's images show the classic art. None when unavailable."""
    folder = os.path.splitext(os.path.basename(Z["png"] or ""))[0].split("_")[-1]
    if not folder:
        return None
    if folder in _ERA:
        return _ERA[folder]
    path = os.path.join(cache, "era", folder + ".png")
    if not os.path.exists(path):
        try:
            import io
            sys.path.insert(0, HEARTHBREAK_CASC)
            import casc_probe, forever_casc
            casc_probe.PRODUCT = "wow_classic_era"
            reader = forever_casc.Reader()
            tiles = {}
            pat = re.compile(r"interface/worldmap/%s/%s(\d+)\.blp$" % (folder.lower(), folder.lower()))
            for line in open(LISTFILE, encoding="utf-8"):
                fid, _, p = line.strip().partition(";")
                mm = pat.match(p)
                if mm:
                    tiles[int(mm.group(1))] = int(fid)
            out = Image.new("RGB", (1024, 768))
            for n in range(1, 13):
                im = Image.open(io.BytesIO(reader.read(tiles[n]))).convert("RGB")
                out.paste(im, (((n - 1) % 4) * 256, ((n - 1) // 4) * 256))
            os.makedirs(os.path.dirname(path), exist_ok=True)
            out.crop((0, 0, ZONE_W, ZONE_H)).save(path)
        except Exception as e:   # no Classic Era install / reader: the caller falls back
            print("  (no classic art for %s: %s)" % (folder, e))
            _ERA[folder] = None
            return None
    _ERA[folder] = np.asarray(Image.open(path).convert("RGB")).astype(float) / 255
    return _ERA[folder]


def spawns_for(r, Z, gm):
    """Every mining (or herb) spawn in the zone: what the map's node markers were drawn from."""
    lo, hi = (201, 219) if r["category"] == "Ore" else (401, 431) if r["category"] == "Herbs" else (0, -1)
    return np.array([(x, y) for x, y, nid in gm.get(Z["map"], []) if lo <= nid <= hi]).reshape(-1, 2)


def calibrate(r, web, Z, gm):
    """Image -> zone transform, the route mask, and how well it checks out:
       art   SIFT match against the client's zone art (the normal case)
       via   the client redrew the zone (Forever: Mulgore, Eastern Plaguelands): match an image of the
             same zone calibrated earlier instead
       dots  no usable reference: fit the drawn node markers to GatherMate2's spawn points
    Every ore / herb image is also checked against GatherMate2: the median distance from each spawn to
    the nearest drawn marker, and how many spawns found one."""
    H, W = web.shape[:2]
    scale = W / 750.0
    T = register(web, Z["png"])
    info = {"method": "art", "inliers": T["inliers"], "matches": T["matches"], "rms": T["rms"]}
    art_ok = T["inliers"] >= 150 and T["rms"] < 1.5
    redrawn = not art_ok
    if not art_ok:
        era = era_art(Z, CACHE_DIR)
        if era is not None:
            Te = register(web, None, target=era, key="era:" + r["zone"])
            if Te["inliers"] >= 150 and Te["rms"] < 1.5:
                T, art_ok = Te, True
                info = {"method": "classic-art", "inliers": T["inliers"], "matches": T["matches"], "rms": T["rms"]}
    if not art_ok:
        best = None
        for key, rw, rT in REFS.get(r["zone"], []):
            Tb = register(web, None, target=rw, key="ref:" + key)
            if Tb["inliers"] >= 150 and (best is None or Tb["inliers"] > best[0]["inliers"]):
                best = (Tb, rT, key)
        if best:
            T = dict(chain(best[1], best[0]), zone=T["zone"])
            info = {"method": "via " + best[2], "inliers": best[0]["inliers"], "matches": best[0]["matches"],
                    "rms": best[0]["rms"] * float(np.mean(best[1]["s"]))}
    d = inside = None
    if art_ok:
        d, inside = overlay_diff(web, T)
    m, _d, _inset = route_mask(web, T, r, d, inside)
    sp = spawns_for(r, Z, gm)
    if len(sp):
        dd = d if d is not None else np.abs(web - ndi.median_filter(web, size=(11, 11, 1))).sum(-1)
        dots = find_dots(web, dd, m, scale)
        med, n, tot, _p = dot_check(T, dots, sp, (H, W), 5 * scale)
        info.update({"dot_median": med, "dot_hits": n, "dot_spawns": tot, "dots": len(dots)})
    info["redrawn"] = redrawn
    good = art_ok or info["method"].startswith("via")
    if good:
        REFS.setdefault(r["zone"], []).append((r["key"], web, T))
    info["good"] = good
    return T, info, m


def trace(web, T, r, m):
    """The drawn route as zone-percent polylines: [{xy, loop, kind}], plus diagnostics."""
    diag = {"mask_px": int(m.sum())}
    H, W = m.shape
    scale = W / 750.0
    if r["category"] == "Leather" and "skinning" not in r["kinds"]:
        parts = []
        for a in area_loops(m):
            if "loop" in a:
                poly = rdp(a["loop"][:, ::-1], 1.5)[:, ::-1]           # (x, y)
                rc = np.c_[poly[:, 1], poly[:, 0]]
                xy = web_to_pct(T, rc)
                parts.append({"xy": xy, "loop": True, "area": True})
            else:
                rc = np.array([[a["center"][1], a["center"][0]]])
                parts.append({"xy": web_to_pct(T, rc), "loop": False, "spot": True})
        diag["parts"] = len(parts)
        return parts, diag, m
    sk = skeletonize(m)
    nodes, edges = build_graph(sk)
    edges, barbs = prune(nodes, edges, spur=18 * scale)
    # skinning maps label the route with skill numbers in the route's own colour: short side pieces
    # there are text, not dashes
    side = (100 if "skinning" in r["kinds"] else 10) * scale
    edges = keep_route_parts(edges, gap=45 * scale, minlen=side, biglen=160 * scale)
    edges, bridges = bridge_ends(nodes, edges, maxgap=40 * scale)
    diag["bridges"] = bridges
    pts, jumps = walk(nodes, edges)
    if not pts:
        return [], {"mask_px": int(m.sum()), "jumps": 0}, m
    poly = rdp(np.array(pts, float), 1.2)
    vote = vote_direction(poly, barbs)
    rev = CONFIG.get(r["key"], {}).get("reverse")
    if (vote < 0) != bool(rev):
        poly = poly[::-1]
    xy = web_to_pct(T, poly)
    span = np.hypot(*(to_yards(xy[:1], Z_CUR) - to_yards(xy[-1:], Z_CUR))[0])
    loop = span < 120
    diag.update({"jumps": jumps, "barbs": len(barbs), "vote": round(vote, 2), "edges": len(edges)})
    return [{"xy": xy, "loop": loop}], diag, m


Z_CUR = None


def same_route(a, b, Z, yards=60):
    """Two traced drawings of one route: every point of each lies near the other."""
    pa = np.vstack([to_yards(p["xy"], Z) for p in a["parts"]]) if a["parts"] else np.zeros((0, 2))
    pb = np.vstack([to_yards(p["xy"], Z) for p in b["parts"]]) if b["parts"] else np.zeros((0, 2))
    if len(pa) < 2 or len(pb) < 2:
        return False
    da = cKDTree(dense(pb)).query(dense(pa))[0]
    db = cKDTree(dense(pa)).query(dense(pb))[0]
    return np.median(da) < yards and np.median(db) < yards and np.percentile(da, 90) < 3 * yards


def dense(yd, step=20.0):
    out = [yd[0]]
    for p, q in zip(yd[:-1], yd[1:]):
        n = int(np.hypot(*(q - p)) // step)
        for k in range(1, n + 1):
            out.append(p + (q - p) * k / (n + 1))
        out.append(q)
    return np.array(out)


def build_route(r, web, T, Z, gm, names, mask):
    global Z_CUR
    Z_CUR = Z
    parts, diag, mask = trace(web, T, r, mask)
    raw = gm.get(Z["map"], [])
    ids = node_ids_for(r["mats"], names) if r["category"] in ("Ore", "Herbs") else set()
    nodes = dedupe_nodes(raw, ids, names, Z) if ids else []
    points, loop, nnodes = [], False, 0
    if len(parts) == 1 and not parts[0].get("spot"):
        p = parts[0]
        loop = p["loop"]
        if nodes:
            points, nnodes = hybrid(p["xy"], Z, nodes, loop, SNAP_YARDS[r["category"]])
        else:
            points = [(x, y, "path", None) for x, y in resample(p["xy"], Z, PATH_STEP_YARDS * 0.6)]
            if loop and len(points) > 2:
                points = points[:-1]
    else:
        # several areas (leather): visit them in reading order, each as a loop around its outline
        for p in parts:
            if p.get("spot"):
                points.append((float(p["xy"][0, 0]), float(p["xy"][0, 1]), "path", "farm here"))
            else:
                ring = resample(p["xy"], Z, PATH_STEP_YARDS * 0.5)
                points.extend((x, y, "path", None) for x, y in ring[:-1] if True)
        loop = len(parts) == 1 and parts[0].get("loop", False)
        if len(parts) > 1:
            loop = True
    return {"points": points, "loop": loop, "nnodes": nnodes, "diag": diag, "parts": parts, "mask": mask,
            "nodes_all": nodes}

# ------------------------------------------------------------------------------------- render
def render(r, web, T, res, path):
    im = Image.fromarray((web * 255).astype(np.uint8)).convert("RGB")
    dim = Image.new("RGB", im.size, (0, 0, 0))
    im = Image.blend(im, dim, 0.35)
    d = ImageDraw.Draw(im)
    # every spawn of the route's node types (calibration check: they should sit on the map's dots)
    for x, y, nid, name in res["nodes_all"]:
        px, py = pct_to_web(T, [x, y])[0]
        d.ellipse([px - 2, py - 2, px + 2, py + 2], outline=(255, 255, 255))
    for p in res["parts"]:
        w = pct_to_web(T, p["xy"])
        d.line([tuple(q) for q in w], fill=(255, 0, 255), width=1)
    pts = res["points"]
    if pts:
        w = pct_to_web(T, [(p[0], p[1]) for p in pts])
        seq = [tuple(q) for q in w] + ([tuple(w[0])] if res["loop"] else [])
        d.line(seq, fill=(0, 255, 255), width=2)
        for i, (q, p) in enumerate(zip(w, pts)):
            c = (60, 255, 60) if p[2] == "node" else (60, 140, 255)
            rad = 4 if p[2] == "node" else 3
            d.ellipse([q[0] - rad, q[1] - rad, q[0] + rad, q[1] + rad], fill=c, outline=(0, 0, 0))
            if i % 5 == 0:
                d.text((q[0] + 5, q[1] - 6), str(i + 1), fill=(255, 255, 0))
        q = w[0]
        d.rectangle([q[0] - 6, q[1] - 6, q[0] + 6, q[1] + 6], outline=(255, 255, 0), width=2)
    d.text((6, 4), "%s  %s  pts=%d nodes=%d loop=%s  cal %s  dots %s" % (r["id"], r["zone"], len(pts), res["nnodes"],
           res["loop"], r["cal"][0], r["cal"][1]), fill=(255, 255, 255))
    d.text((6, 16), str(res["diag"]), fill=(200, 200, 200))
    im.save(path)

# --------------------------------------------------------------------------------------- lua
def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def write_lua(routes, out):
    L = ["-- GENERATED by tools/import_wowprof_farming.py from WoW-Professions.com's classic farming guides.",
         "-- Their routes and text: not committed (see .gitignore). Re-run the importer to rebuild.",
         "local ADDON, ns = ...", "", "ns.FarmData = {"]
    for r in routes:
        L.append("  {")
        L.append("    id = %s, category = %s, zone = %s, map = %d, continent = %d," % (
            lua_str(r["id"]), lua_str(r["category"]), lua_str(r["zone"]), r["map"], r["continent"]))
        L.append("    name = %s, materials = { %s }," % (lua_str(r["name"]), ", ".join(lua_str(m) for m in r["mats"])))
        if r.get("skill"):
            L.append("    skill = { %d, %d }," % r["skill"])
        if r.get("level"):
            L.append("    level = %s," % lua_str(r["level"]))
        L.append("    source = %s, url = %s," % (lua_str(" / ".join(r["pages"])), lua_str(SITE + r["src"])))
        L.append("    notes = %s," % lua_str(r["notes"][:700]))
        L.append("    yards = { %d, %d }, loop = %s,%s" % (round(r["yw"]), round(r["yh"]), "true" if r["loop"] else "false",
                                                         " approx = true," if r.get("approx") else ""))
        L.append("    points = {")
        row = []
        for x, y, kind, node in r["points"]:
            s = "{ %.2f, %.2f" % (x, y)
            if kind == "node":
                s += ", %s" % lua_str(node)
            elif node:
                s += ", nil, %s" % lua_str(node)
            row.append(s + " }")
            if len(row) == 4:
                L.append("      " + ", ".join(row) + ",")
                row = []
        if row:
            L.append("      " + ", ".join(row) + ",")
        L.append("    },")
        L.append("  },")
    L.append("}")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L) + "\n")

# -------------------------------------------------------------------------------------- main
CAT_SHORT = {"Ore": "ore", "Herbs": "herb", "Leather": "leather"}


def route_name(r):
    if r["category"] == "Leather":
        if "skinning" in r["kinds"] and not [m for m in r["mats"] if m != "Skinning"]:
            return "Skinning" + (" %d-%d" % r["skill"] if r.get("skill") else "")
        mats = [m for m in r["mats"] if m != "Skinning"]
        return ", ".join(mats) + (" (skinning %d-%d)" % r["skill"] if "skinning" in r["kinds"] and r.get("skill") else "")
    mats = [m.replace(" Ore", "") for m in r["mats"]]
    what = ", ".join(mats[:3]) + (" ..." if len(mats) > 3 else "")
    if r.get("skill"):
        what += " (%d-%d)" % r["skill"]
    return what


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--cache", default=os.path.join(os.environ.get("TEMP", "/tmp"), "wowprof_farming"))
    ap.add_argument("--addons", default=DEFAULT_ADDONS, help="AddOns folder with GatherMate2 + GatherMate2_Data")
    ap.add_argument("--zones", default=DEFAULT_ZONES, help="zone map PNGs (1002x668) exported from the client")
    ap.add_argument("--out", default=os.path.join(HERE, "..", "Evergreen_Farming", "Farm_Data.lua"))
    ap.add_argument("--only", help="only images whose name contains this")
    ap.add_argument("--offline", action="store_true", help="use the cache only")
    a = ap.parse_args()
    for p, what in ((a.zones, "--zones"), (os.path.join(a.addons, "GatherMate2_Data"), "--addons")):
        if not os.path.isdir(p):
            raise SystemExit("not found: %s (%s)" % (p, what))
    global CACHE_DIR
    CACHE_DIR = a.cache
    zones = load_zones(a.zones)
    gm, names = load_gathermate(a.addons)
    routes = gather_routes(a.cache, a.offline)
    vdir = os.path.join(a.cache, "verify")
    os.makedirs(vdir, exist_ok=True)
    traced, rows = [], []
    for r in routes:
        cfg = CONFIG.get(r["key"], {})
        if a.only and a.only not in r["key"]:
            continue
        if cfg.get("drop"):
            rows.append((r["key"], r["zone"], "-", "-", "-", "DROPPED: " + cfg["drop"]))
            continue
        Z = zones[r["zone"]]
        img = fetch(SITE + r["src"], os.path.join(a.cache, "img", r["src"].replace("/images/", "").replace("/", "_")), a.offline)
        web = np.asarray(Image.open(img).convert("RGB")).astype(float) / 255
        T, cal, mask = calibrate(r, web, Z, gm)
        yd_px = (Z["yw"] / ZONE_W + Z["yh"] / ZONE_H) / 2       # yards per zone-art pixel
        img_yd = yd_px * float(np.mean(T["s"]))                   # yards per image pixel
        cal_s = "%s %d/%d %.1fyd" % (cal["method"].split(" ")[0], cal["inliers"], cal["matches"], cal["rms"] * yd_px)
        dot_s = "-"
        if cal.get("dot_spawns"):
            dot_s = "%d/%d %.1fyd" % (cal["dot_hits"], cal["dot_spawns"], (cal["dot_median"] or 0) * img_yd)
        r["cal"] = (cal_s, dot_s)
        r.update({"map": Z["map"], "continent": Z["cont"], "yw": Z["yw"], "yh": Z["yh"]})
        if not cal["good"]:
            rows.append((r["key"], r["zone"], cal_s, dot_s, "0", "DROPPED: no calibration"))
            continue
        res = build_route(r, web, T, Z, gm, names, mask)
        if not res["points"]:
            rows.append((r["key"], r["zone"], cal_s, dot_s, "0", "DROPPED: no route traced"))
            continue
        flags = []
        if cal["redrawn"]:
            flags.append("Forever redrew this zone's map: calibrated on %s" % cal["method"])
        if cfg.get("approx"):
            flags.append(cfg["approx"])
            r["approx"] = True
        elif res["diag"].get("jumps", 0) >= 7:
            flags.append("APPROX: the drawing breaks into %d pieces, the point order may jump" % (res["diag"]["jumps"] + 1))
            r["approx"] = True
        traced.append([r, web, T, Z, mask, res, flags])

    # the same drawing on several pages (copper page + mining guide, heavy + thick leather): one route
    done = []
    for item in traced:
        r, web, T, Z, mask, res, flags = item
        dup = None
        for o in done:
            if o[0]["zone"] == r["zone"] and o[0]["category"] == r["category"] and same_route(o[5], res, Z):
                dup = o
                break
        if dup:
            o = dup[0]
            for k in ("mats", "pages"):
                o[k] += [x for x in r[k] if x not in o[k]]
            o["kinds"] |= r["kinds"]
            for k in ("skill", "level"):
                if r.get(k) and not o.get(k):
                    o[k] = r[k]
            if r["notes"] and r["notes"] not in o["notes"]:
                o["notes"] = (o["notes"] + " " + r["notes"]).strip()
            o.setdefault("also", []).append(r["key"])
            dup[5] = build_route(o, dup[1], dup[2], Z, gm, names, dup[4])
            continue
        done.append(item)
    used, out = {}, []
    for r, web, T, Z, mask, res, flags in done:
        base = "%s-%s" % (CAT_SHORT[r["category"]], re.sub(r"[^a-z]+", "-", r["zone"].lower()).strip("-"))
        used[base] = used.get(base, 0) + 1
        r["id"] = base if used[base] == 1 else "%s-%d" % (base, used[base])
        r.update({"points": res["points"], "loop": res["loop"], "name": route_name(r)})
        render(r, web, T, res, os.path.join(vdir, r["id"] + ".png"))
        out.append(r)
        rows.append((r["id"], r["zone"], r["cal"][0], r["cal"][1],
                     "%d (%d nodes)%s" % (len(res["points"]), res["nnodes"], " loop" if res["loop"] else ""),
                     "; ".join(flags + (["same drawing as " + ", ".join(r["also"])] if r.get("also") else [])) + " " + str(res["diag"])))
    done = out
    if not a.only:
        write_lua(done, a.out)
        print("wrote %s: %d routes" % (os.path.normpath(a.out), len(done)))
    print("%-28s %-20s %-24s %-16s %-18s %s" % ("route", "zone", "calibration (rms)", "dots hit (median)", "points", "notes"))
    for row in rows:
        print("%-28s %-20s %-24s %-16s %-18s %s" % row)
    cats = {}
    for r in done:
        cats[r["category"]] = cats.get(r["category"], 0) + 1
    print("routes per category:", cats, " verification images:", vdir)


if __name__ == "__main__":
    main()
