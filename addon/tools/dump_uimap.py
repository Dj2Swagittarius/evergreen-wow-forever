"""Dump UiMapAssignment (uiMapID -> world-space box) from the Forever beta client to JSON.
Used by route_optimizer.py to turn zone-percent coordinates into world yards."""
import sys, os, json, struct
sys.path.insert(0, r"E:\Project HearthBreak\tools\forever-port\casc")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import forever_casc, wdc5
t = wdc5.read(forever_casc.Reader().read(1957219))
best = {}
for _id, _rel, v in t["rows"]:
    umin = struct.unpack("<2f", v[0]); umax = struct.unpack("<2f", v[1]); reg = struct.unpack("<6f", v[2])
    ui, order, mapid, area = v[4], v[5], v[6], v[7]
    if umax[0] - umin[0] <= 0 or reg[3] - reg[0] <= 0:
        continue
    cover = (umax[0] - umin[0]) * (umax[1] - umin[1])
    cur = best.get(ui)
    if cur is None or (order, -cover) < (cur["order"], -cur["cover"]):
        best[ui] = dict(order=order, cover=cover, map=mapid, area=area, umin=umin, umax=umax, region=reg)
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uimap_world.json")
json.dump({str(k): v for k, v in best.items()}, open(out, "w"), indent=0)
for ui in (1420, 1421, 1458, 1424):
    b = best[ui]; r = b["region"]
    print(ui, "map", b["map"], "width yd %.0f height yd %.0f" % ((r[4] - r[1]) / (b["umax"][0] - b["umin"][0]), (r[3] - r[0]) / (b["umax"][1] - b["umin"][1])))
print(len(best), "maps ->", out)
