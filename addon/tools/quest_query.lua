-- usage: luajit quest_query.lua <scratch dir> <pattern> [<pattern> ...]
-- prints Questie Classic quest entries whose name matches each Lua pattern (case-insensitive).
local bit = require("bit")
local scratch = arg[1]
local function loadDB(file, field)
  local src = assert(io.open(scratch .. "/" .. file)):read("*a")
  local body = src:match(field .. "%s*=%s*%[%[(.-)%]%]")
  local t = {}
  for line in body:gmatch("[^\n]+") do
    local id, entry = line:match("^%[(%d+)%]%s*=%s*(%b{}),?%s*$")
    if id then local fn = loadstring("return " .. entry); if fn then t[tonumber(id)] = fn() end end
  end
  return t
end
local quests = loadDB("classicQuestDB.lua", "QuestieDB.questData")
local npcs = loadDB("classicNpcDB.lua", "QuestieDB.npcData")
local objects = loadDB("classicObjectDB.lua", "QuestieDB.objectData")
local ZONE = { [85]=1420,[130]=1421,[17]=1413,[267]=1424,[331]=1440,[400]=1441,[33]=1434,[405]=1443,[45]=1417,[15]=1445,[3]=1418,[8]=1435,[440]=1446,[357]=1444,[47]=1425,[51]=1427,[490]=1449,[361]=1448,[46]=1428,[16]=1447,[28]=1422,[139]=1423,[618]=1452,[1377]=1451,[1497]=1458,[1637]=1454,[1638]=1456,[14]=1411,[215]=1412,[36]=1416 }
local function who(tbl)
  if not tbl then return "-" end
  local out = {}
  for _, id in ipairs(tbl[1] or {}) do local n = npcs[id]; local s = n and n[1] or ("npc" .. id)
    if n and n[7] then for area, list in pairs(n[7]) do local p = list[1]; if p then s = s .. string.format(" @%d,%d m%s", p[1], p[2], tostring(ZONE[area] or ("area" .. area))); break end end end
    table.insert(out, s) end
  for _, id in ipairs(tbl[2] or {}) do local o = objects[id]; local s = "obj:" .. (o and o[1] or id)
    if o and o[4] then for area, list in pairs(o[4]) do local p = list[1]; if p then s = s .. string.format(" @%d,%d m%s", p[1], p[2], tostring(ZONE[area] or ("area" .. area))); break end end end
    table.insert(out, s) end
  for _, id in ipairs(tbl[3] or {}) do table.insert(out, "item:" .. id) end
  return table.concat(out, "; ")
end
local function objs(q)
  local o = q[10]; if not o then return "-" end
  local out = {}
  for _, c in ipairs(o[1] or {}) do local n = npcs[c[1]]; table.insert(out, "kill " .. (n and n[1] or c[1])) end
  for _, c in ipairs(o[2] or {}) do local ob = objects[c[1]]; table.insert(out, "use " .. (ob and ob[1] or c[1])) end
  for _, c in ipairs(o[3] or {}) do table.insert(out, "item " .. c[1]) end
  return table.concat(out, ", ")
end
for a = 2, #arg do
  local pat = arg[a]:lower()
  local ids = {}
  local numeric = tonumber(pat)
  for id, q in pairs(quests) do if (numeric and id == numeric) or (not numeric and q[1] and q[1]:lower():find(pat)) then table.insert(ids, id) end end
  table.sort(ids)
  print("### " .. arg[a])
  for _, id in ipairs(ids) do
    local q = quests[id]
    print(string.format("[%d] %s  L%s req%s races=%s classes=%s pre=%s next=%s", id, q[1], tostring(q[5]), tostring(q[4]), tostring(q[6]), tostring(q[7]), q[13] and table.concat(q[13], "/") or "-", tostring(q[22])))
    print("    from: " .. who(q[2]) .. "   to: " .. who(q[3]))
    print("    obj: " .. objs(q))
    print("    txt: " .. ((q[8] and q[8][1]) or "-"))
  end
end
