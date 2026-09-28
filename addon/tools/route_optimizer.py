"""Evergreen route optimizer (prototype).

Takes a route export from export_route.lua, turns every quest into accept / objective / turn-in
events placed in world yards (uimap_world.json, from the Forever client's UiMapAssignment), and
searches for the event order that levels fastest under a simple time model:

  time = running (7 yd/s, or hearthstone when it is up and saves time)
       + objective work (fixed per quest, same for every order)
       + grinding whenever the simulated level is below a quest's required level
       + a penalty for doing objectives under-levelled

Hard rules: accept < objective < turn-in; chain prerequisites (Questie preQuest data, same-name
parts, and the hand route's own giver/turn-in links); visit steps (binds, flight points, manual
steps) keep the level at which the hand route placed them. Class quests are placed per class by
cheapest insertion into the common order.

Writes Routes_<Name>_Opt.lua (a separate, selectable route) and prints a comparison with the
hand-made order under the same model. Usage:

  python route_optimizer.py forsaken_b1-3.json --out ../Evergreen_Guide/Routes_Forsaken_Opt.lua
"""
import argparse, json, math, os, random, re, copy

HERE = os.path.dirname(os.path.abspath(__file__))
RUN = 7.0                   # yd/s on foot
HEARTH_CAST, HEARTH_CD = 35.0, 3600.0
OBJ_TIME = 150.0            # seconds of objective work per quest with an objective
KILL_XP_SHARE = 0.6         # kill XP earned doing a quest, as a share of its turn-in XP
XP_TO_LEVEL = [0, 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100, 11400, 12900,
               14400, 16000, 17700, 19400, 21300, 23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400]
CLASSES = ["WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"]

# ---------------------------------------------------------------- world coordinates
UIMAP = {int(k): v for k, v in json.load(open(os.path.join(HERE, "uimap_world.json"))).items()}


def world(x, y, ui):
    m = UIMAP.get(ui)
    if not m:
        return None
    u = (x / 100.0 - m["umin"][0]) / (m["umax"][0] - m["umin"][0])
    v = (y / 100.0 - m["umin"][1]) / (m["umax"][1] - m["umin"][1])
    r = m["region"]  # minX minY minZ maxX maxY maxZ; map x runs along -Y, map y along -X
    return (m["map"], r[3] - v * (r[3] - r[0]), r[4] - u * (r[4] - r[1]), ui)


# Straight lines ignore mountains: zone borders are crossed on roads, and city maps sit under or
# inside the zone they belong to (Undercity: walk in, ride the elevators). Crossing a zone line
# costs a detour factor plus a fixed amount; entering or leaving a city costs a fixed amount.
ZONE_DETOUR, ZONE_FIXED = 1.35, 150.0
CITY_FIXED = {1458: 450.0, 1454: 250.0, 1456: 300.0, 1453: 250.0, 1455: 250.0, 1457: 300.0}


def dist(a, b):
    if a is None or b is None:
        return 0.0
    if a[0] != b[0]:
        return 20000.0
    d = math.hypot(a[1] - b[1], a[2] - b[2])
    if a[3] != b[3]:
        d = d * ZONE_DETOUR + ZONE_FIXED + CITY_FIXED.get(a[3], 0.0) + CITY_FIXED.get(b[3], 0.0)
    return d


def level_of(xp):
    lvl, need = 1, 0
    while lvl < len(XP_TO_LEVEL) and xp >= need + XP_TO_LEVEL[lvl]:
        need += XP_TO_LEVEL[lvl]
        lvl += 1
    return lvl


def xp_at_level(lvl):
    return sum(XP_TO_LEVEL[1:lvl])


def grind_rate(lvl):  # xp per second of grinding at-level mobs
    return (45 + 5 * lvl) * 2.2 / 60.0


def mob_xp(mlvl, plvl):
    """Classic kill XP: 45 + 5 * mob level, scaled by the level difference."""
    base = 45 + 5 * mlvl
    d = mlvl - plvl
    if d >= 0:
        return base * (1 + 0.05 * min(d, 4))
    gray = 5 if plvl < 10 else 6 if plvl < 20 else 7
    if -d >= gray:
        return 0
    return base * (1 + d / 17.0)


def quest_xp(base, qlvl, plvl):
    d = plvl - qlvl
    if d <= 5:
        return base
    return base * {6: .8, 7: .6, 8: .4, 9: .2}.get(d, .1)


# ---------------------------------------------------------------- loading
def medoid(points):
    if not points:
        return None
    pts = points if len(points) <= 150 else random.Random(1).sample(points, 150)
    best, bd = None, None
    for p in pts:
        d = sum(dist(p, q) for q in pts)
        if bd is None or d < bd:
            best, bd = p, d
    return best


def nearest(points, ref):
    if not points:
        return None
    if ref is None:
        return points[0]
    return min(points, key=lambda p: dist(p, ref))


def coord(c, bmap):
    """Route coord table {x, y, label, map?} -> (world, x, y, map, label) or None for 0,0 / missing."""
    if not c or not isinstance(c, list) or len(c) < 2:
        return None
    x, y = c[0], c[1]
    label = c[2] if len(c) > 2 else None
    ui = c[3] if len(c) > 3 and isinstance(c[3], (int, float)) else bmap
    if not x and not y:
        return (None, 0, 0, ui, label)
    return (world(x, y, int(ui)), x, y, int(ui), label)


class Event:
    __slots__ = ("kind", "quest", "loc", "min_level", "idx", "cls", "visit", "notes", "order")

    def __init__(self, kind, quest, loc, min_level=0, cls=None):
        self.kind, self.quest, self.loc, self.min_level, self.cls = kind, quest, loc, min_level, cls


class Quest:
    def __init__(self, key, step, facts, bmap, order):
        self.key, self.step, self.facts, self.bmap, self.order = key, step, facts or {}, bmap, order
        self.cls = step.get("cls")
        f = self.facts
        self.req = f.get("reqLevel") or 1
        self.level = f.get("level") or self.req
        self.xp = f.get("xp") or (60 + 55 * max(self.level, 1))
        # objective work: kill/collect counts read from the quest text ("Kill 10 ..", "8 Scarlet Armbands")
        # the hand route's objective label usually carries the counts; strip coordinates first
        olabel = ""
        if isinstance(step.get("o"), list) and len(step["o"]) > 2 and isinstance(step["o"][2], str):
            olabel = re.sub(r"\d+(\.\d+)?\s*,\s*\d+(\.\d+)?", " ", step["o"][2])
        nums = [int(n) for n in re.findall(r"\b(\d{1,2})\b", olabel) if 0 < int(n) <= 40]
        if not nums:
            nums = [int(n) for n in re.findall(r"\b(\d{1,2})\b", f.get("objText") or "") if 0 < int(n) <= 40]
        if nums:
            self.count = sum(nums)
        elif f.get("kills") is False or (not f and not step.get("o")):
            self.count = 0
        else:
            self.count = 6
        self.mob_level = f.get("mobLevel") or self.level
        g, o, r = coord(step.get("g"), bmap), coord(step.get("o"), bmap), coord(step.get("r"), bmap)
        wg = g[0] if g else None
        if wg is None:
            wg = nearest([world(x, y, ui) for x, y, ui in f.get("starts", [])], None)
        wo = o[0] if o else None
        if wo is None and f.get("obj"):
            wo = medoid([world(x, y, ui) for x, y, ui in f["obj"]])
        wr = r[0] if r else None
        if wr is None and f.get("ends"):
            wr = nearest([world(x, y, ui) for x, y, ui in f["ends"]], wo or wg)
        if wr is None and not r:
            wr = wg
        self.g, self.o, self.r = g, o, r
        self.events = [Event("A", self, wg)]
        if wo is not None or (o and o[0] is None):
            self.events.append(Event("O", self, wo))
        self.events.append(Event("T", self, wr))
        self.pre = []


def npc_name(c):
    if not c or len(c) < 3 or not isinstance(c[2], str):
        return None
    return re.split(r"[,:(]", c[2])[0].strip().lower() or None


def load(path):
    d = json.load(open(path))
    facts = d["facts"]
    quests, visits, notes = [], [], []
    order = 0
    pending_notes = []
    for b in d["brackets"]:
        gate = b["lv"][0]
        for s in b["steps"]:
            order += 1
            if s.get("lv"):
                gate = s["lv"]
                continue
            if s.get("note") or s.get("forever"):
                pending_notes.append(s)
                continue
            if s.get("q"):
                f = facts.get(str(s.get("qid"))) if s.get("qid") else None
                q = Quest("%s#%d" % (s["q"], s.get("p", 1)) + ("@" + str(s.get("cls")) if s.get("cls") else ""), s, f, b["map"], order)
                q.hand_gate = gate
                q.notes = pending_notes
                pending_notes = []
                quests.append(q)
            elif s.get("bind") or s.get("fp") or s.get("man") or (s.get("tr") and s.get("any")):
                ui = int(s.get("map") or b["map"])
                loc = world(s["x"], s["y"], ui) if s.get("x") else None
                ev = Event("V", None, loc, gate, s.get("cls"))
                ev.visit = dict(s, map=ui)
                ev.notes = pending_notes
                ev.order = order
                pending_notes = []
                visits.append(ev)
            # plain travel steps are dropped: the optimizer makes its own path
    # prerequisites
    by_qid = {}
    for q in quests:
        if q.step.get("qid"):
            by_qid.setdefault(q.step["qid"], []).append(q)
    by_name = {}
    for q in quests:
        by_name.setdefault((q.step["q"], str(q.cls)), []).append(q)
    for q in quests:
        f = q.facts
        for pid in (f.get("preAll") or []):
            q.pre += by_qid.get(pid, [])
        single = [p for pid in (f.get("pre") or []) for p in by_qid.get(pid, [])]
        if single:
            q.pre.append(min(single, key=lambda p: p.order))  # any one of: the earliest in the route
        same = by_name[(q.step["q"], str(q.cls))]
        for p in same:
            if p.step.get("p", 1) < q.step.get("p", 1):
                q.pre.append(p)
        # no Questie data (Forever quests): chain to the nearest earlier quest whose turn-in NPC gives this one
        if not q.facts:
            giver = npc_name(q.step.get("g"))
            if giver:
                for p in sorted(quests, key=lambda p: -p.order):
                    if p.order < q.order and npc_name(p.step.get("r")) == giver and p.cls == q.cls:
                        q.pre.append(p)
                        break
    return d, quests, visits


# ---------------------------------------------------------------- simulation
def simulate(seq, start, detail=False):
    pos, t, xp = start, 0.0, 0
    bind, hearth_ready = None, 0.0
    bind_step = None
    grind, run, pen = 0.0, 0.0, 0.0
    log = []
    for ev in seq:
        lvl = level_of(xp)
        # level requirements
        need = ev.min_level if ev.kind == "V" else (ev.quest.req if ev.kind == "A" else 0)
        if need and lvl < need:
            deficit = xp_at_level(need) - xp
            g = deficit / grind_rate(lvl)
            t += g; grind += g; xp += deficit; lvl = need
            if detail:
                log.append(("grind", need, g))
        if ev.loc is not None:
            walk = dist(pos, ev.loc) / RUN
            cost = walk
            if bind is not None and t >= hearth_ready:
                h = HEARTH_CAST + dist(bind, ev.loc) / RUN
                if h + 30 < walk:
                    cost = h; hearth_ready = t + HEARTH_CD
                    if detail:
                        log.append(("hearth", ev, walk - h, bind_step))
            t += cost; run += cost
            pos = ev.loc
        if ev.kind == "O":
            q = ev.quest
            kills = q.count * 1.4                      # item drops are not 100%
            per_kill = 22.0 + 6.0 * max(0, q.mob_level - lvl)   # harder, slower kills when under-levelled
            work = 45.0 + kills * per_kill
            t += work
            if lvl < q.mob_level - 1:
                pen += kills * 6.0 * (q.mob_level - 1 - lvl)
            xp += int(kills * mob_xp(q.mob_level, lvl))
        elif ev.kind == "T":
            q = ev.quest
            xp += int(quest_xp(q.xp, q.level, lvl))

        elif ev.kind == "V" and ev.visit.get("bind"):
            bind = ev.loc
            bind_step = ev.visit
        if detail:
            log.append(("ev", ev, t, level_of(xp)))
    return t, dict(time=t, run=run, grind=grind, penalty=pen, xp=xp, level=level_of(xp), log=log)


def valid(seq):
    pos = {id(e): i for i, e in enumerate(seq)}
    for e in seq:
        if e.kind in "OT":
            q = e.quest
            evs = q.events
            if pos[id(evs[evs.index(e) - 1])] > pos[id(e)]:
                return False
        if e.kind == "A":
            for p in e.quest.pre:
                if id(p.events[-1]) in pos and pos[id(p.events[-1])] > pos[id(e)]:
                    return False
    return True


def fast_valid_move(seq, pos, i, j):
    """Would moving seq[i] to index j (after removal) keep precedence? pos: id -> index."""
    e = seq[i]
    target = j if j < i else j  # index in the list after removal/insert
    new = seq[:i] + seq[i + 1:]
    new.insert(j, e)
    return valid(new), new


def repair(seq, label):
    """Report prerequisite breaks in a hand order and fix them by moving the late prerequisite's
    events just before the quest that needs it (so the baseline is something you can play)."""
    seq = list(seq)
    for _ in range(50):
        pos = {id(e): i for i, e in enumerate(seq)}
        bad = None
        for e in seq:
            if e.kind == "A":
                for p in e.quest.pre:
                    if id(p.events[-1]) in pos and pos[id(p.events[-1])] > pos[id(e)]:
                        bad = (e, p)
                        break
            if bad:
                break
        if not bad:
            return seq
        e, p = bad
        print("  HAND ROUTE BUG (%s): '%s' is listed before its prerequisite '%s'" % (label, e.quest.step["q"], p.step["q"]))
        moved = [x for x in seq if x.quest is p]
        seq = [x for x in seq if x.quest is not p]
        at = seq.index(e)
        seq = seq[:at] + moved + seq[at:]
    return seq


# ---------------------------------------------------------------- search
def optimize(seq, start, iters, seed=7, keep_objective_order=False):
    """Simulated annealing over block moves. keep_objective_order: only pickups, turn-ins and
    visits may move (the "hand route, batched" baseline a sensible player gets by themselves)."""
    rnd = random.Random(seed)
    obj_order = [id(e) for e in seq if e.kind == "O"]
    best = cur = list(seq)
    best_t = cur_t = simulate(cur, start)[0]
    temp0 = 120.0
    n = len(cur)
    for it in range(iters):
        temp = temp0 * (1 - it / iters) + 0.5
        i = rnd.randrange(n)
        blk = 1 if rnd.random() < 0.6 else rnd.randint(2, 6)
        blk = min(blk, n - i)
        block = cur[i:i + blk]
        rest = cur[:i] + cur[i + blk:]
        # move near something: pick a target position biased to spatially close events
        if rnd.random() < 0.7 and block[0].loc is not None:
            cands = rnd.sample(range(len(rest)), min(12, len(rest)))
            j = min(cands, key=lambda k: dist(rest[k].loc, block[0].loc) if rest[k].loc is not None else 1e9) + rnd.randint(0, 1)
        else:
            j = rnd.randrange(len(rest) + 1)
        new = rest[:j] + block + rest[j:]
        if keep_objective_order and [id(e) for e in new if e.kind == "O"] != obj_order:
            continue
        if not valid(new):
            continue
        t = simulate(new, start)[0]
        if t < cur_t or rnd.random() < math.exp((cur_t - t) / temp):
            cur, cur_t = new, t
            if t < best_t:
                best, best_t = list(new), t
    return best, best_t


def insert_class(common, cls_quests, start):
    """Cheapest insertion of one class's events into the common order (keeps precedence)."""
    seq = list(common)
    for q in sorted(cls_quests, key=lambda q: q.order):
        lo = 0
        for ev in q.events:
            best_j, best_t = None, None
            for j in range(lo, len(seq) + 1):
                cand = seq[:j] + [ev] + seq[j:]
                if not valid(cand):
                    continue
                t = simulate(cand, start)[0]
                if best_t is None or t < best_t:
                    best_j, best_t = j, t
            if best_j is None:
                best_j = len(seq)
            seq.insert(best_j, ev)
            lo = best_j + 1
    return seq


# ---------------------------------------------------------------- output
def lua(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int,)):
        return str(v)
    if isinstance(v, float):
        return ("%.1f" % v).rstrip("0").rstrip(".")
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, list):
        return "{" + ",".join(lua(x) for x in v) + "}"
    if isinstance(v, dict):
        parts = []
        for k, x in v.items():
            parts.append(("%s=" % k if re.match(r"^[A-Za-z_]\w*$", k) else "[%s]=" % lua(k)) + lua(x))
        return "{" + ", ".join(parts) + "}"
    return "nil"


STEP_KEYS = ["q", "p", "id", "act", "cls", "opt", "g", "o", "r"]


def with_map(c, bmap):
    if not c or not isinstance(c, list):
        return c
    c = list(c)
    while len(c) < 3:
        c.append("")
    if len(c) < 4:
        c.append(bmap)
    return c


def emit_steps(seq, hearths=None):
    """Group consecutive events of one quest into steps (whole / accept / do / turn-in).
    hearths: id(event) -> bind step, for events the plan reaches by hearthstone."""
    out, i = [], 0
    hearths = hearths or {}
    while i < len(seq):
        e = seq[i]
        hb = hearths.get(id(e))
        if hb:
            out.append({"tr": True, "x": hb["x"], "y": hb["y"], "map": hb["map"],
                        "t": "Hearth to %s (the plan counts on it here; walk if it is on cooldown)." % hb["bind"]})
        if e.kind == "V":
            for n in getattr(e, "notes", []):
                out.append(dict(n))
            v = {k: x for k, x in e.visit.items() if k not in ("key",)}
            out.append(v)
            i += 1
            continue
        q = e.quest
        run = [e]
        while i + len(run) < len(seq) and seq[i + len(run)].quest is q:
            run.append(seq[i + len(run)])
        kinds = "".join(x.kind for x in run)
        s = {k: q.step[k] for k in STEP_KEYS if k in q.step}
        for k in ("g", "o", "r"):
            if k in s:
                s[k] = with_map(s[k], q.bmap)
        if s.get("id") is None and q.step.get("qid") and not q.facts == {}:
            pass
        if kinds[-1] == "T" and len(kinds) > 1:
            pass                                  # whole step
        elif kinds == "T":
            s["act"] = "turnin"
        elif kinds == "A":
            s["act"] = "accept"
        else:
            s["act"] = "do"                       # O or AO
        if kinds[0] == "A" or kinds == "AO":
            for n in getattr(q, "notes", []):
                out.append(dict(n))
            q.notes = []
        out.append(s)
        i += len(run)
    return out


def split_brackets(seq, start, hand_brackets):
    """Cut the event order into brackets at the hand route's level boundaries (simulated level)."""
    _, info = simulate(seq, start, detail=True)
    levels = [lv for kind, *rest in info["log"] if kind == "ev" for lv in [rest[2]]]
    bounds = [b["lv"][1] for b in hand_brackets]
    cuts, bi = [], 0
    for idx, lvl in enumerate(levels):
        while bi < len(bounds) - 1 and lvl >= bounds[bi]:
            cuts.append(idx + 1)
            bi += 1
    parts, prev = [], 0
    for c in cuts + [len(seq)]:
        parts.append(seq[prev:c])
        prev = c
    while len(parts) < len(hand_brackets):
        parts.append([])
    return parts, info


def report(name, info):
    return "%-10s %6.1f min total | running %5.1f | grinding %5.1f | under-level penalty %4.1f | ends level %d" % (
        name, info["time"] / 60, info["run"] / 60, info["grind"] / 60, info["penalty"] / 60, info["level"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("export")
    ap.add_argument("--out", required=True)
    ap.add_argument("--iters", type=int, default=400000)
    ap.add_argument("--seeds", type=int, default=4)
    ap.add_argument("--route-id", default=None)
    ap.add_argument("--class", dest="only_class", default=None)
    args = ap.parse_args()

    d, quests, visits = load(args.export)
    common_q = [q for q in quests if not q.cls]
    class_q = [q for q in quests if q.cls]

    def hand_order(qs, vs):
        items = [(q.order, q) for q in qs] + [(v.order, v) for v in vs]
        seq = []
        for _, x in sorted(items, key=lambda t: t[0]):
            seq += x.events if isinstance(x, Quest) else [x]
        return seq

    common_visits = [v for v in visits if not v.cls]
    hand = hand_order(common_q, common_visits)
    start = hand[0].loc
    hand = repair(hand, "common")
    t_hand, info_hand = simulate(hand, start)
    print("common quests %d, class quests %d, visit steps %d, events %d" % (len(common_q), len(class_q), len(visits), len(hand)))
    print(report("hand", info_hand))
    batched, _ = optimize(hand, start, max(50000, args.iters // 4), seed=99, keep_objective_order=True)
    info_batched = simulate(batched, start)[1]
    print(report("batched", info_batched) + "   (hand objective order, pickups/turn-ins batched)")
    best, t_best = None, None
    for seed in range(args.seeds):
        cand, t_c = optimize(hand, start, args.iters, seed=seed + 1)
        print("  seed %d: %.1f min" % (seed + 1, t_c / 60))
        if t_best is None or t_c < t_best:
            best, t_best = cand, t_c
    _, info_best = simulate(best, start)
    print(report("optimized", info_best))

    # per-class comparison and insertion
    classes = sorted({q.cls for q in class_q if isinstance(q.cls, str)})
    if args.only_class:
        classes = [args.only_class]
    merged_extra = {}   # index in best -> list of class events placed after it
    for cls in classes:
        cq = [q for q in class_q if q.cls == cls]
        cv = [v for v in visits if v.cls == cls]
        h = hand_order(common_q + cq, common_visits + cv)
        h = repair(h, cls)
        th = simulate(h, start)[1]
        placed = insert_class(best, cq, start)
        for v in cv:  # class visit steps: cheapest valid spot
            placed = insert_class(placed, [], start)
            j = min(range(len(placed) + 1), key=lambda j: simulate(placed[:j] + [v] + placed[j:], start)[0])
            placed.insert(j, v)
        to = simulate(placed, start)[1]
        print("  %-8s hand %5.1f min -> optimized %5.1f min (%+.1f)" % (cls, th["time"] / 60, to["time"] / 60, (to["time"] - th["time"]) / 60))
        # remember where each class event landed relative to the common events
        last_common = -1
        common_idx = {id(e): k for k, e in enumerate(best)}
        for e in placed:
            if id(e) in common_idx:
                last_common = common_idx[id(e)]
            else:
                merged_extra.setdefault(last_common, []).append(e)

    final = list(merged_extra.get(-1, []))
    for k, e in enumerate(best):
        final.append(e)
        final += merged_extra.get(k, [])

    hearths = {}
    for kind, *rest in simulate(best, start, detail=True)[1]["log"]:
        if kind == "hearth" and rest[2]:
            hearths[id(rest[0])] = rest[2]
    parts, info = split_brackets(best, start, d["brackets"])
    # re-split the merged list on the same common cut points
    cut_events = [p[-1] for p in parts[:-1] if p]
    brackets_out, cur = [], []
    ci = 0
    for e in final:
        cur.append(e)
        if ci < len(cut_events) and e is cut_events[ci]:
            # pull this common event's trailing class events along before cutting
            brackets_out.append(cur); cur = []; ci += 1
    brackets_out.append(cur)
    while len(brackets_out) < len(d["brackets"]):
        brackets_out.append([])

    rid = args.route_id or (d["route"] + "-opt")
    lines = ["-- GENERATED by addon/tools/route_optimizer.py from route '%s' (brackets %s). Do not edit by hand:" % (d["route"], ", ".join(b["id"] for b in d["brackets"])),
             "-- edit the hand route, re-export, re-run. Time model and rules: see the tool's docstring.",
             "-- " + report("hand", info_hand),
             "-- " + report("batched", info_batched),
             "-- " + report("optimized", info_best),
             "local ADDON, ns = ...", "", "local OPT = {"]
    for hb, evs in zip(d["brackets"], brackets_out):
        steps = emit_steps(evs, hearths)
        lines.append("  {")
        lines.append("    id=%s, lv=%s, name=%s, map=%d," % (lua(hb["id"] + "o"), lua(hb["lv"]), lua(hb["name"] + " (optimized)"), hb["map"]))
        lines.append("    hub=%s, hearth=%s, fp=%s," % (lua(hb.get("hub") or ""), lua(hb.get("hearth") or ""), lua(hb.get("fp") or "")))
        lines.append("    steps={")
        for s in steps:
            lines.append("      " + lua(s) + ",")
        lines.append("      {lv=%d}," % hb["lv"][1])
        lines.append("    },")
        lines.append("  },")
    lines.append("}")
    lines += ["",
              "-- the rest of the hand route follows unchanged",
              "local src",
              "for _, r in ipairs(ns.ROUTES) do if r.id == %s then src = r end end" % lua(d["route"]),
              "if not src then return end",
              "local brackets = {}",
              "for _, b in ipairs(OPT) do table.insert(brackets, b) end",
              "for i = %d, #src.brackets do table.insert(brackets, src.brackets[i]) end" % (len(d["brackets"]) + 1),
              "table.insert(ns.ROUTES, {",
              "  id = %s, name = src.name .. \" (optimized)\", faction = src.faction," % lua(rid),
              "  races = src.races, raceOnly = src.raceOnly, optimized = true,",
              "  brackets = brackets,",
              "})", ""]
    with open(args.out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote", args.out)


if __name__ == "__main__":
    main()
