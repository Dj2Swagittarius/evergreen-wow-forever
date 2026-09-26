-- Resolves every quest step in Evergreen/Data.lua to Classic quest IDs using Questie's
-- database, and pulls exact giver / turn-in NPC (or object) spawn coordinates.
--
-- usage: luajit resolve_quests.lua <scratch dir with classicQuestDB.lua, classicNpcDB.lua, classicObjectDB.lua> <addon dir>
-- writes <addon dir>/QuestIDs.lua and prints a report.

local bit = require("bit")
local scratch, addonDir = arg[1], arg[2]
assert(scratch and addonDir, "usage: luajit resolve_quests.lua <scratch> <addonDir>")

-- ---------------------------------------------------------------- load Questie DBs
QuestieLoader = { ImportModule = function() return {} end }
local function loadDB(file, field)
  local env = setmetatable({ QuestieLoader = QuestieLoader }, { __index = _G })
  local chunk = assert(loadfile(scratch .. "/" .. file))
  setfenv(chunk, env)
  local ok, err = pcall(chunk)
  -- the file assigns QuestieDB.<field> = [[return {...}]] on a local table; we need that table.
  -- Simplest: re-read the string from the file directly.
  -- The DB is far too large for one Lua chunk (65536-constant limit), so load one entry per line.
  local src = assert(io.open(scratch .. "/" .. file)):read("*a")
  local body = src:match(field .. "%s*=%s*%[%[(.-)%]%]")
  assert(body, "could not find " .. field .. " in " .. file)
  local t, n = {}, 0
  for line in body:gmatch("[^\n]+") do
    local id, entry = line:match("^%[(%d+)%]%s*=%s*(%b{}),?%s*$")
    if id then
      local fn = loadstring("return " .. entry)
      if fn then t[tonumber(id)] = fn(); n = n + 1 end
    end
  end
  io.stderr:write(string.format("loaded %d entries from %s\n", n, file))
  return t
end
local quests  = loadDB("classicQuestDB.lua", "QuestieDB.questData")
local npcs    = loadDB("classicNpcDB.lua", "QuestieDB.npcData")
local objects = loadDB("classicObjectDB.lua", "QuestieDB.objectData")

-- ---------------------------------------------------------------- load our route data
local ns = {}
local dataChunk = assert(loadfile(addonDir .. "/Data.lua"))
dataChunk("Evergreen", ns)

-- Questie areaID -> uiMapID
local ZONE = {
  [85]=1420, [130]=1421, [17]=1413, [267]=1424, [331]=1440, [400]=1441, [33]=1434, [405]=1443, [45]=1417, [15]=1445,
  [3]=1418, [8]=1435, [440]=1446, [357]=1444, [47]=1425, [51]=1427, [490]=1449, [361]=1448, [46]=1428, [16]=1447,
  [28]=1422, [139]=1423, [618]=1452, [1377]=1451, [1497]=1458, [1637]=1454, [1638]=1456, [14]=1411, [215]=1412,
  [36]=1416, [1519]=1453, [1537]=1455, [1657]=1457,
}
local HORDE = 178

local function hordeOK(mask) return (not mask) or mask == 0 or mask == 255 or bit.band(mask, HORDE) ~= 0 end

-- name -> list of quest ids (Horde-available)
local byName = {}
for id, q in pairs(quests) do
  local name, races = q[1], q[6]
  if name and hordeOK(races) then
    byName[name] = byName[name] or {}
    table.insert(byName[name], id)
  end
end

-- order a same-name candidate set by chain links, then level, then id
local function orderChain(ids)
  local set = {}
  for _, id in ipairs(ids) do set[id] = true end
  local pred = {}
  for _, id in ipairs(ids) do
    local q = quests[id]
    local pre = q[13]
    if pre then for _, p in ipairs(pre) do if set[p] then pred[id] = p end end end
    local nxt = q[22]
    if nxt and set[nxt] and not pred[nxt] then pred[nxt] = id end
  end
  local ordered, placed = {}, {}
  local function chainDepth(id, depth)
    depth = depth or 0
    if depth > 20 or not pred[id] then return depth end
    return chainDepth(pred[id], depth + 1)
  end
  table.sort(ids, function(a, b)
    local da, db = chainDepth(a), chainDepth(b)
    if da ~= db then return da < db end
    local la, lb = quests[a][5] or 0, quests[b][5] or 0
    if la ~= lb then return la < lb end
    return a < b
  end)
  return ids
end

local function nearestSpawn(spawns, hx, hy, hmap)
  -- spawns: {[areaID] = {{x,y},...}}; prefer the hand-picked map, else any mapped zone
  local best, bestD, bestMap
  for area, list in pairs(spawns or {}) do
    local map = ZONE[area]
    if map then
      for _, p in ipairs(list) do
        local x, y = p[1], p[2]
        if x and y and x > 0 then
          local d
          if hmap and map == hmap and hx then d = math.sqrt((x - hx) ^ 2 + (y - hy) ^ 2)
          elseif hmap and map ~= hmap then d = 1000 + math.sqrt((x - 50) ^ 2 + (y - 50) ^ 2)
          else d = 500 end
          if not bestD or d < bestD then best, bestD, bestMap = { math.floor(x + 0.5), math.floor(y + 0.5) }, d, map end
        end
      end
    end
  end
  if best then return best[1], best[2], bestMap, bestD end
end

local function entityCoord(startTbl, hx, hy, hmap)
  -- startTbl = {creatures, objects, items}
  if not startTbl then return end
  local creatures, objs = startTbl[1], startTbl[2]
  if creatures and creatures[1] then
    local npc = npcs[creatures[1]]
    if npc then
      local x, y, map, d = nearestSpawn(npc[7], hx, hy, hmap)
      return x, y, map, npc[1], d
    end
  end
  if objs and objs[1] then
    local o = objects[objs[1]]
    if o then
      local x, y, map, d = nearestSpawn(o[4], hx, hy, hmap)
      return x, y, map, o[1], d
    end
  end
end

-- ---------------------------------------------------------------- resolve
local QUEST_IDS, META = {}, {}
local report = { missing = {}, ambiguous = {}, coordDiff = {}, resolved = 0, total = 0 }
local usedParts = {}

for _, b in ipairs(ns.BRACKETS) do
  for i, s in ipairs(b.steps) do
    if s.q then
      report.total = report.total + 1
      local part = s.p or 1
      local cands = byName[s.q]
      if not cands or #cands == 0 then
        table.insert(report.missing, b.id .. ":" .. i .. "  " .. s.q)
      else
        cands = orderChain(cands)
        usedParts[s.q] = math.max(usedParts[s.q] or 0, part)
        QUEST_IDS[s.q] = cands
        local id = cands[part]
        if not id then
          table.insert(report.missing, b.id .. ":" .. i .. "  " .. s.q .. " part " .. part .. " (only " .. #cands .. " candidates)")
        else
          report.resolved = report.resolved + 1
          local q = quests[id]
          local hmap = (s.g and s.g[4]) or b.map
          local gx, gy, gmap, gname, gd = entityCoord(q[2], s.g and s.g[1], s.g and s.g[2], hmap)
          local rmap = (s.r and s.r[4]) or ((s.g and s.g[4]) or b.map)
          local rx, ry, rmapDB, rname, rd = entityCoord(q[3], s.r and s.r[1] or (s.g and s.g[1]), s.r and s.r[2] or (s.g and s.g[2]), rmap)
          local m = { lvl = q[5], t = q[8] and q[8][1] or nil }
          if gx then m.g = { gx, gy, gmap, gname } end
          if rx then m.r = { rx, ry, rmapDB, rname } end
          -- objective area: centre of the objective creatures' / objects' spawns in the zone
          -- that holds most of them (item objectives have no spawn data here)
          local o = q[10]
          if o then
            local byMap = {}
            local function add(spawns)
              for area, list in pairs(spawns or {}) do
                local map = ZONE[area]
                if map then
                  byMap[map] = byMap[map] or { n = 0, sx = 0, sy = 0 }
                  for _, p in ipairs(list) do
                    if p[1] and p[1] > 0 then byMap[map].n = byMap[map].n + 1; byMap[map].sx = byMap[map].sx + p[1]; byMap[map].sy = byMap[map].sy + p[2] end
                  end
                end
              end
            end
            for _, c in ipairs(o[1] or {}) do local npc = npcs[c[1]]; if npc then add(npc[7]) end end
            for _, c in ipairs(o[2] or {}) do local ob = objects[c[1]]; if ob then add(ob[4]) end end
            local bestMap, bestN = nil, 0
            for map, acc in pairs(byMap) do if acc.n > bestN then bestMap, bestN = map, acc.n end end
            if bestMap then
              local acc = byMap[bestMap]
              m.o = { math.floor(acc.sx / acc.n + 0.5), math.floor(acc.sy / acc.n + 0.5), bestMap }
            end
          end
          META[id] = m
          if gx and gd and gd > 8 then
            table.insert(report.coordDiff, string.format("%s:%d  %s  giver %s hand %s,%s map %s -> db %d,%d map %d", b.id, i, s.q, gname or "?", tostring(s.g and s.g[1]), tostring(s.g and s.g[2]), tostring(hmap), gx, gy, gmap))
          end
        end
      end
    end
  end
end
for name, cands in pairs(QUEST_IDS) do
  if #cands > (usedParts[name] or 1) then
    local ids = {}
    for _, id in ipairs(cands) do table.insert(ids, id .. "(L" .. tostring(quests[id][5]) .. ")") end
    table.insert(report.ambiguous, name .. ": " .. table.concat(ids, ", ") .. "  used parts: " .. (usedParts[name] or 1))
  end
end

-- ---------------------------------------------------------------- write QuestIDs.lua
local out = {}
table.insert(out, "-- AUTO-GENERATED by tools/resolve_quests.lua from Questie's Classic database. Do not edit by hand.")
table.insert(out, "-- QUEST_IDS[name] = ordered list of Horde-available quest ids sharing that name (chain order).")
table.insert(out, "-- QUEST_META[id]  = { g = {x,y,uiMapID,'giver'}, r = {x,y,uiMapID,'turn-in'}, lvl = questLevel }")
table.insert(out, "local ADDON, ns = ...")
table.insert(out, "ns.QUEST_IDS = {")
local names = {}
for name in pairs(QUEST_IDS) do table.insert(names, name) end
table.sort(names)
for _, name in ipairs(names) do
  table.insert(out, string.format("  [%q] = {%s},", name, table.concat(QUEST_IDS[name], ",")))
end
table.insert(out, "}")
table.insert(out, "ns.QUEST_META = {")
local ids = {}
for id in pairs(META) do table.insert(ids, id) end
table.sort(ids)
local function coordStr(c) if not c then return "nil" end if c[4] then return string.format("{%d,%d,%d,%q}", c[1], c[2], c[3], c[4]) end return string.format("{%d,%d,%d}", c[1], c[2], c[3]) end
for _, id in ipairs(ids) do
  local m = META[id]
  table.insert(out, string.format("  [%d] = { lvl = %s, g = %s, r = %s, o = %s, t = %s },", id, tostring(m.lvl or "nil"), coordStr(m.g), coordStr(m.r), coordStr(m.o), m.t and string.format("%q", m.t) or "nil"))
end
table.insert(out, "}")
local f = assert(io.open(addonDir .. "/QuestIDs.lua", "w"))
f:write(table.concat(out, "\n"), "\n")
f:close()

-- ---------------------------------------------------------------- report
print(string.format("resolved %d / %d quest steps", report.resolved, report.total))
print("\n== MISSING (" .. #report.missing .. ") — name not in DB for Horde, or part beyond chain length")
for _, l in ipairs(report.missing) do print("  " .. l) end
print("\n== AMBIGUOUS (" .. #report.ambiguous .. ") — more same-name quests than parts used; verify order")
for _, l in ipairs(report.ambiguous) do print("  " .. l) end
print("\n== GIVER COORD DIFFS > 8 units (" .. #report.coordDiff .. ")")
for _, l in ipairs(report.coordDiff) do print("  " .. l) end
