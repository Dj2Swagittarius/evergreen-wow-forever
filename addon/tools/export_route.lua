-- Export one Evergreen route's brackets plus the Questie facts the optimizer needs, as JSON.
--
-- usage: luajit export_route.lua <questie Database dir> <addon dir> <route id> <first bracket> <last bracket> <out.json>
-- Questie's Classic DBs ship inside the Questie addon (Database/Classic/*.lua, Database/QuestXP/DB/xpDB-classic.lua).

local qdir, addonDir, routeId, b1, b2, outFile = arg[1], arg[2], arg[3], tonumber(arg[4]), tonumber(arg[5]), arg[6]
assert(outFile, "usage: luajit export_route.lua <questieDB> <addonDir> <route> <b1> <b2> <out.json>")

-- ---------------------------------------------------------------- Questie loaders (one entry per line)
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
local xp = {}
do
  local src = assert(io.open(qdir .. "/QuestXP/DB/xpDB-classic.lua")):read("*a")
  for id, lvl, amount in src:gmatch("%[(%d+)%]%s*=%s*{(%d+),%s*(%d+)}") do xp[tonumber(id)] = { tonumber(lvl), tonumber(amount) } end
end

-- Questie AreaID -> uiMapID
local ZONE = {
  [85]=1420, [130]=1421, [17]=1413, [267]=1424, [331]=1440, [400]=1441, [33]=1434, [405]=1443, [45]=1417, [15]=1445,
  [3]=1418, [8]=1435, [440]=1446, [357]=1444, [47]=1425, [51]=1427, [490]=1449, [361]=1448, [46]=1428, [16]=1447,
  [28]=1422, [139]=1423, [618]=1452, [1377]=1451, [1497]=1458, [1637]=1454, [1638]=1456, [14]=1411, [215]=1412,
  [36]=1416, [1519]=1453, [1537]=1455, [1657]=1457,
}
local function spawnsOf(sp, out)
  for zone, list in pairs(sp or {}) do
    local ui = ZONE[zone]
    if ui then for _, c in ipairs(list) do if c[1] and c[1] > 0 then out[#out + 1] = { c[1], c[2], ui } end end end
  end
  return out
end
local function npcSpawns(id, out) local n = npcs[id]; if n then spawnsOf(n[7], out) end; return out end
local function objSpawns(id, out) local o = objects[id]; if o then spawnsOf(o[4], out) end; return out end

-- ---------------------------------------------------------------- the route
local ns = {}
CopyTable = function(t) return t end
local toc = assert(io.open(addonDir .. "/Evergreen_Guide.toc")):read("*a")
for file in toc:gmatch("\n(Routes_[%w_]+%.lua)") do end
local files = { "Data.lua" }
for file in toc:gmatch("(Routes_[%w_]+%.lua)") do if not file:match("_Opt%.lua$") then files[#files + 1] = file end end
files[#files + 1] = "QuestIDs.lua"
for _, f in ipairs(files) do assert(loadfile(addonDir .. "/" .. f))("Evergreen", ns) end
local route
for _, r in ipairs(ns.ROUTES) do if r.id == routeId then route = r end end
assert(route, "no route " .. routeId)

local function qidOf(step)
  if step.id then return step.id end
  local ids = ns.QUEST_IDS[step.q]
  return ids and ids[step.p or 1] or nil
end

local function questFacts(id)
  local q = quests[id]
  if not q then return nil end
  local f = { name = q[1], reqLevel = q[4], level = q[5], pre = {}, starts = {}, ends = {}, obj = {} }
  for _, p in ipairs(q[13] or {}) do f.pre[#f.pre + 1] = p end   -- preQuestSingle: any one of
  f.preAll = q[12]                                               -- preQuestGroup: all of
  if q[2] then
    for _, n in ipairs(q[2][1] or {}) do npcSpawns(n, f.starts) end
    for _, o in ipairs(q[2][2] or {}) do objSpawns(o, f.starts) end
  end
  if q[3] then
    for _, n in ipairs(q[3][1] or {}) do npcSpawns(n, f.ends) end
    for _, o in ipairs(q[3][2] or {}) do objSpawns(o, f.ends) end
  end
  f.objText = q[8] and table.concat(q[8], " ") or nil
  local lv, ln = 0, 0
  local function mob(id) local n = npcs[id]; if n and n[4] then lv = lv + (n[4] + (n[5] or n[4])) / 2; ln = ln + 1 end end
  local o = q[10]
  if o then
    for _, c in ipairs(o[1] or {}) do mob(c[1]) end
    for _, c in ipairs(o[3] or {}) do local it = items[c[1]]; if it then for _, n in ipairs(it[2] or {}) do mob(n) end end end
  end
  if ln > 0 then f.mobLevel = lv / ln end
  f.kills = (o and ((o[1] and #o[1] > 0) or (o[3] and #o[3] > 0))) and true or false
  if o then
    for _, c in ipairs(o[1] or {}) do npcSpawns(c[1], f.obj) end
    for _, c in ipairs(o[2] or {}) do objSpawns(c[1], f.obj) end
    for _, c in ipairs(o[3] or {}) do
      local it = items[c[1]]
      if it then
        for _, n in ipairs(it[2] or {}) do npcSpawns(n, f.obj) end
        for _, ob in ipairs(it[3] or {}) do objSpawns(ob, f.obj) end
      end
    end
    for _, kc in ipairs(o[5] or {}) do for _, n in ipairs(kc[1] or {}) do npcSpawns(n, f.obj) end end
  end
  if q[9] and q[9][2] then spawnsOf(q[9][2], f.obj) end   -- triggerEnd (explore) areas
  f.xp = xp[id] and xp[id][2] or nil
  return f
end

-- ---------------------------------------------------------------- JSON
local function enc(v)
  local t = type(v)
  if t == "nil" then return "null"
  elseif t == "boolean" or t == "number" then return tostring(v)
  elseif t == "string" then return '"' .. v:gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"'
  elseif t == "table" then
    if #v > 0 or next(v) == nil then
      local parts = {}
      for i = 1, #v do parts[i] = enc(v[i]) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local parts = {}
    for k, val in pairs(v) do if type(k) ~= "function" then parts[#parts + 1] = enc(tostring(k)) .. ":" .. enc(val) end end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "null"
end

local out = { route = routeId, brackets = {}, facts = {} }
for bi = b1, b2 do
  local b = route.brackets[bi]
  local ob = { id = b.id, lv = b.lv, name = b.name, map = b.map, hub = b.hub, hearth = b.hearth, fp = b.fp, steps = {} }
  for _, s in ipairs(b.steps) do
    local c = {}
    for k, v in pairs(s) do if type(v) ~= "function" then c[k] = v end end
    if s.q then
      c.qid = qidOf(s)
      if c.qid and not out.facts[tostring(c.qid)] then out.facts[tostring(c.qid)] = questFacts(c.qid) or false end
    end
    ob.steps[#ob.steps + 1] = c
  end
  out.brackets[#out.brackets + 1] = ob
end
local f = assert(io.open(outFile, "w")); f:write(enc(out)); f:close()
io.stderr:write("wrote " .. outFile .. "\n")
