-- Audit every Evergreen route against Questie's Classic database and write a markdown report.
--
-- usage: luajit audit_routes.lua <questie Database dir> <addon dir> <out.md> [fixes.lua]
--
-- Per quest step it checks: the quest exists for the route's faction; its prerequisites are done
-- earlier on the route (or at least appear on it); the giver / turn-in NPC named in the label is the
-- one Questie has, and the coordinates are within 3 map units of a real spawn; the level gate the
-- step sits behind is not below the quest's required level. Classic data: Forever-only quests are
-- reported as "not in Questie" (expected), and Forever may have moved things, so every finding is
-- a lead to check, not a verdict.

local qdir, addonDir, outFile, fixFile = arg[1], arg[2], arg[3], arg[4]
assert(outFile, "usage: luajit audit_routes.lua <questieDB> <addonDir> <out.md> [fixes.lua]")
local bit = require("bit")

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

local ZONE = {
  [85]=1420, [130]=1421, [17]=1413, [267]=1424, [331]=1440, [400]=1441, [33]=1434, [405]=1443, [45]=1417, [15]=1445,
  [3]=1418, [8]=1435, [440]=1446, [357]=1444, [47]=1425, [51]=1427, [490]=1449, [361]=1448, [46]=1428, [16]=1447,
  [28]=1422, [139]=1423, [618]=1452, [1377]=1451, [1497]=1458, [1637]=1454, [1638]=1456, [14]=1411, [215]=1412,
  [36]=1416, [1519]=1453, [1537]=1455, [1657]=1457, [12]=1429, [40]=1436, [44]=1433, [10]=1431, [38]=1432,
  [1]=1426, [11]=1437, [141]=1438, [148]=1439, [4]=1419, [406]=1442, [41]=1430, [493]=1450,
}
local FACTION_MASK = { Horde = 178, Alliance = 77 }
local CLASS_BIT = { WARRIOR=1, PALADIN=2, HUNTER=4, ROGUE=8, PRIEST=16, SHAMAN=64, MAGE=128, WARLOCK=256, DRUID=1024 }

-- name index
local byName = {}
for id, q in pairs(quests) do
  if q[1] then byName[q[1]] = byName[q[1]] or {}; table.insert(byName[q[1]], id) end
end

-- ---------------------------------------------------------------- load the addon's routes
local ns = {}
CopyTable = function(t) return t end
local toc = assert(io.open(addonDir .. "/Evergreen.toc")):read("*a")
local files = { "Data.lua" }
for file in toc:gmatch("(Routes_[%w_]+%.lua)") do files[#files + 1] = file end
files[#files + 1] = "QuestIDs.lua"
for _, f in ipairs(files) do assert(loadfile(addonDir .. "/" .. f))("Evergreen", ns) end

local function lower(s) return (s or ""):lower() end

local function spawnsOf(sp, want)
  local out = {}
  for zone, list in pairs(sp or {}) do
    local ui = ZONE[zone]
    if ui and (not want or ui == want) then for _, c in ipairs(list) do out[#out + 1] = { c[1], c[2], ui } end end
  end
  return out
end

-- starters / finishers as {name=, spawns=}
local function actors(entry)
  local out = {}
  if not entry then return out end
  for _, n in ipairs(entry[1] or {}) do local d = npcs[n]; if d then out[#out + 1] = { name = d[1], spawns = d[7], id = n } end end
  for _, o in ipairs(entry[2] or {}) do local d = objects[o]; if d then out[#out + 1] = { name = d[1], spawns = d[4], id = o, obj = true } end end
  return out
end

-- chain order for same-name quests: follow preQuestSingle links
local function chainOrder(ids)
  local set = {}
  for _, id in ipairs(ids) do set[id] = true end
  local depth = {}
  local function d(id, seen)
    if depth[id] then return depth[id] end
    seen = seen or {}
    if seen[id] then return 0 end
    seen[id] = true
    local q = quests[id]; local best = 0
    for _, p in ipairs((q and q[13]) or {}) do if set[p] then best = math.max(best, d(p, seen) + 1) end end
    for _, p in ipairs((q and q[12]) or {}) do if set[p] then best = math.max(best, d(p, seen) + 1) end end
    depth[id] = best
    return best
  end
  local sorted = {}
  for _, id in ipairs(ids) do sorted[#sorted + 1] = id end
  table.sort(sorted, function(a, b) local da, db = d(a), d(b); if da ~= db then return da < db end return a < b end)
  return sorted
end

local function resolve(step, faction)
  if step.id then return step.id, "id" end
  if faction == "Horde" and ns.QUEST_IDS[step.q] then return ns.QUEST_IDS[step.q][step.p or 1], "horde-table" end
  local cands = {}
  for _, id in ipairs(byName[step.q] or {}) do
    local q = quests[id]
    local races, classes = q[6], q[7]
    local okF = (not races) or races == 0 or bit.band(races, FACTION_MASK[faction]) ~= 0
    local okC = true
    if classes and classes ~= 0 and step.cls and type(step.cls) == "string" then okC = bit.band(classes, CLASS_BIT[step.cls] or 0) ~= 0 end
    if okF and okC then cands[#cands + 1] = id end
  end
  if #cands == 0 then return nil end
  cands = chainOrder(cands)
  return cands[step.p or 1] or cands[#cands], (#cands == 1) and "name1" or "name"
end

local function labelMatches(label, list)
  local l = lower(label)
  local STOP = { the = true, of = true, high = true, lord = true, lady = true, apothecary = true, deathguard = true, executor = true,
    sergeant = true, captain = true, commander = true, priestess = true, priest = true, master = true, elder = true, chief = true }
  for _, a in ipairs(list) do
    local n = lower(a.name)
    if n ~= "" and l:find(n, 1, true) then return a end
    -- any distinctive word of the NPC's name ("Bath'rah" for "Bath'rah the Windwatcher",
    -- "cauldron" for "Scourge Cauldron", "wanted" for "Wanted Poster: Deathclasp")
    for w in n:gmatch("[%w']+") do
      if #w >= 4 and not STOP[w] and l:find(w, 1, true) then return a end
    end
  end
  return nil
end

local function nearestSpawn(a, x, y, ui)
  local best, bd
  for _, s in ipairs(spawnsOf(a.spawns, ui)) do
    local d = math.sqrt((s[1] - x) ^ 2 + (s[2] - y) ^ 2)
    if not bd or d < bd then best, bd = s, d end
  end
  return best, bd
end

-- ---------------------------------------------------------------- audit
local report = {}
local fixes = {}
local totals = {}
local function add(route, kind, msg)
  report[route] = report[route] or {}
  table.insert(report[route], { kind = kind, msg = msg })
  totals[kind] = (totals[kind] or 0) + 1
end

local auditedBrackets = {}
for _, r in ipairs(ns.ROUTES) do
  if not r.optimized then
    local doneIds, seenIds = {}, {}
    local order = {}
    -- first pass: every resolved id on the route, in order
    for bi, b in ipairs(r.brackets) do
      for si, s in ipairs(b.steps) do
        if s.q then
          local id, how = resolve(s, r.faction)
          s._aid, s._how = id, how
          if id then order[#order + 1] = { id = id, b = b, s = s, pos = bi * 1000 + si } end
          if id then seenIds[id] = seenIds[id] or (bi * 1000 + si) end
        end
      end
    end
    for bi, b in ipairs(r.brackets) do
      local shared = auditedBrackets[b]   -- a shared bracket is audited once, under the first route
      auditedBrackets[b] = auditedBrackets[b] or r.id
      local gate = b.lv[1]
      for si, s in ipairs(b.steps) do
        if s.lv then gate = s.lv end
        if s.q and not shared then
          local where = string.format("`%s` %s: **%s**%s%s", b.id, b.name, s.q, s.p and (" (" .. s.p .. ")") or "", s.cls and (" [" .. (type(s.cls) == "string" and s.cls or "class") .. "]") or "")
          if s._how == "name" then where = where .. " _(several quests share this name; low confidence)_" end
          local id = s._aid
          local q = id and quests[id]
          local pos = bi * 1000 + si
          if not q then
            add(r.id, "not in Questie", where .. (id and (" (id " .. id .. ")") or "") .. " — Forever-only or misspelt")
          else
            -- level
            if q[4] and q[4] > gate and q[4] > b.lv[1] then
              add(r.id, "level", string.format("%s needs level %d but sits behind a level-%d gate", where, q[4], gate))
            end
            -- prerequisites
            local group = q[12] or {}
            for _, p in ipairs(group) do
              if not seenIds[p] then
                if quests[p] then add(r.id, "prerequisite missing", string.format("%s needs **%s** (%d), which is not on the route", where, quests[p][1] or "?", p)) end
              elseif seenIds[p] > pos then
                add(r.id, "prerequisite order", string.format("%s is listed before its prerequisite **%s**", where, quests[p][1] or "?"))
              end
            end
            local single = q[13] or {}
            if #single > 0 then
              local anyBefore, anyOn = false, false
              for _, p in ipairs(single) do
                if seenIds[p] then anyOn = true; if seenIds[p] < pos then anyBefore = true end end
              end
              if not anyOn then
                local names = {}
                for _, p in ipairs(single) do if quests[p] then names[#names + 1] = (quests[p][1] or "?") .. " (" .. p .. ")" end end
                add(r.id, "prerequisite missing", string.format("%s needs one of **%s**, none of which is on the route", where, table.concat(names, ", ")))
              elseif not anyBefore then
                add(r.id, "prerequisite order", string.format("%s is listed before its prerequisite **%s**", where, quests[single[1]] and quests[single[1]][1] or "?"))
              end
            end
            -- giver / turn-in
            for _, ph in ipairs({ { "g", q[2], "giver" }, { "r", q[3], "turn-in" } }) do
              local key, entry, what = ph[1], ph[2], ph[3]
              local c = s[key] or (key == "r" and s.g or nil)
              local list = actors(entry)
              if c and type(c) == "table" and #list > 0 then
                local x, y, label = c[1], c[2], c[3] or ""
                local ui = c[4] or b.map
                if x ~= 0 or y ~= 0 then
                  local a = labelMatches(label, list)
                  if not a then
                    -- is the label a different NPC than Questie's?
                    local names = {}
                    for _, l in ipairs(list) do names[#names + 1] = l.name end
                    if not lower(label):find("any ", 1, true) and not lower(label):find("trainer", 1, true) then
                      local sp = list[1] and nearestSpawn(list[1], x, y, ui)
                      add(r.id, what .. " NPC", string.format("%s: label \"%s\" but Questie's %s is **%s**%s", where, label, what, table.concat(names, " / "),
                        sp and string.format(" at %.1f, %.1f", sp[1], sp[2]) or ""))
                      local target = sp or (list[1] and spawnsOf(list[1].spawns)[1])
                      if target and s._how ~= "name" then
                        local extra = label:match(":%s*(.+)$")
                        local newLabel = list[1].name .. (extra and (": " .. extra) or "")
                        fixes[#fixes + 1] = { b = b.id, q = s.q, p = s.p, cls = s.cls, key = key, x = target[1], y = target[2], map = target[3], label = newLabel, ox = x, oy = y, why = "npc", was = label }
                      end
                    end
                  else
                    local sp, d = nearestSpawn(a, x, y, ui)
                    if sp and d > 3 then
                      add(r.id, what .. " coords", string.format("%s: %s at %d,%d but Questie has %.1f, %.1f (%.0f units off)", where, a.name, x, y, sp[1], sp[2], d))
                      if s._how ~= "name" then
                        fixes[#fixes + 1] = { b = b.id, q = s.q, p = s.p, cls = s.cls, key = key, x = sp[1], y = sp[2], map = ui, label = label, ox = x, oy = y, why = "coords" }
                      end
                    elseif not sp and (a.spawns and next(a.spawns)) then
                      local zones = {}
                      for z in pairs(a.spawns) do zones[#zones + 1] = tostring(ZONE[z] or z) end
                      add(r.id, what .. " coords", string.format("%s: %s is on map %s per Questie, route says map %d", where, a.name, table.concat(zones, "/"), ui))
                      local any = spawnsOf(a.spawns)[1]
                      if any and s._how ~= "name" then
                        fixes[#fixes + 1] = { b = b.id, q = s.q, p = s.p, cls = s.cls, key = key, x = any[1], y = any[2], map = any[3], label = label, ox = x, oy = y, why = "map" }
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

-- ---------------------------------------------------------------- write
local f = assert(io.open(outFile, "w"))
f:write("# Evergreen route audit against Questie (Classic data)\n\n")
f:write("Generated by `addon/tools/audit_routes.lua`. Classic data: Forever may have moved NPCs or changed quests, so each line is a lead to verify, not a verdict. Shared brackets are listed once, under the first route that uses them.\n\n")
f:write("| Finding | Count |\n|---|---|\n")
local kinds = {}
for k in pairs(totals) do kinds[#kinds + 1] = k end
table.sort(kinds)
for _, k in ipairs(kinds) do f:write("| " .. k .. " | " .. totals[k] .. " |\n") end
for _, r in ipairs(ns.ROUTES) do
  local list = report[r.id]
  if list then
    f:write("\n## " .. r.name .. " (`" .. r.id .. "`)\n")
    table.sort(list, function(a, b) if a.kind ~= b.kind then return a.kind < b.kind end return false end)
    local cur
    for _, e in ipairs(list) do
      if e.kind ~= cur then f:write("\n### " .. e.kind .. "\n\n"); cur = e.kind end
      f:write("- " .. e.msg .. "\n")
    end
  end
end
f:close()
if fixFile then
  local g = assert(io.open(fixFile, "w"))
  g:write("-- GENERATED by addon/tools/audit_routes.lua: giver / turn-in corrections from Questie's Classic\n")
  g:write("-- database, applied on top of the hand routes at load time. Only steps whose quest id is certain\n")
  g:write("-- are touched, and each fix checks the step still has the coordinates it was made for, so a hand\n")
  g:write("-- edit wins. Delete this file (and its TOC line) to go back to the hand data. why: coords = same\n")
  g:write("-- NPC, better spot; map = NPC is on another map; npc = the route named the wrong NPC.\n")
  g:write("local ADDON, ns = ...\n\nlocal FIXES = {\n")
  local seen = {}
  for _, x in ipairs(fixes) do
    local k = x.b .. x.q .. tostring(x.p) .. tostring(x.cls) .. x.key
    if not seen[k] then
      seen[k] = true
      local cls = x.cls and (type(x.cls) == "string" and string.format("%q", x.cls) or "true") or "nil"
      g:write(string.format("  {b=%q, q=%q, p=%s, cls=%s, key=%q, to={%.1f, %.1f, %q, %d}, from={%s, %s}, why=%q%s},\n",
        x.b, x.q, tostring(x.p or 1), cls, x.key, x.x, x.y, x.label, x.map, tostring(x.ox), tostring(x.oy), x.why,
        x.was and string.format(", was=%q", x.was) or ""))
    end
  end
  g:write("}\n\n")
  g:write([[
local brackets = {}
for _, r in ipairs(ns.ROUTES) do
  for _, b in ipairs(r.brackets) do brackets[b.id] = brackets[b.id] or b end
end
local applied = 0
for _, f in ipairs(FIXES) do
  local b = brackets[f.b]
  if b then
    for _, s in ipairs(b.steps) do
      local cls = s.cls
      local clsOK = (f.cls == nil and cls == nil) or (f.cls == true and type(cls) == "table") or (f.cls == cls)
      if s.q == f.q and (s.p or 1) == f.p and clsOK then
        local c = s[f.key] or (f.key == "r" and s.g) or nil
        if c and c[1] == f.from[1] and c[2] == f.from[2] then
          s[f.key] = f.to
          applied = applied + 1
        end
      end
    end
  end
end
ns.QUESTIE_FIXES_APPLIED = applied
]])
  g:close()
end
for _, k in ipairs(kinds) do io.write(k, ": ", totals[k], "\n") end
