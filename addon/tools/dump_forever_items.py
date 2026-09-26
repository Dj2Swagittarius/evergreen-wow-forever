"""Read the WoW Forever beta client hotfix cache (Cache/ADB/enUS/DBCache.bin): print which DB2 tables it
holds hotfix rows for, and write forever_items.json = {itemID: {name, desc}} from its ItemSparse rows
(the items Forever added or changed). Used to turn item names from research into item ids."""
import sys, collections
sys.path.insert(0, r"E:\Project HearthBreak\tools\forever-port\casc")
from tact_keys_local import dbcache_records

def rot(x, k): return ((x << k) | (x >> (32 - k))) & 0xffffffff
def lookup3(data, initval=0):
    length = len(data)
    a = b = c = (0xdeadbeef + length + initval) & 0xffffffff
    i = 0
    while length > 12:
        a = (a + int.from_bytes(data[i:i+4], 'little')) & 0xffffffff
        b = (b + int.from_bytes(data[i+4:i+8], 'little')) & 0xffffffff
        c = (c + int.from_bytes(data[i+8:i+12], 'little')) & 0xffffffff
        a = (a - c) & 0xffffffff; a ^= rot(c, 4); c = (c + b) & 0xffffffff
        b = (b - a) & 0xffffffff; b ^= rot(a, 6); a = (a + c) & 0xffffffff
        c = (c - b) & 0xffffffff; c ^= rot(b, 8); b = (b + a) & 0xffffffff
        a = (a - c) & 0xffffffff; a ^= rot(c, 16); c = (c + b) & 0xffffffff
        b = (b - a) & 0xffffffff; b ^= rot(a, 19); a = (a + c) & 0xffffffff
        c = (c - b) & 0xffffffff; c ^= rot(b, 4); b = (b + a) & 0xffffffff
        length -= 12; i += 12
    if length == 0:
        return c
    tail = data[i:] + b"\0" * 12
    a = (a + int.from_bytes(tail[0:4], 'little')) & 0xffffffff
    b = (b + int.from_bytes(tail[4:8], 'little')) & 0xffffffff
    c = (c + int.from_bytes(tail[8:12], 'little')) & 0xffffffff
    c ^= b; c = (c - rot(b, 14)) & 0xffffffff
    a ^= c; a = (a - rot(c, 11)) & 0xffffffff
    b ^= a; b = (b - rot(a, 25)) & 0xffffffff
    c ^= b; c = (c - rot(b, 16)) & 0xffffffff
    a ^= c; a = (a - rot(c, 4)) & 0xffffffff
    b ^= a; b = (b - rot(a, 14)) & 0xffffffff
    c ^= b; c = (c - rot(b, 24)) & 0xffffffff
    return c

names = ["DungeonEncounter","JournalEncounter","JournalInstance","JournalEncounterItem","JournalEncounterSection","JournalEncounterCreature","ItemSparse","Item","LFGDungeons","Map","AreaTable","QuestV2","Creature","CreatureDisplayInfo","TactKey","ItemSearchName","JournalTierXInstance","MapDifficulty","UiMap","UiMapAssignment","WorldMapOverlay","AreaPOI","QuestPOIPoint","QuestLineXQuest","QuestLine","ItemEffect","SpellName","ItemModifiedAppearance"]
T = [0x486E26EE, 0xDCAA16B3, 0xE1918EEF, 0x202DAFDB, 0x341C7DC7, 0x1C365303, 0x40EF2D37, 0x65FD5E49,
     0xD6057177, 0x904ECE93, 0x1C38024F, 0x98FD323B, 0xE3061AE7, 0xA39B0FA1, 0x9797F25F, 0xE4444563]
def sstr(name):
    seed, shift = 0x7FED7FED, 0xEEEEEEEE
    for ch in name.upper():
        c = ord(ch)
        seed = ((T[c >> 4] - T[c & 0xF]) & 0xffffffff) ^ ((shift + seed) & 0xffffffff)
        shift = (c + seed + 33 * shift + 3) & 0xffffffff
    return seed or 1
known = {sstr(n): n for n in names}
assert sstr("TactKey") == 0xDF2F53CF, hex(sstr("TactKey"))
x = open(r"E:\Program Files (x86)\World of Warcraft\_classic_beta_\Cache\ADB\enUS\DBCache.bin", "rb").read()
ver, build, recs, end = dbcache_records(x)
c = collections.Counter((r["table"], r["status"]) for r in recs)
for (t, st), n in c.most_common(40):
    print("0x%08X %-24s status %d  %5d" % (t, known.get(t, "?"), st, n))

# ---- ItemSparse hotfix rows -> {id: name}; strings sit inline at the start of the row
import json
names = {}
for r in recs:
    if r["table"] == 0x919BE54E and r["status"] == 1 and r["data"]:
        d = r["data"]
        # AllowableRace (8 bytes) then Description, Display3, Display2, Display1, Display (null-terminated)
        p = 0
        strs = []
        for _ in range(5):
            e = d.find(b"\0", p)
            if e < 0: break
            strs.append(d[p:e].decode("utf-8", "replace"))
            p = e + 1
        if len(strs) == 5 and strs[4]:
            names[r["id"]] = {"name": strs[4], "desc": strs[0]}
json.dump(names, open(r"C:\Users\DJ\Desktop\WoW guide\addon\tools\forever_items.json", "w"), indent=0)
ids = sorted(names)
print("items", len(names), "id range", ids[0], ids[-1])
for i in ids[-8:]: print(i, names[i])
