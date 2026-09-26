-- Headless test: loads the whole Evergreen addon (TOC order) against stubbed WoW APIs, then a bot
-- "plays" a route: it does whatever the current step says (accept, do objectives, turn in, travel,
-- bind, level up) and checks the guide advances. Catches runtime errors in Core.lua and steps
-- the engine can never complete (the bot gets stuck).
--
-- usage: luajit test_harness.lua <addon dir> <race file name> <class> [route id] [max levels]
-- e.g.   luajit test_harness.lua ../Evergreen Scourge PALADIN forsaken-opt 18

local addonDir, RACE, CLASS, ROUTE_ID, MAXLV = arg[1], arg[2] or "Scourge", arg[3] or "WARRIOR", arg[4], tonumber(arg[5] or "18")
assert(addonDir, "usage: luajit test_harness.lua <addonDir> <race> <class> [route] [maxLevel]")

-- ---------------------------------------------------------------- stub world
local timers = {}
local printed = {}
local frames = {}
local CHILD_KEYS = { NineSlice = true, PortraitContainer = true, portrait = true, Inset = true, Bg = true, CloseButton = true,
  Text = true, Instructions = true, searchIcon = true, Left = true, LeftActive = true, LeftTexture = true, TitleContainer = true,
  TitleText = true, Tabs = true, numTabs = true, skinned = true, fallbackTitle = true, contentTop = true, portraitW = true, locked = true }
local function newFrame(name)
  local f = { _scripts = {}, _events = {}, _shown = true, _name = name or false }
  setmetatable(f, { __index = function(t, k)
    -- template children (parentKey frames) do not exist on stub frames: the addon must fall back
    if CHILD_KEYS[k] then return nil end
    if k == "SetScript" then return function(self, ev, fn) self._scripts[ev] = fn end end
    if k == "GetScript" then return function(self, ev) return self._scripts[ev] end end
    if k == "HookScript" then return function(self, ev, fn) local o = self._scripts[ev]; self._scripts[ev] = function(...) if o then o(...) end fn(...) end end end
    if k == "RegisterEvent" then return function(self, ev) self._events[ev] = true end end
    if k == "UnregisterEvent" then return function(self, ev) self._events[ev] = nil end end
    if k == "UnregisterAllEvents" then return function(self) self._events = {} end end
    if k == "Show" then return function(self) self._shown = true end end
    if k == "Hide" then return function(self) self._shown = false end end
    if k == "IsShown" or k == "IsVisible" then return function(self) return self._shown end end
    if k == "SetText" then return function(self, s) self._text = s end end
    if k == "GetText" then return function(self) return self._text or "" end end
    if k == "GetPoint" then return function() return "CENTER", nil, "CENTER", 0, 0 end end
    if k == "GetCenter" then return function() return 0, 0 end end
    if k == "GetName" then return function(self) return self._name or nil end end
    if k == "GetObjectType" then return function() return "Frame" end end
    if k == "GetEffectiveScale" or k == "GetScale" then return function() return 1 end end
    if k:match("^Create") then return function(self, n) return newFrame(n) end end
    if k:match("^Get") then return function() return 0 end end
    if k:match("^Is") or k:match("^Has") or k:match("^Can") then return function() return false end end
    return function() end
  end })
  frames[#frames + 1] = f
  if name then _G[name] = f end
  return f
end
CreateFrame = function(_, name) return newFrame(name) end
UIParent, Minimap, WorldFrame, GameTooltip = newFrame("UIParent"), newFrame("Minimap"), newFrame("WorldFrame"), newFrame("GameTooltip")
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) printed[#printed + 1] = m end }
print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end printed[#printed + 1] = table.concat(t, " ") end
hooksecurefunc = function() end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
CopyTable = function(t) local c = {} for k, v in pairs(t) do c[k] = type(v) == "table" and CopyTable(v) or v end return c end
tinsert, tremove, format, strlower, strupper = table.insert, table.remove, string.format, string.lower, string.upper
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
strsplit = function(sep, s) local t = {} for p in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do t[#t + 1] = p end return unpack(t) end
Mixin = function(o, ...) for i = 1, select("#", ...) do for k, v in pairs(select(i, ...)) do o[k] = v end end return o end
CreateVector2D = function(x, y) return { x = x, y = y, GetXY = function(s) return s.x, s.y end } end
GetTime = function() return os.clock() end
GetBuildInfo = function() return "1.60.1", "69893", "Sep 2026", 16001 end
IsShiftKeyDown = function() return false end
GetCursorPosition = function() return 0, 0 end
GetPlayerFacing = function() return 0 end
IsSpellKnown, IsPlayerSpell = function() return false end, function() return false end
GetSpellCooldown = function() return 0, 0 end
SlashCmdList = {}
UISpecialFrames = {}
STANDARD_TEXT_FONT = "Fonts/FRIZQT__.TTF"
RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { r = 1, g = 1, b = 1, colorStr = "ffffffff" } end })
C_Timer = {
  After = function(d, f) timers[#timers + 1] = f end,
  NewTimer = function(d, f) timers[#timers + 1] = f; return { Cancel = function() end } end,
  NewTicker = function() return { Cancel = function() end } end,
}
local function flush() for _ = 1, 5 do local t = timers; timers = {}; for _, f in ipairs(t) do f() end end end

-- player & quest state the bot drives
local state = { level = 1, map = nil, x = 0.5, y = 0.5, log = {}, done = {}, bind = "Deathknell" }
local RACE_NAME = { Scourge = "Undead", NightElf = "Night Elf" }
UnitRace = function() return RACE_NAME[RACE] or RACE, RACE end
UnitClass = function() return CLASS:sub(1, 1) .. CLASS:sub(2):lower(), CLASS end
UnitFactionGroup = function() return os.getenv("FACTION") or ((RACE == "Human" or RACE == "Dwarf" or RACE == "Gnome" or RACE == "NightElf") and "Alliance" or "Horde") end
UnitLevel = function() return state.level end
UnitName = function() return "Tester" end
UnitExists = function(u) return u == "player" end
UnitIsConnected, UnitIsVisible, UnitIsFriend, UnitIsPlayer = function() return true end, function() return true end, function() return true end, function() return true end
UnitIsDeadOrGhost, UnitCanAssist = function() return false end, function() return true end
UnitInRange = function() return true end
IsInRaid, IsInGroup = function() return false end, function() return false end
UnitAura, UnitBuff = function() return nil end, function() return nil end
GetCVar, SetCVar = function() return "1" end, function() end
C_UnitAuras = { GetAuraDataByIndex = function() return nil end }
IsSpellInRange = function() return 1 end
GetBindLocation = function() return state.bind end
C_QuestLog = {
  GetNumQuestLogEntries = function() return #state.log end,
  GetInfo = function(i) local q = state.log[i]; return q and { title = q.title, questID = q.id, isHeader = false } end,
  IsComplete = function(id) for _, q in ipairs(state.log) do if q.id == id then return q.complete end end return false end,
  IsQuestFlaggedCompleted = function(id) return state.done[id] or false end,
  GetAllCompletedQuestIDs = function() local t = {} for id in pairs(state.done) do t[#t + 1] = id end return t end,
  GetTitleForQuestID = function() return nil end,
  GetQuestInfo = function() return nil end,
}
C_Map = {
  GetBestMapForUnit = function() return state.map end,
  GetPlayerMapPosition = function() return CreateVector2D(state.x, state.y) end,
  GetMapInfo = function(id) return { mapID = id, name = "map" .. tostring(id), parentMapID = 0 } end,
  GetWorldPosFromMapPos = function(map, v) return 0, CreateVector2D(v.x * 1000, v.y * 1000) end,
  GetMapWorldSize = function() return 1000, 1000 end,
  CanSetUserWaypointOnMap = function() return true end,
  SetUserWaypoint = function() end, ClearUserWaypoint = function() end,
}
C_SuperTrack = { SetSuperTrackedUserWaypoint = function() end }
UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { m = m, x = x, y = y } end }
C_Spell = { GetSpellCooldown = function() return nil end }
setmetatable(_G, { __index = function(_, k)
  -- any other unit / state query answers "no" (enough for modules that only read them)
  if type(k) == "string" and (k:match("^Unit%u") or k:match("^Is%u") or k:match("^Get%u")) then return function() return nil end end
  return nil
end })

-- ---------------------------------------------------------------- load the addon
local ns = {}
local toc = assert(io.open(addonDir .. "/Evergreen.toc")):read("*a")
for line in toc:gmatch("[^\r\n]+") do
  if line:match("%.lua$") and not line:match("^#") then
    local path = addonDir .. "/" .. line:gsub("\\", "/")
    local chunk, err = loadfile(path)
    assert(chunk, err)
    local ok, e = pcall(chunk, "Evergreen", ns)
    if not ok then error("loading " .. line .. ": " .. tostring(e)) end
  end
end
local function fire(ev, ...)
  for _, f in ipairs(frames) do
    if f._events[ev] and f._scripts.OnEvent then
      local ok, e = pcall(f._scripts.OnEvent, f, ev, ...)
      if not ok then error("event " .. ev .. ": " .. tostring(e)) end
    end
  end
  flush()
end
EvergreenDB = { modules = { buffs = (os.getenv("BUFFS") ~= nil), move = false, reveal = false } }  -- guide (+ journal) only
bit = require("bit")
WorldMapFrame = newFrame("WorldMapFrame")
InCombatLockdown = function() return false end
fire("ADDON_LOADED", "Evergreen")
fire("PLAYER_LOGIN")
fire("PLAYER_ENTERING_WORLD")
if ROUTE_ID then SlashCmdList.EVERGREEN("route " .. ROUTE_ID) end
local UI = ns.UI

-- JOURNAL=1: exercise the Dungeon Journal module instead of playing a route
if os.getenv("JOURNAL") then
  local J = assert(ns.Journal, "journal module not loaded")
  SlashCmdList.EVERGREENJOURNAL("")
  assert(J.frame and J.frame._shown, "journal did not open")
  local n = 0
  for _, d in ipairs(ns.JournalData) do
    for _, tab in ipairs({ "Loot", "Quests" }) do
      J.tab = tab
      J.Select(d)
      n = n + 1
    end
  end
  SlashCmdList.EVERGREENJOURNAL("dead")
  assert(J.current and J.current.name == "The Deadmines", "search did not open The Deadmines")
  J.entranceBtn._scripts.OnClick(J.entranceBtn)
  -- world map pins on a stub map showing Westfall
  WorldMapFrame._shown = true
  WorldMapFrame.GetMapID = function() return 1436 end
  WorldMapFrame.ScrollContainer = { Child = CreateFrame("Frame"), GetCanvasScale = function() return 1 end }
  WorldMapFrame.ScrollContainer.Child.GetSize = function() return 1000, 667 end
  J.RefreshPins()
  SlashCmdList.EVERGREENJOURNAL("pins"); SlashCmdList.EVERGREENJOURNAL("pins")
  SlashCmdList.EVERGREENJOURNAL("clear")
  io.write(string.format("OK journal: %d instance/tab views drawn, %d chat lines\n", n, #printed))
  for _, m in ipairs(printed) do io.write("  chat: ", m, "\n") end
  os.exit(0)
end

-- ---------------------------------------------------------------- the bot
local fakeId = 900000
local ids = {}
local function questId(step)
  if step.qid then return step.qid end
  local k = step.q .. "#" .. (step.p or 1)
  if not ids[k] then fakeId = fakeId + 1; ids[k] = fakeId end
  return ids[k]
end
local function inLog(id) for i, q in ipairs(state.log) do if q.id == id then return i, q end end end

local steps, stuck, last = 0, 0, nil
local levelGates = {}
while steps < 3000 do
  UI.Refresh(); flush()
  local s = UI.currentStep
  if not s then
    if state.level >= MAXLV then break end
    state.level = state.level + 1                -- bracket done: next bracket by level
    fire("PLAYER_LEVEL_UP", state.level)
  else
    local desc = (s.act or "") .. " " .. (s.q or s.bind or s.fp or s.man or s.t or (s.lv and ("lv " .. s.lv)) or "?")
    if last == s then stuck = stuck + 1 else stuck = 0 end
    if stuck >= 3 then
      io.write("STUCK at ", s.key or "?", ": ", desc, "\n")
      os.exit(1)
    end
    last = s
    steps = steps + 1
    if os.getenv("TRACE") then io.write(string.format("%4d %-10s %-6s %-40s phase=%s onQuest=%s qid=%s\n", steps, s.key or "?", s.act or "", desc:sub(1, 40), tostring(s.phase), tostring(s.onQuest), tostring(s.qid))) end
    if s.q then
      local id = questId(s)
      local i, q = inLog(id)
      if state.done[id] then
        io.write("WARN guide points at a turned-in quest: ", desc, "\n")
        stuck = 5
      elseif not q then
        table.insert(state.log, { title = s.q, id = id, complete = false }); fire("QUEST_ACCEPTED", #state.log, id)
      elseif not q.complete and s.act ~= "accept" then
        q.complete = true; fire("QUEST_LOG_UPDATE")
      elseif q.complete and (s.act == nil or s.act == "turnin") then
        table.remove(state.log, i); state.done[id] = true; fire("QUEST_TURNED_IN", id)
      end
    elseif s.lv then
      state.level = s.lv; levelGates[#levelGates + 1] = s.lv; fire("PLAYER_LEVEL_UP", s.lv)
      if s.lv >= MAXLV then break end
    elseif s.bind then
      state.bind = s.bind; fire("HEARTHSTONE_BOUND")
    elseif s.tr then
      state.map = s.map or state.map; state.x, state.y = (s.x or 50) / 100, (s.y or 50) / 100; fire("ZONE_CHANGED")
      if not s.done then SlashCmdList.EVERGREEN("") end
      -- travel steps complete by position; the bot marks them by hand if the stub map math cannot
      ns.FR._scripts.OnEvent(ns.FR, "ZONE_CHANGED_NEW_AREA")
    end
    if (s.fp or s.man or s.tr) and last == s then
      -- manual / flight-point / travel steps: right-click equivalent
      EvergreenCharDB.manual[s.key] = true
    end
  end
end
io.write(string.format("OK %s %s route=%s: %d guide steps followed, reached level %d, %d quests turned in, %d chat lines\n",
  RACE, CLASS, ROUTE_ID or "auto", steps, state.level, (function() local n = 0 for _ in pairs(state.done) do n = n + 1 end return n end)(), #printed))
for _, m in ipairs(printed) do if m:lower():find("error") then io.write("  chat: ", m, "\n") end end

-- quests on the active route (this class) that were never turned in
if os.getenv("MISSED") then
  local seen = {}
  for bi = 1, 3 do
    local b = ns.ROUTES and nil
  end
  for _, r in ipairs(ns.ROUTES) do
    if r.id == (ROUTE_ID or "") then
      for bi, b in ipairs(r.brackets) do
        if b.lv[1] < MAXLV then
          for _, s in ipairs(b.steps) do
            local okc = (not s.cls) or s.cls == CLASS or (type(s.cls) == "table" and s.cls[CLASS])
            local okr = (not s.race) or s.race == RACE or (type(s.race) == "table" and s.race[RACE])
            if s.q and okc and okr and not seen[s.q .. (s.p or 1)] then
              seen[s.q .. (s.p or 1)] = true
              local id = s.id or (ns.QUEST_IDS[s.q] and ns.QUEST_IDS[s.q][s.p or 1]) or ids[s.q .. "#" .. (s.p or 1)]
              if not (id and state.done[id]) then io.write("  missed: ", b.id, " ", s.q, " p", s.p or 1, s.opt and " (optional)" or "", "\n") end
            end
          end
        end
      end
    end
  end
end
