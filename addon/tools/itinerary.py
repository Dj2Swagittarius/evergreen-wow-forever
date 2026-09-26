"""Print a generated route's itinerary with per-leg distances, to audit an optimizer run.
usage: python itinerary.py <Routes_X_Opt.lua> [class]"""
import re, sys, math, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from route_optimizer import world, dist
src = open(sys.argv[1], encoding="utf-8").read()
cls = sys.argv[2] if len(sys.argv) > 2 else None
NAMES = {1420: "Tirisfal", 1421: "Silverpine", 1458: "Undercity", 1424: "Hillsbrad"}
pos, total, longs, zone_changes, last_zone = None, 0, [], 0, None
for line in src.split("\n"):
    m = re.search(r'\{q="([^"]+)"', line)
    b = re.search(r'id="(\w+)", lv=\{(\d+),(\d+)\}', line)
    if b:
        print("== %s %s-%s" % b.groups())
        continue
    if not m:
        continue
    c = re.search(r'cls="(\w+)"', line)
    if c and c.group(1) != cls:
        continue
    act = re.search(r'act="(\w+)"', line)
    act = act.group(1) if act else "full"
    key = {"accept": "g", "do": "o", "turnin": "r", "full": "g"}[act]
    cm = re.search(key + r'=\{([\d.]+),([\d.]+),"[^"]*",(\d+)\}', line) or re.search(r'g=\{([\d.]+),([\d.]+),"[^"]*",(\d+)\}', line)
    if not cm:
        continue
    x, y, ui = float(cm.group(1)), float(cm.group(2)), int(cm.group(3))
    if x == 0 and y == 0:
        continue
    w = world(x, y, ui)
    d = dist(pos, w) if pos else 0
    total += d
    if ui != last_zone:
        zone_changes += 1
        last_zone = ui
    flag = "  <-- long" if d > 900 else ""
    if d > 900:
        longs.append((m.group(1), act, int(d)))
    print("  %-8s %-34s %-10s %5.0f,%-5.0f %5d yd%s" % (act, m.group(1)[:34], NAMES.get(ui, ui), x, y, d, flag))
    pos = w
print("total %.0f yd (%.0f min at 7 yd/s), zone changes %d, legs over 900 yd: %d" % (total, total / 7 / 60, zone_changes, len(longs)))
