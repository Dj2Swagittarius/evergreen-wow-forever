-- Smoke + behaviour tests for Evergreen_Farming against a fake WoW API.
-- Run from addon/tools: luajit test_farming.lua
-- Loads the Evergreen core (Modules.lua) and the Farming files (with a fixture route instead of the
-- generated Farm_Data.lua), opens the window, follows a route, walks the fake player along it, and
-- checks advancing, the arrow (own and the guide's), the world map pin, the minimap, stop and restore.
local fails, passes = 0, 0
local function check(ok, what)
  if ok then passes = passes + 1 else fails = fails + 1; io.write("FAIL ", what, "\n") end
end

local DIR = "../Evergreen_Farming/"
local said = {}

-- ---------------------------------------------------------------- fake world
local frames
local CHILD_KEYS = { NineSlice = true, PortraitContainer = true, portrait = true, Inset = true, Bg = true, CloseButton = true,
  Text = true, Instructions = true, searchIcon = true, Left = true, LeftActive = true, LeftTexture = true, TitleContainer = true,
  TitleText = true, Tabs = true, numTabs = true, skinned = true, fallbackTitle = true, contentTop = true, portraitW = true,
  locked = true, layer = true, provider = true, drawn = true, lines = true, dots = true, edges = true, labels = true,
  tex = true, title = true, dist = true, status = true, normalizedX = true, normalizedY = true, owningMap = true }
local function newFrame(name, parent)
  local f = { _scripts = {}, _events = {}, _shown = true, _name = name or false, _w = 0, _h = 0, _parent = parent }
  setmetatable(f, { __index = function(t, k)
    if CHILD_KEYS[k] or not k:match("^%u") then return nil end   -- data fields; methods are Capitalized
    if k == "SetScript" then return function(self, ev, fn) self._scripts[ev] = fn end end
    if k == "GetScript" then return function(self, ev) return self._scripts[ev] end end
    if k == "HookScript" then return function(self, ev, fn) local o = self._scripts[ev]; self._scripts[ev] = function(...) if o then o(...) end fn(...) end end end
    if k == "RegisterEvent" then return function(self, ev) self._events[ev] = true end end
    if k == "UnregisterEvent" then return function(self, ev) self._events[ev] = nil end end
    if k == "UnregisterAllEvents" then return function(self) self._events = {} end end
    if k == "Show" then return function(self) local was = self._shown; self._shown = true; if not was and self._scripts.OnShow then self._scripts.OnShow(self) end end end
    if k == "Hide" then return function(self) self._shown = false end end
    if k == "SetShown" then return function(self, v) if v then self:Show() else self:Hide() end end end
    if k == "IsShown" then return function(self) return self._shown end end
    if k == "IsVisible" then return function(self) return self._shown and (not self._parent or not self._parent.IsVisible or self._parent:IsVisible()) end end
    if k == "SetText" then return function(self, s) self._text = s end end
    if k == "GetText" then return function(self) return self._text or "" end end
    if k == "SetSize" then return function(self, w, h) self._w, self._h = w, h end end
    if k == "SetWidth" then return function(self, w) self._w = w end end
    if k == "SetHeight" then return function(self, h) self._h = h end end
    if k == "GetSize" then return function(self) return self._w, self._h end end
    if k == "GetWidth" then return function(self) return self._w end end
    if k == "GetHeight" then return function(self) return self._h end end
    if k == "SetPoint" then return function(self, ...) self._point = { ... } end end
    if k == "GetPoint" then return function() return "CENTER", nil, "CENTER", 0, 0 end end
    if k == "GetCenter" then return function() return 0, 0 end end
    if k == "GetName" then return function(self) return self._name or nil end end
    if k == "GetObjectType" then return function() return "Frame" end end
    if k == "GetEffectiveScale" or k == "GetScale" then return function() return 1 end end
    if k == "SetVertexColor" then return function(self, ...) self._color = { ... } end end
    if k == "SetTexCoord" then return function(self, ...) self._coord = { ... } end end
    if k == "SetPassThroughButtons" then return function(self) self._passthroughCalled = true end end
    if k == "GetFrameLevel" then return function() return 1 end end
    if k == "SetID" then return function(self, id) self._id = id end end
    if k == "GetID" then return function(self) return self._id or 0 end end
    if k:match("^Create") then return function(self, n) return newFrame(n, self) end end
    if k:match("^Get") then return function() return 0 end end
    if k:match("^Is") or k:match("^Has") or k:match("^Can") then return function() return false end end
    return function() end
  end })
  frames[#frames + 1] = f
  if name then _G[name] = f end
  return f
end

local state = { map = 1411, x = 0.49, y = 0.50, facing = 0 }
local MAP_YARDS = 1000   -- the fixture map is 1000 x 1000 yards: 1% = 10 yards

local function Vec(x, y) return { x = x, y = y, GetXY = function(s) return s.x, s.y end } end

local function installWorld()
  frames = {}
  _G.CreateFrame = function(_, name, parent) return newFrame(name, parent) end
  _G.UIParent = newFrame("UIParent")
  _G.Minimap = newFrame("Minimap"); Minimap._w, Minimap._h = 140, 140
  Minimap.GetZoom = function() return 0 end
  _G.GameTooltip = newFrame("GameTooltip")
  _G.print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end said[#said + 1] = table.concat(t, " ") end
  _G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  _G.tinsert = table.insert
  _G.UISpecialFrames = {}
  _G.SlashCmdList = {}
  _G.hooksecurefunc = function() end
  _G.CreateVector2D = Vec
  _G.GetCursorPosition = function() return 0, 0 end
  _G.GetPlayerFacing = function() return state.facing end
  _G.GetCVar = function() return "0" end
  _G.IsIndoors = function() return false end
  _G.IsShiftKeyDown = function() return false end
  _G.UnitName = function() return "Tester" end
  _G.C_AddOns = nil
  _G.C_Map = {
    GetBestMapForUnit = function() return state.map end,
    GetPlayerMapPosition = function() return Vec(state.x, state.y) end,
    GetMapInfo = function(id)
      if id == 1414 then return { mapID = id, name = "Kalimdor", mapType = 2, parentMapID = 947 } end
      return { mapID = id, name = "map" .. id, mapType = 3, parentMapID = 1414 }
    end,
    -- world x = north, world y = west
    GetWorldPosFromMapPos = function(map, v) return map == 1412 and 0 or 1, Vec(-v.y * MAP_YARDS, -v.x * MAP_YARDS) end,
    GetMapWorldSize = function() return MAP_YARDS, MAP_YARDS end,
    GetMapRectOnMap = function(map, onMap) if onMap == 1414 then return 0.6, 0.7, 0.4, 0.5 end end,
  }
  _G.C_Minimap = nil
  -- Blizzard's map canvas, enough of it: the pin/provider mixins and a world map that acquires pins
  -- the way MapCanvasMixin:AcquirePin does (OnLoad, OnAcquired, then CheckMouseButtonPassthrough)
  _G.MapCanvasPinMixin = {
    GetMap = function(self) return self.owningMap end,
    SetPosition = function(self, x, y) self.normalizedX, self.normalizedY = x, y end,
    SetIgnoreGlobalPinScale = function(self, v) self._ignoreScale = v end,
    UseFrameLevelType = function(self, t) self._level = t end,
    OnReleased = function() end,
    CheckMouseButtonPassthrough = function(self) self:SetPassThroughButtons() end,
  }
  _G.MapCanvasDataProviderMixin = {
    OnAdded = function(self, map) self.owningMap = map end,
    GetMap = function(self) return self.owningMap end,
    RefreshAllData = function() end, RemoveAllData = function() end,
  }
  local wm = newFrame("WorldMapFrame")
  wm._shown = false
  wm.providers, wm.pins = {}, {}
  wm.canvas = newFrame(nil); wm.canvas._w, wm.canvas._h = 1002, 668
  wm.mapID = 1411
  wm.GetMapID = function(self) return self.mapID end
  wm.GetCanvas = function(self) return self.canvas end
  wm.GetCanvasScale = function() return 2 end
  wm.AddDataProvider = function(self, p) self.providers[p] = true; p:OnAdded(self) end
  wm.RemoveAllPinsByTemplate = function(self, t) for _, pin in ipairs(self.pins) do if pin.template == t then pin._shown = false; pin.released = true end end end
  wm.AcquirePin = function(self, template, ...)
    assert(template == "EvergreenFarmRoutePinTemplate", "acquired a template that is not Farming's: " .. tostring(template))
    local pin = newFrame(nil, self.canvas)
    for k, v in pairs(_G.EvergreenFarmRoutePinMixin) do pin[k] = v end   -- the XML template's mixin
    pin.template, pin.owningMap = template, self
    pin:OnLoad(); pin:Show(); pin:OnAcquired(...)
    pin:CheckMouseButtonPassthrough("RightButton")
    self.pins[#self.pins + 1] = pin
    return pin
  end
  _G.WorldMapFrame = wm
end

local function fire(ev, ...)
  for _, f in ipairs(frames) do
    if f._events[ev] and f._scripts.OnEvent then f._scripts.OnEvent(f, ev, ...) end
  end
end

local FIXTURE = {
  {
    id = "ore-test", category = "Ore", zone = "Durotar", map = 1411, continent = 1414,
    name = "Copper (1-65)", materials = { "Copper Ore" }, skill = { 1, 65 },
    source = "fixture", notes = "Clear the cave, go left, then jump down.", yards = { 1000, 1000 }, loop = true,
    points = { { 50, 50 }, { 53, 50 }, { 56, 50, "Copper Vein" }, { 56, 54 }, { 50, 54 } },
  },
  {
    id = "herb-test", category = "Herbs", zone = "Mulgore", map = 1412, continent = 1414,
    name = "Peacebloom", materials = { "Peacebloom" }, skill = { 1, 70 }, source = "fixture", notes = "",
    yards = { 1000, 1000 }, loop = false, points = { { 10, 10, "Peacebloom" }, { 20, 20 } },
  },
}

-- load the core and the module; data = the fixture (or nil for "no Farm_Data.lua")
local function load(data, keepDB)
  installWorld()
  said = {}
  if not keepDB then EvergreenDB = nil; EvergreenCharDB = nil end
  local core = {}
  assert(loadfile("../Evergreen/Modules.lua"))("Evergreen", core)
  local priv = {}
  assert(loadfile(DIR .. "Link.lua"))("Evergreen_Farming", priv)
  EvergreenNS.FarmData = data
  for _, f in ipairs({ "Farm.lua", "Farm_Map.lua", "Farm_UI.lua" }) do
    assert(loadfile(DIR .. f))("Evergreen_Farming", priv)
  end
  fire("ADDON_LOADED", "Evergreen")
  fire("ADDON_LOADED", "Evergreen_Farming")
  fire("PLAYER_LOGIN")
  return core
end

local function at(x, y) state.x, state.y = x / 100, y / 100 end
local function lastSaid() return said[#said] or "" end

-- ---------------------------------------------------------------- the TOC
do
  local toc = io.open(DIR .. "Evergreen_Farming.toc"):read("*a")
  check(toc:find("## Interface: 16001, 11509", 1, true) and toc:find("## Dependencies: Evergreen", 1, true)
    and toc:find("## Group: Evergreen", 1, true) and toc:find("|cff7fd35eEvergreen|r - Farming", 1, true), "TOC header")
  local files = {}
  for line in toc:gmatch("[^\r\n]+") do if not line:match("^#") and line:match("%S") then files[#files + 1] = line end end
  check(table.concat(files, ",") == "Link.lua,Farm_Data.lua,Farm.lua,Farm_Map.lua,Farm_Map.xml,Farm_UI.lua", "TOC file order: " .. table.concat(files, ","))
  local xml = io.open(DIR .. "Farm_Map.xml"):read("*a")
  check(xml:find('name="EvergreenFarmRoutePinTemplate"', 1, true) and xml:find('mixin="EvergreenFarmRoutePinMixin"', 1, true), "pin template in XML")
end

-- ---------------------------------------------------------------- follow a route with the own arrow
local ns = load(FIXTURE)
local F = ns.Farm
check(F and F.db and #F.routes == 2, "module loaded with the fixture routes")
check(F.byId["ore-test"] and F.RangeText(F.byId["ore-test"]) == "1-65", "range text")
check(F.RangeText({ level = "Mostly 47-48, with a few 49-50 mobs north of the river." }) == "lvl 47-50", "sentence level text shortened")
check(F.RangeText({ level = "Northern area: 56-58, Southern area: 53-55" }) == "lvl 53-58", "two-area level text shortened")

-- window
SlashCmdList.EVERGREENFARM("")
local UI = F.UI
check(UI.frame and UI.frame._shown, "/farm opens the window")
local listed = {}
for _, r in ipairs(UI.rows) do if r._shown and r.route then listed[r.route.id] = true end end
check(listed["ore-test"] and not listed["herb-test"], "Ore tab lists the ore route only (continent filter)")
F.db.filter = "zone"; state.map = 1412; UI.Refresh()
listed = {}
for _, r in ipairs(UI.rows) do if r._shown and r.route then listed[r.route.id] = true end end
check(not listed["ore-test"], "zone filter hides other zones")
state.map = 1411; F.db.filter = "continent"
UI.tabs[2]._scripts.OnClick(UI.tabs[2])
listed = {}
for _, r in ipairs(UI.rows) do if r._shown and r.route then listed[r.route.id] = true end end
check(listed["herb-test"] and F.db.tab == 2, "Herbs tab lists the herb route")
UI.tabs[1]._scripts.OnClick(UI.tabs[1])
local row
for _, r in ipairs(UI.rows) do if r.route and r.route.id == "ore-test" then row = r end end
row._scripts.OnClick(row)
check(UI.selected == F.byId["ore-test"] and UI.notes:GetText():find("jump down", 1, true), "clicking a row shows its notes")

-- follow: starts at the nearest point
at(49, 50)
UI.follow._scripts.OnClick(UI.follow)
local r, i = F.Active()
check(r and r.id == "ore-test" and i == 1, "Follow activates at the nearest point")
check(F.cdb.route == "ore-test" and F.cdb.index == 1, "active route saved per character")
check(F.arrow and F.arrow._shown and not F.usingGuide, "own arrow shown without the guide")
F.Tick()
check(select(2, F.Active()) == 2, "within 25 yd of point 1: on to point 2")
at(52.5, 50); F.Tick()
check(select(2, F.Active()) == 3, "reached point 2: on to point 3")
check(F.arrow.title:GetText():find("Copper Vein 3/5", 1, true), "arrow title names the node: " .. tostring(F.arrow.title:GetText()))
check(F.arrowCell == 81, "arrow points east while facing north (cell " .. tostring(F.arrowCell) .. ")")
check(F.arrow.dist:GetText() == "35 yd", "arrow distance: " .. tostring(F.arrow.dist:GetText()))
state.facing = -math.pi / 2; F.Tick()                      -- facing east: straight ahead
check(F.arrowCell == 0, "arrow straight up when facing the point")
state.facing = 0

-- manual next / prev, key bindings
F.Next(); check(select(2, F.Active()) == 4, "Next")
EvergreenFarm_Prev(); check(select(2, F.Active()) == 3, "Prev (key binding)")
UI.nextB._scripts.OnClick(UI.nextB); check(select(2, F.Active()) == 4, "Next button")

-- the loop wraps around
F.SetIndex(5)
at(50.5, 54); F.Tick()
check(select(2, F.Active()) == 1 and lastSaid():find("lap done", 1, true), "loop route wraps to point 1")

-- minimap
at(50, 50.5)
F.SetIndex(2)
F.Map.UpdateMinimap()
check((F.Map.minimapShown or 0) >= 2, "minimap shows nearby points (" .. tostring(F.Map.minimapShown) .. ")")
local nx = F.Map.minimapNext
check(nx and nx[3] and math.abs(nx[1] - 30 * 140 / (466 + 2 / 3)) < 0.5 and math.abs(nx[2] - 5 * 140 / (466 + 2 / 3)) < 0.5,
  "next point placed east / north of the player on the minimap")
F.db.minimap = false; F.Map.UpdateMinimap()
check(F.Map.minimapShown == 0, "minimap points off")
F.db.minimap = true

-- world map: Farming's own pin through a data provider, no passthrough call reaches the frame
fire("ADDON_LOADED", "Blizzard_WorldMap")
check(WorldMapFrame.providers[F.Map.provider], "data provider added to the world map")
WorldMapFrame._shown = true
F.Notify("route")
local pin = F.Map.provider.pin
check(pin and pin.template == "EvergreenFarmRoutePinTemplate" and pin.drawn == 5, "route pin drawn with 5 points")
check(not pin._passthroughCalled, "pin never calls SetPassThroughButtons")
check(pin._ignoreScale and pin._level == "PIN_FRAME_LEVEL_AREA_POI", "pin ignores the global pin scale, own frame level")
check(pin.normalizedX == 0.5 and pin._w == 1002 and pin.layer._w == 2004, "pin covers the canvas, layer counters the zoom")
local labels = 0
for _, t in ipairs(pin.layer.labels.items) do if t._shown then labels = labels + 1 end end
check(labels >= 2, "points numbered on the map")
F.Next()
check(F.Map.provider.pin == pin, "a new point redraws the same pin")
WorldMapFrame.mapID = 1414; F.Map.provider:OnMapChanged()
check(F.Map.provider.pin and F.Map.provider.pin.drawn == 5, "route also drawn on the continent map")
WorldMapFrame.mapID = 1429; F.Map.provider:OnMapChanged()
check(F.Map.provider.pin == nil, "no pin on an unrelated map")
WorldMapFrame.mapID = 1411; F.Map.provider:OnMapChanged()

-- a route in another zone: the arrow says so
F.Activate("herb-test", 1)
F.Tick()
check(F.arrow.status:GetText() == "on another continent" and F.arrow.dist:GetText():find("Mulgore", 1, true), "route elsewhere shown on the arrow")
F.Activate("ore-test", 3)

-- ---------------------------------------------------------------- the guide's arrow
local ext
EvergreenNS.SetExternalTarget = function(map, x, y, title) ext = { map = map, x = x, y = y, title = title } end
EvergreenNS.GetExternalTarget = function() return ext end
EvergreenNS.ClearExternalTarget = function() ext = nil end
EvergreenDB.arrowShown = true
F.UpdateTarget()
check(ext and ext.map == 1411 and ext.x == 56 and ext.title:find("Farming: Copper Vein 3/5", 1, true), "guide's arrow gets the point")
check(F.usingGuide and not F.arrow._shown, "own arrow hidden while the guide's shows")
at(55, 51); F.Tick()
check(select(2, F.Active()) == 4 and ext.y == 54, "advancing moves the guide's target")
ext = nil; at(50, 50); F.Tick()                                 -- the guide cleared it (its own arrival check)
check(ext and ext.title:find("4/5", 1, true), "cleared guide target is set again")
EvergreenNS.SetExternalTarget(1426, 10, 10, "Journal: entrance")  -- the journal takes the guide's arrow
F.Tick()
check(ext.title == "Journal: entrance" and F.arrow._shown and not F.usingGuide, "journal keeps the guide's arrow, own arrow meanwhile")
EvergreenNS.ClearExternalTarget(); F.Tick()
check(ext and ext.title:find("Farming", 1, true) and F.usingGuide, "guide's arrow taken back when free")
F.db.arrow = "own"; F.UpdateTarget()
check(ext == nil and F.arrow._shown, "/farm arrow own releases the guide's arrow")
F.db.arrow = "auto"; F.UpdateTarget()
EvergreenDB.arrowShown = false; F.Tick()
check(ext == nil and F.arrow._shown, "guide's arrow hidden: own arrow")
EvergreenDB.arrowShown = true

-- ---------------------------------------------------------------- stop, slash commands
F.UpdateTarget()
UI.stop._scripts.OnClick(UI.stop)
check(F.Active() == nil and F.cdb.route == nil and ext == nil and not F.arrow._shown, "Stop clears route, arrow and guide target")
F.Map.UpdateMinimap()
check(F.Map.minimapShown == 0, "Stop clears the minimap")
check(F.Map.provider.pin == nil, "Stop removes the map pin")
SlashCmdList.EVERGREEN("farm ore-test")
check(F.Active() and F.Active().id == "ore-test", "/eg farm <id> activates")
SlashCmdList.EVERGREENFARM("next")
SlashCmdList.EVERGREENFARM("minimap"); check(F.db.minimap == false, "/farm minimap toggles"); SlashCmdList.EVERGREENFARM("minimap")
SlashCmdList.EVERGREENFARM("help"); check(lastSaid():find("/farm next", 1, true), "/farm help")
local keep = select(2, F.Active())

-- ---------------------------------------------------------------- reload restores the route
local DBs = { EvergreenDB, EvergreenCharDB }
ns = load(FIXTURE, true)
F = ns.Farm
check(F.Active() and F.Active().id == "ore-test" and select(2, F.Active()) == keep, "route and point restored after /reload")
check(#said == 0, "restoring is quiet")

-- ---------------------------------------------------------------- no Farm_Data.lua
ns = load(nil)
F = ns.Farm
check(F and #F.routes == 0, "loads without route data")
SlashCmdList.EVERGREENFARM("")
check(lastSaid():find("import_wowprof_farming.py", 1, true), "no data: chat says to run the importer")
check(F.UI.empty._shown and F.UI.empty:GetText():find("import_wowprof_farming.py", 1, true), "no data: window says to run the importer")
check(F.UI.rows[1]._shown == false, "no data: empty list")

-- ---------------------------------------------------------------- the generated data, when present
do
  local chunk = loadfile(DIR .. "Farm_Data.lua")
  if chunk then
    local d = {}
    chunk("Evergreen_Farming", d)
    local bad, n, cats = nil, 0, {}
    for _, r in ipairs(d.FarmData or {}) do
      n = n + 1
      cats[r.category] = true
      if not (r.id and r.map and r.map >= 1411 and r.map <= 1452 and r.zone and r.name and #r.points > 0) then bad = r.id or "?" end
      for _, p in ipairs(r.points) do
        if not (p[1] >= 0 and p[1] <= 100 and p[2] >= 0 and p[2] <= 100) then bad = r.id end
      end
    end
    check(not bad, "generated routes are well formed (" .. tostring(bad) .. ")")
    check(n > 0 and cats.Ore and cats.Herbs and cats.Leather, "generated data has all three categories (" .. n .. " routes)")
  end
end

-- ---------------------------------------------------------------- WoW has no os / io
for _, f in ipairs({ "Farm.lua", "Farm_Map.lua", "Farm_UI.lua" }) do
  local src = io.open(DIR .. f):read("*a"):gsub("%-%-[^\n]*", "")
  local bad = src:match("[^%w_]os%.%w+") or src:match("[^%w_]io%.%w+")
  check(not bad, f .. " uses " .. tostring(bad) .. ", which WoW doesn't have")
  check(not src:find("SetMapID", 1, true) and not src:find("RefreshAll()", 1, true), f .. " must not drive Blizzard's map")
end

io.write(("Farming tests: %d passed, %d failed\n"):format(passes, fails))
os.exit(fails == 0 and 0 or 1)
