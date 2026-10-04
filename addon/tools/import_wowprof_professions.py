#!/usr/bin/env python
"""Import WoW-Professions.com's WoW Forever profession leveling guides into Evergreen_Professions.

    python import_wowprof_professions.py [--cache DIR] [--out FILE] [--offline] [--refresh]

Downloads the 10 guide pages and every trainer / vendor NPC page they link (each once, ~1s apart,
cached in DIR so a second run makes no requests), parses them and writes
addon/Evergreen_Professions/Prof_Data.lua.

The generated file holds WoW-Professions' guide text, so it is not committed (the repo is public);
every user runs this script once. Needs BeautifulSoup (pip install beautifulsoup4).

Data layout (ns.ProfessionsData):
  npcs   = { [slug] = { n = name, m = uiMapID, x = 55.9, y = 33.1, z = "Orgrimmar", sub = "The Drag", f = "H"|"A"|nil, role = "Alchemy Trainer" } }
  guides = { { key, name, skill, url, tiers, trainers, startZones, shopping, recipeTables, entries } }
  entries is the guide in page order:
    { k = "h", lvl = 2|3|4, title, from, to, text = {lines}, npcs = {slugs}, way = {{m,x,y,title}}, vendors = {...} }
    { k = "v", g = group, labels = {...} }                        -- route choice (page tabs)
    { k = "s", from, to, crafts = {{c, name, spell, mats = {{n, c, i}}}}, pick = "one"|"all",
      alts = {crafts}, note = {lines}, recipes = {{i, n, npcs}}, npcs = {slugs}, vendors = {...}, text = {lines} }
  Any entry may carry var = { g, i } (only shown when that route is picked) or fac = "H"|"A", and skill
  (when it is not the guide's skill, e.g. Cooking steps in the Fishing and Cooking guide).
"""
import argparse
import json
import os
import re
import sys
import tempfile
import time
import urllib.request

try:
    from bs4 import BeautifulSoup, NavigableString, Tag
except ImportError:
    sys.exit("BeautifulSoup is needed: pip install beautifulsoup4")

BASE = "https://www.wow-professions.com"
UA = "Mozilla/5.0 (Evergreen addon importer; one request per page, cached)"
GUIDES = [
    ("alchemy", "Alchemy", "Alchemy"),
    ("blacksmithing", "Blacksmithing", "Blacksmithing"),
    ("enchanting", "Enchanting", "Enchanting"),
    ("engineering", "Engineering", "Engineering"),
    ("leatherworking", "Leatherworking", "Leatherworking"),
    ("tailoring", "Tailoring", "Tailoring"),
    ("first-aid", "First Aid", "First Aid"),
    ("cooking", "Cooking", "Cooking"),
    ("fishing", "Fishing", "Fishing"),
    ("fishing-and-cooking", "Fishing & Cooking", "Fishing"),
]
TIERS = ("Apprentice", "Journeyman", "Expert", "Artisan")
RECIPE_PREFIX = re.compile(r"^(Recipe|Formula|Plans|Pattern|Schematic|Manual|Design)\s*:", re.I)
WH = re.compile(r"wowhead\.com/forever/(spell|item|quest|npc)=(\d+)")
NPC = re.compile(r"^/forever/npc/([^/?#]+?)(?:\.html)?/?$")
MAX_LINE = 420

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.join(HERE, "..", "Evergreen_Professions", "Prof_Data.lua")
DEFAULT_CACHE = os.path.join(tempfile.gettempdir(), "wowprof_cache")

problems = []  # things the parser could not place, reported at the end


def warn(guide, msg):
    problems.append(f"{guide}: {msg}")


# ------------------------------------------------------------------ fetching
class Fetcher:
    def __init__(self, cache, offline=False, refresh=False):
        self.cache, self.offline, self.refresh = cache, offline, refresh
        self.last = 0.0
        self.requests = 0
        os.makedirs(os.path.join(cache, "npc"), exist_ok=True)

    def get(self, path, cache_name):
        fn = os.path.join(self.cache, cache_name)
        if os.path.exists(fn) and os.path.getsize(fn) > 0 and not self.refresh:
            with open(fn, encoding="utf-8") as f:
                return f.read()
        if self.offline:
            return None
        wait = 1.0 - (time.time() - self.last)
        if wait > 0:
            time.sleep(wait)
        self.last = time.time()
        self.requests += 1
        req = urllib.request.Request(BASE + path, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                html = r.read().decode("utf-8", "replace")
        except Exception as e:  # 404s and timeouts: reported, not fatal
            print(f"  fetch failed {path}: {e}", file=sys.stderr)
            return None
        with open(fn, "w", encoding="utf-8") as f:
            f.write(html)
        return html


# ------------------------------------------------------------------ text helpers
def clean(s):
    s = (s or "").replace("\xa0", " ")
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"\s+([,.;:)])", r"\1", s)
    s = re.sub(r"\(\s+", "(", s)
    return s


def short(s, n=MAX_LINE):
    s = clean(s)
    if len(s) <= n:
        return s
    cut = s[:n].rsplit(" ", 1)[0]
    return cut.rstrip(",;:") + "..."


def text(el):
    if el is None:
        return ""
    if isinstance(el, NavigableString):
        return clean(str(el))
    return clean(el.get_text(" "))


def link_kind(a):
    """('spell'|'item'|'quest'|'wnpc', id) for a wowhead link, ('npc', slug) for a site NPC page."""
    href = a.get("href", "") if isinstance(a, Tag) else ""
    m = WH.search(href)
    if m:
        k = m.group(1)
        return ("wnpc" if k == "npc" else k), int(m.group(2))
    m = NPC.match(href)
    if m:
        return "npc", m.group(1)
    return None, None


def link_faction(a):
    img = a.find("img")
    src = img.get("src", "") if img else ""
    if "horde" in src:
        return "H"
    if "alliance" in src:
        return "A"
    return None


def faction_after(a):
    """'(Horde)' / '(Alliance)' / 'Horde only' right after a link."""
    nxt = a.next_sibling
    s = ""
    for _ in range(3):
        if nxt is None:
            break
        s += text(nxt) + " "
        if len(s) > 60:
            break
        nxt = nxt.next_sibling
    m = re.match(r"^[^()]{0,40}?\((Horde|Alliance)( only)?\)", s.strip())
    if m:
        return "H" if m.group(1) == "Horde" else "A"
    return None


def range_of(s):
    m = re.search(r"\((\d+)\s*-\s*(\d+)\)", s) or re.search(r"\b(\d+)\s*-\s*(\d+)\b", s)
    if m:
        return int(m.group(1)), int(m.group(2))
    m = re.search(r"\bto (\d+)\b", s)
    if m:
        return None, int(m.group(1))
    return None, None


# ------------------------------------------------------------------ crafts and materials
class Names:
    """Material name -> item ID, from every wowhead item link on every page."""

    def __init__(self):
        self.ids = {}

    def learn(self, soup):
        for a in soup.find_all("a"):
            k, v = link_kind(a)
            if k == "item":
                n = text(a)
                if n and not RECIPE_PREFIX.match(n):
                    self.ids.setdefault(n.lower(), v)

    def get(self, name):
        n = name.lower()
        if n in self.ids:
            return self.ids[n]
        if n.endswith("s") and n[:-1] in self.ids:
            return self.ids[n[:-1]]
        if n.endswith("es") and n[:-2] in self.ids:
            return self.ids[n[:-2]]
        return None


NAMES = Names()

# Trade goods the guides name without a link (crafted intermediates, vendor reagents). Game item IDs
# (unchanged from Classic), used only to count what is in the bags; the addon also counts by name.
KNOWN_IDS = {
    "black dye": 2325, "bleach": 2324, "blue dye": 6260, "gray dye": 4340, "orange dye": 6261, "red dye": 2604,
    "bolt of linen cloth": 2996, "bolt of woolen cloth": 2997, "bolt of silk cloth": 4305,
    "coarse thread": 2320, "fine thread": 2321, "silken thread": 4291, "heavy silken thread": 8343, "salt": 4289,
    "cured medium hide": 4233, "cured heavy hide": 4236, "fine leather belt": 4246, "iron buckle": 7071,
    "rough blasting powder": 4357, "coarse blasting powder": 4364, "heavy blasting powder": 4377,
    "solid blasting powder": 10505, "handful of copper bolts": 4359, "bronze tube": 4371,
    "whirring bronze gizmo": 4375, "bronze framework": 4382, "unstable trigger": 10560, "mithril casing": 10561,
    "rough grinding stone": 3470, "coarse grinding stone": 3478, "heavy grinding stone": 3486,
    "solid grinding stone": 7966, "fire oil": 6371, "ghost mushroom": 8845, "plaguebloom": 13466,
    "stonescale oil": 13423, "imbued vial": 18256,
}
for _k, _v in KNOWN_IDS.items():
    NAMES.ids.setdefault(_k, _v)


def parse_mats(s, links=None):
    """'9 Peacebloom, 9 Empty Vial' -> [{n, c, i}]. links: name -> itemID seen in the same text."""
    out = []
    s = clean(s).rstrip(".")
    s = re.sub(r"\((?:vendor|sold by[^)]*|buy[^)]*)\)", "", s, flags=re.I)
    for part in re.split(r",\s*|\s+and\s+(?=\d)", s):
        part = part.strip().rstrip(".")
        m = re.match(r"^(\d+)(?:\s*-\s*(\d+))?x?\s+(.+?)(?:\s+each)?$", part)
        if not m:
            continue
        name = re.sub(r"\s*\(.*$", "", m.group(3)).strip()
        if not name:
            continue
        c = int(m.group(2) or m.group(1))
        iid = (links or {}).get(name.lower()) or NAMES.get(name)
        e = {"n": name, "c": c}
        if iid:
            e["i"] = iid
        out.append(e)
    return out


def head_nodes(li):
    """Inline content of a step <li> before its first block child (<p>, <ul>, <ol>, <details>, <div>)."""
    nodes = []
    for ch in li.children:
        if isinstance(ch, Tag) and ch.name in ("p", "ul", "ol", "details", "div", "table"):
            break
        nodes.append(ch)
    return nodes


def craft_from_nodes(nodes):
    """Find 'Nx <spell link> - mats' (or '(mats)') in a run of inline nodes."""
    pre = ""
    for i, n in enumerate(nodes):
        if isinstance(n, Tag) and n.name == "a" and link_kind(n)[0] == "spell":
            m = re.search(r"(\d+)(?:\s*-\s*(\d+))?\s*x\s*$", pre)
            c = int(m.group(2) or m.group(1)) if m else None
            rest_nodes = nodes[i + 1:]
            rest = clean(" ".join(text(x) if isinstance(x, Tag) else str(x) for x in rest_nodes))
            links = {}
            for x in rest_nodes:
                if isinstance(x, Tag):
                    for a in ([x] if x.name == "a" else x.find_all("a")):
                        k, v = link_kind(a)
                        if k == "item":
                            links[text(a).lower()] = v
            mats = []
            mm = re.match(r"^(?:instead\s*)?[-\u2013]\s*(.+)$", rest)
            if mm:
                mats = parse_mats(mm.group(1).split(". ")[0], links)
            else:
                # '(9 Silverleaf, 9 Empty Vial)', 'until 90 instead (1 Lesser Magic Essence each)'
                mm = re.match(r"^[^()]{0,40}?\(([^)]*\d[^)]*)\)", rest)
                if mm:
                    mats = parse_mats(mm.group(1), links)
            craft = {"name": text(n), "spell": link_kind(n)[1], "mats": mats}
            if c:
                craft["c"] = c
                pre = pre[:m.start()]
            return craft, pre
        pre += text(n) + " " if isinstance(n, Tag) else str(n)
    return None, pre


def flatten(el):
    """A tag's inline children, with nested inline tags (b, span, i) opened up so links are siblings."""
    out = []
    for ch in el.children:
        if isinstance(ch, Tag) and ch.name in ("b", "strong", "span", "i", "em"):
            if ch.find("a"):
                out.extend(flatten(ch))
            else:
                out.append(ch)
        else:
            out.append(ch)
    return out


# ------------------------------------------------------------------ the parser
class Guide:
    def __init__(self, key, name, skill, soup, npcs_seen):
        self.key, self.name, self.skill = key, name, skill
        self.soup = soup
        self.npcs_seen = npcs_seen  # slug -> {name, fac hint}
        self.g = {"key": key, "name": name, "skill": skill, "url": f"{BASE}/forever/{key}-leveling-guide",
                  "tiers": [], "trainers": {"H": [], "A": []}, "startZones": [], "shopping": [],
                  "recipeTables": [], "entries": [], "intro": []}
        self.section = None   # current h2 id/title
        self.mode = None      # shopping | trainers | tier | info
        self.tier = None
        self.block = None     # current header entry ('h') that text goes to
        self.sub = None       # current h3 text
        self.groups = 0
        self.prev = {}        # skill -> where the last step ended (per skill: the combined guide)
        self.cur_skill = skill
        self.last_step = None
        self.section_ctx = {"skill": skill}

    @property
    def prev_to(self):
        return self.prev.get(self.cur_skill, 1)

    @prev_to.setter
    def prev_to(self, v):
        self.prev[self.cur_skill] = v

    # -- helpers
    def npc_ref(self, a, fac=None):
        k, slug = link_kind(a)
        if k != "npc":
            return None
        rec = self.npcs_seen.setdefault(slug, {"name": text(a), "f": None})
        f = fac or link_faction(a) or faction_after(a)
        if f and not rec["f"]:
            rec["f"] = f
        return slug

    def npcs_in(self, el):
        out = []
        for a in el.find_all("a") if isinstance(el, Tag) else []:
            s = self.npc_ref(a)
            if s and s not in out:
                out.append(s)
        return out

    def ways_in(self, el):
        out = []
        for d in el.find_all(attrs={"data-zone": True}) if isinstance(el, Tag) else []:
            m = re.match(r"\s*([\d.]+)\s*,\s*([\d.]+)", d.get("data-coords", ""))
            if m and d.get("data-zone", "").isdigit():
                out.append({"m": int(d["data-zone"]), "x": float(m.group(1)), "y": float(m.group(2)),
                            "title": clean(d.get("data-title", ""))})
        return out

    def ctx_fields(self, ctx):
        e = {}
        if ctx.get("var"):
            e["var"] = ctx["var"]
        if ctx.get("fac"):
            e["fac"] = ctx["fac"]
        if ctx.get("skill") and ctx["skill"] != self.skill:
            e["skill"] = ctx["skill"]
        return e

    def header(self, lvl, title, ctx, rng=None):
        f, t = rng if rng else range_of(title)
        self.cur_skill = ctx.get("skill") or self.skill
        e = {"k": "h", "lvl": lvl, "title": title, "text": []}
        if t:
            f = f if f is not None else self.prev_to
            if f < t:
                e["from"], e["to"] = f, t
        e.update(self.ctx_fields(ctx))
        self.g["entries"].append(e)
        self.block = e
        return e

    def add_text(self, line, ctx, el=None):
        line = short(line)
        if not line:
            return
        if self.block is None or (ctx.get("var") or ctx.get("fac")) != (self.block.get("var") or self.block.get("fac")):
            # text inside a route tab gets its own (untitled) block so it is filtered with the route
            self.header(5, "", ctx)
        self.block["text"].append(line)
        if el is not None:
            for s in self.npcs_in(el):
                self.block.setdefault("npcs", [])
                if s not in self.block["npcs"]:
                    self.block["npcs"].append(s)
            w = self.ways_in(el)
            if w:
                self.block.setdefault("way", []).extend(w)

    # -- top level
    def run(self):
        art = self.soup.find("article")
        if art is None:
            warn(self.key, "no <article> on the page")
            return self.g
        started = False
        for el in art.children:
            if not isinstance(el, Tag):
                continue
            if el.name == "h2":
                started = True
                self.start_section(el)
                continue
            if not started:
                t = text(el)
                if t and el.name in ("p", "div"):
                    self.g["intro"].append(short(t))
                continue
            self.element(el, dict(self.section_ctx))
        self.finish()
        return self.g

    def start_section(self, h2):
        sid, title = h2.get("id", ""), text(h2)
        self.section, self.sub, self.block = sid, None, None
        self.tier_steps = 0
        self.cur_skill = self.skill_for(title)
        self.section_ctx = {"skill": self.cur_skill}
        if sid == "shopping-list":
            self.mode = "shopping"
        elif sid.endswith("-trainers"):
            self.mode = "trainers"
        elif sid in TIERS:
            self.mode = "tier"
            f, t = range_of(title)
            self.tier = {"name": sid, "title": title, "from": f, "to": t, "train": None,
                         "trainers": {"H": [], "A": []}}
            self.g["tiers"].append(self.tier)
            self.header(2, title, {"skill": self.skill}, (f, t))
            if f is not None:
                self.prev_to = f
        else:
            self.mode = "info"
            ctx = {"skill": self.skill_for(title)}
            e = self.header(2, title, ctx)
            if "to" in e:
                self.prev_to = e["to"]

    def skill_for(self, title):
        if self.key != "fishing-and-cooking":
            return self.skill
        t = title.lower()
        if "cooking" in t and "fishing" not in t:
            return "Cooking"
        return "Fishing"

    # -- elements
    def element(self, el, ctx):
        name = el.name
        self.cur_skill = ctx.get("skill") or self.skill
        if name == "div" and el.find(attrs={"data-zone": True}) and el.find("button", attrs={"data-clipboard-text": True}):
            # a map card (TomTom / in-game pin buttons and a map image): keep the waypoint only
            w = self.ways_in(el)
            if w:
                if self.block is None:
                    self.header(5, "", ctx)
                self.block.setdefault("way", []).extend(w)
            return
        if self.mode == "shopping":
            return self.shopping(el)
        if self.mode == "trainers":
            return self.trainers(el)
        if name in ("h3", "h4"):
            t = text(el)
            if not t:
                return
            if name == "h3":
                self.sub = t
            sctx = dict(ctx)
            if self.key == "fishing-and-cooking" and name == "h3":
                sctx["skill"] = "Cooking" if "cook" in t.lower() else ("Fishing" if "fish" in t.lower() else ctx.get("skill"))
                ctx["skill"] = sctx["skill"]
            f, to = range_of(t)
            self.header(3 if name == "h3" else 4, t, sctx, (f, to) if to else (None, None))
            return
        if name == "ul" and self.is_step_list(el):
            for li in el.find_all("li", recursive=False):
                self.step(li, ctx)
            return
        if name == "div" and el.find("button", attrs={"data-tab": True}):
            return self.tabs(el, ctx)
        if name == "div" and self.trainer_columns(el) is not None:
            cols = self.trainer_columns(el)
            if self.tier is not None:
                for f, lst in cols.items():
                    self.tier["trainers"][f].extend(lst)
            return
        if name == "table" or (name == "div" and el.find("table") and not el.find("details")
                                and not el.find(["p", "ul", "ol"], recursive=False)):
            tbl = el if name == "table" else el.find("table")
            return self.table(tbl, ctx)
        if name == "details":
            return self.vendors(el, ctx, self.block)
        if name == "pre":
            self.add_text(el.get_text("\n").strip().replace("\n", " | "), ctx)
            return
        if name in ("p", "div"):
            if name == "div" and el.find(["ul", "ol", "table", "details", "h3", "h4"]):
                for ch in el.children:
                    if isinstance(ch, Tag):
                        self.element(ch, ctx)
                return
            t = text(el)
            if not t or t == "(Return to Top)":
                return
            if self.mode == "tier" and self.tier is not None and not self.tier["train"] and \
                    re.search(r"\b(learn|train|reward)", t, re.I) and \
                    re.search(r"\brequires?\b|\blevel \d+|\bneed\b.*\d", t, re.I):
                self.tier["train"] = short(t, 600)
                self.tier_npcs(el)
            elif self.mode == "tier" and self.tier is not None and not self.tier_steps and \
                    not self.tier["trainers"]["H"] and not self.tier["trainers"]["A"] and \
                    re.search(r"\btrainer\b|\bquest is given\b", t, re.I):
                # 'There is only one Expert Enchanting trainer for each faction. <npc> ... <npc> ...'
                self.tier_npcs(el)
            # 'Nx <spell> - mats' standing alone (cooking's alternative recipe, beta notes)
            craft, pre = craft_from_nodes(flatten(el))
            if craft and craft.get("c") and not clean(pre) and self.last_step is not None and self.mode == "tier":
                self.last_step.setdefault("alts", []).append(craft)
            self.add_text(t, ctx, el)
            return
        if name in ("ol", "ul"):
            for i, li in enumerate(el.find_all("li", recursive=False)):
                t = text(li)
                if t:
                    self.add_text(("%d. " % (i + 1) if name == "ol" else "- ") + t, ctx, li)
            return
        t = text(el)
        if t:
            warn(self.key, f"unhandled <{name}> in {self.section}: {short(t, 80)}")
            self.add_text(t, ctx, el)

    def tier_npcs(self, el):
        for a in el.find_all("a"):
            s = self.npc_ref(a)
            if s:
                f = self.npcs_seen[s]["f"] or faction_after(a)
                for fk in ([f] if f else ["H", "A"]):
                    if s not in [x["npc"] for x in self.tier["trainers"][fk]]:
                        self.tier["trainers"][fk].append({"npc": s})

    def is_step_list(self, ul):
        lis = ul.find_all("li", recursive=False)
        if not lis:
            return False
        first = lis[0]
        b = first.find("b")
        return b is not None and next((c for c in first.children if isinstance(c, Tag)), None) is b and \
            re.match(r"^\d+\s*-\s*\d+$", text(b)) is not None

    def tabs(self, div, ctx):
        buttons = div.find_all("button", attrs={"data-tab": True})
        labels = [text(b) for b in buttons]
        facs = {"Horde": "H", "Alliance": "A"}
        by_fac = all(l in facs for l in labels)
        self.groups += 1
        gid = f"{self.section}:{self.groups}"
        if not by_fac:
            self.g["entries"].append(dict({"k": "v", "g": gid, "labels": labels}, **self.ctx_fields(ctx)))
        start_prev = dict(self.prev)
        ends = []
        for i, b in enumerate(buttons):
            panel = div.find(id=b["data-tab"])
            if panel is None:
                warn(self.key, f"tab panel {b['data-tab']} missing")
                continue
            sub = dict(ctx)
            if by_fac:
                sub["fac"] = facs[labels[i]]
            else:
                sub["var"] = {"g": gid, "i": i + 1}
            self.prev = dict(start_prev)
            saved_block = self.block
            self.block = None
            for ch in panel.children:
                if isinstance(ch, Tag):
                    self.element(ch, sub)
            ends.append(dict(self.prev))
            self.block = saved_block if by_fac else None
        merged = dict(start_prev)
        for e in ends:
            for k, v in e.items():
                merged[k] = max(merged.get(k, 0), v)
        self.prev = merged
        self.block = None

    def trainer_columns(self, div):
        if "Horde trainers" not in text(div) and "Alliance trainers" not in text(div):
            return None
        out = {"H": [], "A": []}
        for p in div.find_all("p"):
            t = text(p)
            f = "H" if t.startswith("Horde") else "A" if t.startswith("Alliance") else None
            ul = p.find_next_sibling("ul")
            if not f or ul is None:
                continue
            for li in ul.find_all("li"):
                a = next((a for a in li.find_all("a") if link_kind(a)[0] == "npc"), None)
                if a is None:
                    continue
                city = clean(text(li).split(":")[0]) if ":" in text(li) else None
                out[f].append({"npc": self.npc_ref(a, f), "city": city})
        return out

    # -- shopping list and trainer sections
    def shopping(self, el):
        if el.name == "h3":
            self.g["shopping"].append({"title": text(el), "rows": [], "note": []})
            return
        if el.name == "p" and not self.g["shopping"]:
            t = text(el)
            if t:
                self.g.setdefault("shopIntro", []).append(short(t))
            return
        tbl = el if el.name == "table" else (el.find("table") if el.name == "div" else None)
        if tbl is not None and tbl.find("input") is not None or (tbl is not None and "shop-table" in (tbl.get("class") or [])):
            if not self.g["shopping"] or self.g["shopping"][-1]["rows"]:
                self.g["shopping"].append({"title": "Shopping list" if not self.g["shopping"] else "More", "rows": [], "note": []})
            lst = self.g["shopping"][-1]
            for tr in tbl.find_all("tr"):
                tds = tr.find_all("td")
                if len(tds) < 2:
                    continue
                row = {"mats": self.mat_links(tds[1])}
                if len(tds) > 2 and text(tds[2]):
                    row["alt"] = self.mat_links(tds[2])
                if not row["mats"]:
                    warn(self.key, f"shopping row without items: {short(text(tds[1]), 80)}")
                    continue
                lst["rows"].append(row)
            return
        t = text(el)
        if t:
            if not self.g["shopping"]:
                self.g["shopping"].append({"title": "Shopping list", "rows": [], "note": []})
            self.g["shopping"][-1]["note"].append(short(t))

    def mat_links(self, td):
        out, pre = [], ""
        for n in flatten(td):
            if isinstance(n, Tag) and n.name == "a" and link_kind(n)[0] == "item":
                m = re.search(r"(\d+)\s*x?\s*$", pre)
                e = {"n": text(n), "c": int(m.group(1)) if m else 1, "i": link_kind(n)[1]}
                out.append(e)
                pre = ""
            else:
                pre += text(n) + " " if isinstance(n, Tag) else str(n)
        return out

    def trainers(self, el):
        if el.name == "h3":
            self.sub = text(el)
            return
        if el.name == "div":
            cols = self.trainer_columns(el)
            if cols:
                for f, lst in cols.items():
                    self.g["trainers"][f].extend(lst)
                return
            tbl = el.find("table")
            if tbl is not None:
                return self.start_zones(tbl)
        if el.name == "table":
            return self.start_zones(el)
        t = text(el)
        if t:
            self.g["intro"].append(short(t))

    def start_zones(self, tbl):
        for tr in tbl.find_all("tr"):
            tds = tr.find_all("td")
            if len(tds) < 3:
                continue
            npcs = [s for s in (self.npc_ref(a) for a in tds[2].find_all("a")) if s]
            self.g["startZones"].append({"races": text(tds[0]), "zone": text(tds[1]), "text": short(text(tds[2])), "npcs": npcs})

    # -- tables inside the guide
    def table(self, tbl, ctx):
        heads = [text(th).lower() for th in tbl.find_all("th")]
        if heads[:2] == ["food", "ingredients"]:
            return self.food_table(tbl, ctx)
        if heads and heads[0] == "recipe" and ("learn" in heads or "skill" in heads):
            rows = []
            for tr in tbl.find_all("tr"):
                tds = tr.find_all("td")
                if not tds:
                    continue
                a = tds[0].find("a")
                r = {"name": text(tds[0])}
                if a is not None and link_kind(a)[0] == "spell":
                    r["spell"] = link_kind(a)[1]
                vals = [text(td) for td in tds[1:]]
                for h, v in zip(heads[1:], vals):
                    if h in ("learn", "skill"):
                        r["learn"] = int(v) if v.isdigit() else v
                    elif h == "yellow":
                        r["yellow"] = int(v) if v.isdigit() else v
                    elif h == "grey":
                        r["grey"] = int(v) if v.isdigit() else v
                    elif h == "materials":
                        r["mats"] = v
                    elif h == "cost":
                        r["cost"] = v
                rows.append(r)
            title = self.block["title"] if self.block and self.block.get("title") else self.sub or "Recipes"
            self.g["recipeTables"].append({"title": title, "rows": rows})
            self.add_text(f"(Recipe table: {len(rows)} recipes, see the Recipes tab.)", ctx)
            return
        warn(self.key, f"unknown table in {self.section}: {heads}")
        for tr in tbl.find_all("tr"):
            t = " | ".join(text(td) for td in tr.find_all("td"))
            if t:
                self.add_text(t, ctx, tr)

    def food_table(self, tbl, ctx):
        crafts = []
        for tr in tbl.find_all("tr"):
            tds = tr.find_all("td")
            if len(tds) < 2:
                continue
            craft, _ = craft_from_nodes(flatten(tds[0]))
            if not craft:
                warn(self.key, f"food row without a recipe: {short(text(tds[0]), 60)}")
                continue
            craft["mats"] = self.mat_links(tds[1])
            extra = re.findall(r"\(([^)]*)\)", text(tds[1]))
            if extra:
                craft["matNote"] = short("; ".join(extra), 160)
            if len(tds) > 2:
                src = tds[2]
                craft["src"] = short(text(src), 300)
                craft["npcs"] = [s for s in (self.npc_ref(a) for a in src.find_all("a")) if s]
            crafts.append(craft)
        if not crafts:
            return
        b = self.block or {}
        f, t = b.get("from"), b.get("to")
        if t is None and self.tier:
            f, t = self.tier["from"], self.tier["to"]
        step = {"k": "s", "from": f if f is not None else self.prev_to, "to": t or self.prev_to, "crafts": crafts,
                "pick": "one" if len(crafts) > 1 else None, "note": []}
        step.update(self.ctx_fields(ctx))
        self.add_step(step)

    def vendors(self, det, ctx, target):
        summ = text(det.find("summary"))
        f = "H" if "Horde" in summ else "A" if "Alliance" in summ else None
        rows = []
        for tr in det.find_all("tr"):
            tds = tr.find_all("td")
            if len(tds) < 2:
                continue
            rows.append({"zone": text(tds[0]), "text": short(text(tds[1]), 200),
                         "npcs": [s for s in (self.npc_ref(a, f) for a in tds[1].find_all("a")) if s]})
        if target is None:
            target = self.header(5, "", ctx)
        target.setdefault("vendors", []).append({"fac": f, "title": summ, "rows": rows})

    # -- one leveling step (<li><b>1-10</b><br>...)
    def step(self, li, ctx):
        b = li.find("b")
        f, t = range_of(text(b))
        step = {"k": "s", "from": f, "to": t, "crafts": [], "note": []}
        step.update(self.ctx_fields(ctx))
        head = [n for n in head_nodes(li) if n is not b]
        craft, pre = craft_from_nodes([n for n in head if not (isinstance(n, Tag) and n.name == "br")])
        lead = clean(" ".join(text(n) if isinstance(n, Tag) else str(n) for n in head))
        if craft:
            if "c" not in craft:
                # 'Learn Recipe: X and cook all your fish': a spell link without a count is prose
                step["text"] = [short(lead)]
            else:
                step["crafts"].append(craft)
        elif lead:
            step["text"] = [short(lead)]
        first_list = True
        for ch in li.children:
            if not isinstance(ch, Tag) or ch is b or any(ch is h for h in head):
                continue
            if ch.name in ("ul", "ol") and first_list and not step["crafts"] and \
                    any(craft_from_nodes(flatten(x))[0] for x in ch.find_all("li", recursive=False)):
                # 'Make one of these:' / 'Make both of these:'
                for x in ch.find_all("li", recursive=False):
                    c, _ = craft_from_nodes(flatten(x))
                    if c:
                        step["crafts"].append(c)
                step["pick"] = "all" if re.search(r"\bboth\b|\ball\b", lead, re.I) or ch.name == "ol" else "one"
                step.pop("text", None)
                step["lead"] = short(lead)
                first_list = False
                continue
            first_list = False if ch.name in ("ul", "ol") else first_list
            self.step_block(ch, step)
        if not step["crafts"] and not step.get("text"):
            warn(self.key, f"step {f}-{t} with no recipe: {short(text(li), 80)}")
        self.add_step(step)

    def step_block(self, el, step):
        if el.name == "details":
            return self.vendors(el, {}, step)
        if el.name in ("ul", "ol"):
            prev = step["note"][-1] if step["note"] else ""
            for x in el.find_all("li", recursive=False):
                c, pre = craft_from_nodes(flatten(x))
                if c and c.get("c") and not clean(pre):
                    step.setdefault("alts", []).append(c)
                    step["note"].append("- " + short(text(x)))
                    continue
                self.recipe_links(x, step, prev)
                step["note"].append("- " + short(text(x)))
            return
        if el.name in ("p", "div"):
            t = text(el)
            if not t:
                return
            if el.find(["ul", "ol", "details"]):
                for ch in el.children:
                    if isinstance(ch, Tag):
                        self.step_block(ch, step)
                return
            c, pre = craft_from_nodes(flatten(el))
            if c and c.get("c") and re.match(r"^(or\s*)?$", clean(pre), re.I):
                step.setdefault("alts", []).append(c)
            elif c and re.search(r"\b(instead|or)\b", t, re.I) and not c.get("c"):
                # 'make <spell> instead (1 Lesser Magic Essence each)'
                step.setdefault("alts", []).append(c)
            self.recipe_links(el, step, t)
            if t not in ("Alternative:",):
                step["note"].append(short(t))
            for s in self.npcs_in(el):
                step.setdefault("npcs", [])
                if s not in step["npcs"]:
                    step["npcs"].append(s)
            return
        t = text(el)
        if t:
            step["note"].append(short(t))

    def recipe_links(self, el, step, context_text=""):
        """'Recipe: X is sold by <npc>, <npc>' -> step.recipes."""
        items = [a for a in el.find_all("a") if link_kind(a)[0] == "item" and RECIPE_PREFIX.match(text(a))]
        npcs = [s for s in (self.npc_ref(a) for a in el.find_all("a")) if s]
        if items:
            for a in items:
                r = {"i": link_kind(a)[1], "n": text(a), "npcs": list(npcs)}
                step.setdefault("recipes", []).append(r)
        elif npcs and step.get("recipes") and context_text.rstrip().endswith(":"):
            # the vendor list under 'Recipe: X is sold by these vendors:'
            for s in npcs:
                if s not in step["recipes"][-1]["npcs"]:
                    step["recipes"][-1]["npcs"].append(s)
        for s in npcs:
            step.setdefault("npcs", [])
            if s not in step["npcs"]:
                step["npcs"].append(s)

    def add_step(self, step):
        self.cur_skill = step.get("skill") or self.skill
        if step.get("from") is None:
            step["from"] = self.prev_to
        if step.get("to") is None:
            step["to"] = step["from"]
        if not step.get("pick"):
            step.pop("pick", None)
        for k in ("note", "alts", "recipes", "npcs", "text"):
            if k in step and not step[k]:
                del step[k]
        self.g["entries"].append(step)
        self.tier_steps = getattr(self, "tier_steps", 0) + 1
        self.prev_to = step["to"]
        self.last_step = step
        self.block = None

    def finish(self):
        # drop empty untitled blocks, fill tier trainers from the capital list
        ents = []
        for e in self.g["entries"]:
            if e["k"] == "h" and (not e.get("title") or e["lvl"] >= 4) and not e.get("text") and \
                    not e.get("vendors") and not e.get("way"):
                continue
            if e["k"] == "h" and not e.get("text"):
                e.pop("text", None)
            ents.append(e)
        self.g["entries"] = ents
        for t in self.g["tiers"]:
            if not t["trainers"]["H"] and not t["trainers"]["A"] and (t["name"] == "Apprentice" or
                                                                    re.search(r"\byour trainer\b", t["train"] or "", re.I)):
                t["trainers"] = {"H": [dict(x) for x in self.g["trainers"]["H"]],
                                 "A": [dict(x) for x in self.g["trainers"]["A"]]}
                t["sameAsCapital"] = True
            if not t["train"] and t["name"] != "Apprentice":
                warn(self.key, f"{t['name']}: no training requirement text found")
        if not self.g["entries"]:
            warn(self.key, "no guide entries parsed")


# ------------------------------------------------------------------ NPC pages
def parse_npc(slug, html):
    soup = BeautifulSoup(html, "html.parser")
    rec = {}
    h1 = soup.find("h1")
    title = text(h1)
    if " - " in title:
        rec["n"], rest = title.split(" - ", 1)
        m = re.match(r"^(.*?)\s+in\s+(.+)$", rest)
        rec["role"] = (m.group(1) if m else rest)[:60]
    elif title:
        rec["n"] = title
    emb = soup.find(attrs={"data-zone": True, "data-coords": True})
    if emb is not None:
        m = re.match(r"\s*([\d.]+)\s*,\s*([\d.]+)", emb["data-coords"])
        if m and emb["data-zone"].isdigit():
            rec["m"], rec["x"], rec["y"] = int(emb["data-zone"]), float(m.group(1)), float(m.group(2))
        rec["z"] = clean(emb.get("data-zone-name", ""))
        mz = emb.find(class_="map-zone")
        if mz is not None:
            sub = text(mz).split(",")[0].strip()
            if sub and sub != rec["z"]:
                rec["sub"] = sub
    else:
        way = re.search(r"/way #(\d+) ([\d.]+) ([\d.]+)", html)
        if way:
            rec["m"], rec["x"], rec["y"] = int(way.group(1)), float(way.group(2)), float(way.group(3))
    about = soup.find(class_="npc-about")
    p = about.find("p") if about else None
    if p is not None:
        t = text(p)
        m = re.search(r"\bis an? (Horde|Alliance|neutral)\b", t, re.I)
        if m:
            k = m.group(1).lower()
            if k == "neutral":
                rec["neutral"] = True   # both factions (Skyborne on Zephras Isle, goblin towns)
            else:
                rec["f"] = "H" if k == "horde" else "A"
    return rec


# ------------------------------------------------------------------ Lua output
IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
LUA_KEYWORDS = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto", "if", "in",
                "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}


def lua_str(s):
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "")
    s = s.replace("|", "||")  # WoW's escape character in font strings
    return '"' + s + '"'


def to_lua(v, ind=0):
    pad = "  " * ind
    if v is None:
        return "nil"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        return ("%.1f" % v).rstrip("0").rstrip(".") if v != int(v) else str(int(v))
    if isinstance(v, str):
        return lua_str(v)
    if isinstance(v, list):
        if not v:
            return "{}"
        items = [to_lua(x, ind + 1) for x in v]
        one = "{ " + ", ".join(items) + " }"
        if len(one) + len(pad) < 140 and "\n" not in one:
            return one
        return "{\n" + "".join(pad + "  " + x + ",\n" for x in items) + pad + "}"
    if isinstance(v, dict):
        parts = []
        for k, x in v.items():
            if x is None:
                continue
            key = k if isinstance(k, str) and IDENT.match(k) and k not in LUA_KEYWORDS else "[" + (
                lua_str(k) if isinstance(k, str) else str(k)) + "]"
            parts.append(key + " = " + to_lua(x, ind + 1))
        if not parts:
            return "{}"
        one = "{ " + ", ".join(parts) + " }"
        if len(one) + len(pad) < 140 and "\n" not in one:
            return one
        return "{\n" + "".join(pad + "  " + x + ",\n" for x in parts) + pad + "}"
    raise TypeError(type(v))


# ------------------------------------------------------------------ main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--cache", default=DEFAULT_CACHE, help="download cache (default: %(default)s)")
    ap.add_argument("--out", default=DEFAULT_OUT, help="Lua file to write (default: %(default)s)")
    ap.add_argument("--offline", action="store_true", help="only use the cache, never download")
    ap.add_argument("--refresh", action="store_true", help="download every page again")
    ap.add_argument("--json", help="also write the parsed data as JSON here (for inspection)")
    args = ap.parse_args()
    fx = Fetcher(args.cache, args.offline, args.refresh)

    soups = []
    for key, name, skill in GUIDES:
        html = fx.get(f"/forever/{key}-leveling-guide", f"{key}.html")
        if html is None:
            warn(key, "page could not be downloaded")
            continue
        soup = BeautifulSoup(html, "html.parser")
        NAMES.learn(soup)
        soups.append((key, name, skill, soup))

    npcs_seen = {}
    guides = [Guide(k, n, s, soup, npcs_seen).run() for k, n, s, soup in soups]

    npcs = {}
    print(f"NPC pages: {len(npcs_seen)} (cached ones are not downloaded again)")
    for slug in sorted(npcs_seen):
        html = fx.get(f"/forever/npc/{slug}", os.path.join("npc", slug + ".html"))
        rec = parse_npc(slug, html) if html else {}
        if not rec.get("n"):
            rec["n"] = npcs_seen[slug]["name"]
        # the guide's faction icons only when the NPC page does not say (shared Skyborne vendors
        # are listed under both factions there)
        if not rec.pop("neutral", False) and not rec.get("f") and npcs_seen[slug]["f"]:
            rec["f"] = npcs_seen[slug]["f"]
        if "m" not in rec:
            warn("npc", f"{slug} ({rec['n']}): no map position" + ("" if html else " (page not found)"))
        npcs[slug] = rec

    # a tier trainer list built from a paragraph without faction hints: now the NPC pages know
    for g in guides:
        for t in g["tiers"]:
            for f in ("H", "A"):
                t["trainers"][f] = [x for x in t["trainers"][f] if npcs.get(x["npc"], {}).get("f") in (None, f)]

    data = {"source": "https://www.wow-professions.com/forever (WoW-Professions.com)",
            "generated": time.strftime("%Y-%m-%d"), "npcs": npcs, "guides": guides}
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- GENERATED by tools/import_wowprof_professions.py from WoW-Professions.com's WoW Forever\n")
        f.write("-- profession guides. Their text: not committed (see .gitignore); run the script to make it.\n")
        f.write("local _, ns = ...\n")
        f.write("ns.ProfessionsData = " + to_lua(data) + "\n")
    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=1)

    print(f"wrote {os.path.relpath(args.out)} ({fx.requests} downloads)")
    for g in guides:
        steps = [e for e in g["entries"] if e["k"] == "s"]
        crafts = sum(len(e.get("crafts", [])) for e in steps)
        tr = {s for t in g["tiers"] for f in "HA" for s in (x["npc"] for x in t["trainers"][f])}
        tr |= {x["npc"] for f in "HA" for x in g["trainers"][f]}
        tr_xy = sum(1 for s in tr if "m" in npcs.get(s, {}))
        mats = [m for e in steps for c in e.get("crafts", []) for m in c["mats"]]
        print(f"  {g['name']:<18} {len(steps):3d} steps, {crafts:3d} crafts, {len(g['tiers'])} tiers, "
              f"{tr_xy}/{len(tr)} trainers with coords, {len(g['shopping'])} shopping lists "
              f"({sum(len(s['rows']) for s in g['shopping'])} rows), {len(g['recipeTables'])} recipe tables, "
              f"mats with item ID {sum(1 for m in mats if 'i' in m)}/{len(mats)}")
    if problems:
        print(f"{len(problems)} things to check:")
        for p in problems:
            print("  " + p)


if __name__ == "__main__":
    main()
