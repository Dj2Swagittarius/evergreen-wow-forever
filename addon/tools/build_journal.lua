-- Build Evergreen_Journal/Journal_Data.lua: every Classic dungeon and raid with its bosses, their loot,
-- and every quest that belongs to it (giver, turn-in, level, prerequisites, rewards).
--
-- Sources (both open, both read locally):
--   * AtlasLootClassic (GPL-2, github.com/Hoizame/AtlasLootClassic): boss list + loot item ids.
--   * Questie's Classic database (ships inside the Questie addon): dungeon entrances, quests, NPC
--     spawns, and which quests reward which items.
-- Item names, icons and tooltips are NOT stored: the game supplies them at runtime from the id.
--
-- usage: luajit build_journal.lua <AtlasLootClassic_DungeonsAndRaids/data.lua> <questie Database dir> <out.lua> [forever_dungeons.lua]
-- The optional last file adds WoW Forever's new instances (hand-curated from research, same schema,
-- see tools/forever_dungeons.lua).

local alFile, qdir, outFile, foreverFile = arg[1], arg[2], arg[3], arg[4]
assert(outFile, "usage: luajit build_journal.lua <atlasloot data.lua> <questie Database dir> <out.lua>")
local bit = require("bit")

-- ---------------------------------------------------------------- AtlasLoot, run in a sandbox
local DIFF = {}      -- difficulty token -> kind
local diffN = 0
local function stubFn() return nil end
local dataObj = {}
local dataMeta = {
  AddDifficulty = function(_, name, key)
    diffN = diffN + 1
    local kind = (name == "NORMAL" and "normal") or (name == "20RAID" and "raid20") or (name == "40RAID" and "raid40")
      or (key == "horde" and "horde") or (key == "alliance" and "alliance") or tostring(name)
    DIFF[diffN] = kind
    return diffN
  end,
  AddItemTableType = function() diffN = diffN + 1; return 1000 + diffN end,
  AddExtraItemTableType = function() diffN = diffN + 1; return 2000 + diffN end,
  AddContentType = function(_, name) return name end,
}
setmetatable(dataObj, { __index = dataMeta })
local function deepStub()
  return setmetatable({}, { __index = function(t, k) local v = deepStub(); rawset(t, k, v); return v end,
                            __call = function() return nil end })
end
local env = setmetatable({
  UnitFactionGroup = function() return "Horde" end,
  FACTION_HORDE = "Horde", FACTION_ALLIANCE = "Alliance",
  ATLASLOOT_DUNGEON_COLOR = "", ATLASLOOT_RAID20_COLOR = "", ATLASLOOT_RAID40_COLOR = "",
}, { __index = _G })
env._G = env
local AL = setmetatable({}, { __index = function(_, k) return k end })
local AtlasLoot = deepStub()
rawset(AtlasLoot, "ItemDB", { Add = function() return dataObj end })
rawset(AtlasLoot, "Locales", AL)
rawset(AtlasLoot, "IngameLocales", AL)
rawset(AtlasLoot, "ReturnForGameVersion", function(a) return a end)
rawset(AtlasLoot, "CLASSIC_VERSION_NUM", 1)
rawset(AtlasLoot, "GetRetByFaction", function(_, h) return h end)
env.AtlasLoot = AtlasLoot
-- the data file reads its globals through getfenv(0), i.e. the real global table
for k, v in pairs(env) do if k ~= "_G" then _G[k] = v end end
local DUNGEON_NAMES = {}
do
  local src = assert(io.open(qdir .. "/Zones/data/dungeons.lua")):read("*a")
  for id, name in src:gmatch("%[(%d+)%]%s*=%s*{\"([^\"]+)\"") do DUNGEON_NAMES[tonumber(id)] = name end
end
C_Map = { GetAreaInfo = function(id) return DUNGEON_NAMES[id] or ("Area " .. tostring(id)) end }
setmetatable(_G, { __index = function(_, k) if type(k) == "string" and k:match("^[A-Z]") then return deepStub() end end })
local chunk = assert(loadfile(alFile))
local ok, err = pcall(chunk, "AtlasLootClassic_DungeonsAndRaids")
if not ok then io.stderr:write("atlasloot load stopped: ", tostring(err), "\n") end

-- ---------------------------------------------------------------- Questie
local function loadDB(file, field)
  local src = assert(io.open(qdir .. "/" .. file)):read("*a")
  local body = assert(src:match(field .. "%s*=%s*%[%[(.-)%]%]"), "no " .. field)
  local t = {}
  for line in body:gmatch("[^\n]+") do
    local id, entry = line:match("^%[(%d+)%]%s*=%s*(%b{}),?%s*$")
    if id then local fn = loadstring("return " .. entry); if fn then t[tonumber(id)] = fn() end end
  end
  return t
end
local quests  = loadDB("Classic/classicQuestDB.lua", "QuestieDB.questData")
local npcs    = loadDB("Classic/classicNpcDB.lua", "QuestieDB.npcData")
local objects = loadDB("Classic/classicObjectDB.lua", "QuestieDB.objectData")
local items   = loadDB("Classic/classicItemDB.lua", "QuestieDB.itemData")

-- dungeons.lua: [areaId] = {name, altAreaIds, parentZone, {{zone, x, y}, ...}}
local dungeons = {}
do
  local src = assert(io.open(qdir .. "/Zones/data/dungeons.lua")):read("*a")
  local body = assert(src:match("local dungeons = (%b{})"))
  dungeons = assert(loadstring("return " .. body))()
end
-- Questie areaId -> uiMapID (Classic world zones and cities)
local ZONE = {
  [85]=1420, [130]=1421, [17]=1413, [267]=1424, [331]=1440, [400]=1441, [33]=1434, [405]=1443, [45]=1417, [15]=1445,
  [3]=1418, [8]=1435, [440]=1446, [357]=1444, [47]=1425, [51]=1427, [490]=1449, [361]=1448, [46]=1428, [16]=1447,
  [28]=1422, [139]=1423, [618]=1452, [1377]=1451, [1497]=1458, [1637]=1454, [1638]=1456, [14]=1411, [215]=1412,
  [36]=1416, [1519]=1453, [1537]=1455, [1657]=1457, [12]=1429, [40]=1436, [44]=1433, [10]=1431, [38]=1432,
  [1]=1426, [11]=1437, [141]=1438, [148]=1439, [4]=1419, [406]=1442, [41]=1430, [493]=1450, [2597]=1459, [3277]=1460,
}

local rewardsOf = {}   -- quest id -> {item ids}
for id, it in pairs(items) do
  for _, q in ipairs(it[6] or {}) do rewardsOf[q] = rewardsOf[q] or {}; table.insert(rewardsOf[q], id) end
end
for _, list in pairs(rewardsOf) do table.sort(list) end

local HORDE, ALLIANCE = 178, 77
local function factionOf(mask)
  if not mask or mask == 0 or mask == 255 then return nil end
  local h, a = bit.band(mask, HORDE) ~= 0, bit.band(mask, ALLIANCE) ~= 0
  if h and not a then return "H" elseif a and not h then return "A" end
  return nil
end

-- first spawn of an NPC or object on a mapped world zone: {uiMap, x, y, name}
local function where(entry)
  if not entry then return nil end
  for _, n in ipairs(entry[1] or {}) do
    local d = npcs[n]
    if d and d[7] then
      for zone, list in pairs(d[7]) do
        if ZONE[zone] and list[1] and list[1][1] > 0 then return { ZONE[zone], list[1][1], list[1][2], d[1] } end
      end
    end
    if d then return { 0, 0, 0, d[1] } end
  end
  for _, o in ipairs(entry[2] or {}) do
    local d = objects[o]
    if d and d[4] then
      for zone, list in pairs(d[4]) do
        if ZONE[zone] and list[1] and list[1][1] > 0 then return { ZONE[zone], list[1][1], list[1][2], d[1] } end
      end
    end
    if d then return { 0, 0, 0, d[1] } end
  end
  for _, i in ipairs(entry[3] or {}) do
    local d = items[i]
    if d then return { 0, 0, 0, d[1] .. " (item)" } end
  end
  return nil
end

-- ---------------------------------------------------------------- assemble
local out = {}
local byArea = {}
for key, inst in pairs(dataObj) do
  if type(inst) == "table" and inst.items and inst.MapID then
    local d = { key = key, area = inst.MapID, raid = (inst.ContentType ~= "Dungeons"), bosses = {}, wing = inst.name }
    local lr = inst.LevelRange
    if type(lr) == "table" then d.levels = { lr[1], lr[2], lr[3] } end
    for _, boss in ipairs(inst.items) do
      local b = { name = boss.name, npc = boss.npcID, level = boss.Level, rare = boss.specialType == "rare" or nil, items = {} }
      if type(b.npc) == "table" then b.npc = b.npc[1] end
      if type(b.level) == "table" then b.level = b.level[1] end
      if type(b.level) ~= "number" then b.level = nil end
      if type(b.name) ~= "string" then b.name = tostring(b.name or "?") end
      local seen = {}
      for token, list in pairs(boss) do
        if type(token) == "number" and type(list) == "table" and DIFF[token] then
          local kind = DIFF[token]
          for _, e in ipairs(list) do
            local id = type(e) == "table" and e[2]
            if type(id) == "number" and id > 0 and not seen[id] then
              seen[id] = true
              local entry = { id }
              if kind == "horde" or kind == "alliance" then entry[2] = kind:sub(1, 1):upper() end
              table.insert(b.items, entry)
            end
          end
        end
      end
      if #b.items > 0 or b.npc then table.insert(d.bosses, b) end
    end
    local q = dungeons[inst.MapID]
    if q then
      d.name = (type(d.wing) == "string" and d.wing) or q[1]
      d.entrances = {}
      for _, e in ipairs(q[4] or {}) do
        if ZONE[e[1]] then table.insert(d.entrances, { ZONE[e[1]], e[2], e[3] }) end
      end
      d.altAreas = q[2]
    else
      d.name = key:gsub("(%l)(%u)", "%1 %2")
    end
    d.wing = nil
    table.insert(out, d)
    byArea[inst.MapID] = byArea[inst.MapID] or d
    for _, a in ipairs(d.altAreas or {}) do byArea[a] = byArea[a] or d end
  end
end

-- quests: Questie zoneOrSort (17) is the dungeon's area id (or one of its alternative ids)
local qCount = 0
-- a quest belongs to a dungeon when Questie files it there, or when its kill / loot / object
-- objectives spawn inside (Questie files some dungeon quests under the outdoor zone)
local function objectiveDungeon(q)
  local o = q[10]
  if not o then return nil end
  -- only things that exist inside a dungeon and nowhere else count
  local function inZones(sp)
    local found
    for zone in pairs(sp or {}) do
      if not byArea[zone] then return nil end
      found = found or byArea[zone]
    end
    return found
  end
  for _, c in ipairs(o[1] or {}) do local n = npcs[c[1]]; local d = n and inZones(n[7]); if d then return d end end
  for _, c in ipairs(o[2] or {}) do local ob = objects[c[1]]; local d = ob and inZones(ob[4]); if d then return d end end
  for _, c in ipairs(o[3] or {}) do
    local it = items[c[1]]
    if it and #(it[2] or {}) + #(it[3] or {}) <= 6 then   -- widely dropped items are not dungeon items
      for _, n in ipairs(it[2] or {}) do local nd = npcs[n]; local d = nd and inZones(nd[7]); if d then return d end end
      for _, ob in ipairs(it[3] or {}) do local od = objects[ob]; local d = od and inZones(od[4]); if d then return d end end
    end
  end
  return nil
end
for id, q in pairs(quests) do
  local d = byArea[q[17] or -1] or objectiveDungeon(q)
  if d and q[1] then
    d.quests = d.quests or {}
    local g, r = where(q[2]), where(q[3])
    local entry = {
      id = id, name = q[1], lvl = q[5], req = q[4], fac = factionOf(q[6]),
      cls = (q[7] and q[7] ~= 0) and q[7] or nil,
      g = g, r = r,
      pre = q[13] or q[12],
      rew = rewardsOf[id],
      txt = q[8] and q[8][1] or nil,
    }
    table.insert(d.quests, entry)
    qCount = qCount + 1
  end
end
-- wings of one dungeon (Scarlet Monastery, Dire Maul, Blackrock Spire) share an area id: every wing
-- lists the dungeon's quests; raids without a level range are level 60
for _, d in ipairs(out) do
  local owner = byArea[d.area]
  if owner ~= d and owner.quests then d.quests = owner.quests end
  if not d.levels and d.raid then d.levels = { 60, 60, 60 } end
end
for _, d in ipairs(out) do
  if d.quests then table.sort(d.quests, function(a, b) if (a.lvl or 0) ~= (b.lvl or 0) then return (a.lvl or 0) < (b.lvl or 0) end return a.id < b.id end) end
end
-- WoW Forever instances (hand-curated)
if foreverFile then
  local extra = assert(dofile(foreverFile))
  local byKey = {}
  for _, d in ipairs(out) do byKey[d.key] = d end
  for _, d in ipairs(extra) do
    if d.patch then
      -- Forever-only loot in a classic instance: append items to the matching boss (by npc, else name)
      local inst = assert(byKey[d.patch], "forever patch: no instance " .. tostring(d.patch))
      for _, pb in ipairs(d.bosses or {}) do
        local target
        for _, b in ipairs(inst.bosses or {}) do
          if (pb.npc and b.npc == pb.npc) or (not pb.npc and b.name == pb.name) then target = b end
        end
        assert(target, "forever patch: no boss " .. tostring(pb.name or pb.npc) .. " in " .. d.patch)
        target.items = target.items or {}
        local have = {}
        for _, it in ipairs(target.items) do have[it[1]] = true end
        for _, it in ipairs(pb.items or {}) do
          if not have[it[1]] then table.insert(target.items, 1, it) end -- Forever drops first
        end
      end
    else
      d.forever = true
      d.bosses = d.bosses or {}
      table.insert(out, d)
    end
  end
end
for _, d in ipairs(out) do d.raid = d.raid and true or false end
table.sort(out, function(a, b)
  if a.raid ~= b.raid then return not a.raid end
  local la, lb = a.levels and a.levels[1] or 99, b.levels and b.levels[1] or 99
  if la ~= lb then return la < lb end
  return a.name < b.name
end)

-- ---------------------------------------------------------------- write Lua
local function ser(v, ind)
  local t = type(v)
  if t == "string" then return string.format("%q", v)
  elseif t == "number" then return (v == math.floor(v)) and string.format("%d", v) or string.format("%.1f", v)
  elseif t == "boolean" then return tostring(v)
  elseif t == "table" then
    local parts = {}
    local n = #v
    for i = 1, n do parts[#parts + 1] = ser(v[i]) end
    local keys = {}
    for k in pairs(v) do if not (type(k) == "number" and k >= 1 and k <= n and k == math.floor(k)) then keys[#keys + 1] = k end end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
      local ks = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k or ("[" .. ser(k) .. "]")
      parts[#parts + 1] = ks .. "=" .. ser(v[k])
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "nil"
end
local f = assert(io.open(outFile, "w"))
f:write("-- GENERATED by addon/tools/build_journal.lua. Do not edit by hand.\n")
f:write("-- Boss loot: AtlasLootClassic (GPL-2, github.com/Hoizame/AtlasLootClassic). Quests, entrances,\n")
f:write("-- NPC spots and quest rewards: Questie's Classic database. Classic Era data: WoW Forever changes\n")
f:write("-- some loot and quests; new Forever dungeons are not in these sources yet.\n")
f:write("-- dungeon = {key, name, area, raid, levels={min,rec,max}, entrances={{uiMap,x,y}}, bosses={{name,npc,level,items={{itemID[,faction]}}}},\n")
f:write("--            quests={{id,name,lvl,req,fac,cls,g={uiMap,x,y,npc},r=...,pre={ids},rew={itemIDs},txt}}}\n")
f:write("local _, ns = ...\n\nns.JournalData = {\n")
for _, d in ipairs(out) do
  d.altAreas = nil
  f:write("  " .. ser(d) .. ",\n")
end
f:write("}\n")
f:close()
local bosses, loot = 0, 0
for _, d in ipairs(out) do for _, b in ipairs(d.bosses) do bosses = bosses + 1; loot = loot + #b.items end end
io.write(string.format("%d instances, %d bosses, %d loot entries, %d quests -> %s\n", #out, bosses, loot, qCount, outFile))
