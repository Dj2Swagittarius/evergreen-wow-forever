-- Tests for Evergreen_Professions. Run from addon/tools: luajit test_professions.lua
-- Loads the Evergreen core and the Professions module against a fake WoW API, first with a small
-- fixture guide (skill detection, current step, material counts, routes, faction filter, trainer
-- waypoints, shopping ticks, /prof and /eg prof, a missing data file), then with the real generated
-- Prof_Data.lua when it is there (every guide and tab drawn at several skill levels).
local fails, passes = 0, 0
local function check(ok, what)
  if ok then passes = passes + 1 else fails = fails + 1; io.write("FAIL " .. what .. "\n") end
end

local ROOT = "../"

---------------------------------------------------------------------------
-- fixture: one profession with a route choice, a faction-only part and a prose guide
---------------------------------------------------------------------------
local FIXTURE = {
  npcs = {
    whuut = { n = "Whuut", m = 1454, x = 55.9, y = 33.1, z = "Orgrimmar", f = "H", role = "Alchemy Trainer" },
    telathir = { n = "Tel'Athir", m = 1453, x = 46.4, y = 79.1, z = "Stormwind City", f = "A" },
    yelmak = { n = "Yelmak", m = 1454, x = 56.5, y = 32.9, z = "Orgrimmar", f = "H" },
    lilyssia = { n = "Lilyssia Nightbreeze", m = 1453, x = 46.5, y = 79.2, z = "Stormwind City", f = "A" },
    algernon = { n = "Algernon", m = 1458, x = 51.8, y = 74.6, z = "Undercity", f = "H" },
    nopos = { n = "Somebody" },
    nat = { n = "Nat Pagle", m = 1445, x = 58.5, y = 59.9, z = "Dustwallow Marsh" },
  },
  guides = {
    { key = "alchemy", name = "Alchemy", skill = "Alchemy",
      trainers = { H = { { npc = "whuut", city = "Orgrimmar" } }, A = { { npc = "telathir", city = "Stormwind City" } } },
      tiers = {
        { name = "Apprentice", title = "Apprentice Alchemy (1-55)", from = 1, to = 55,
          trainers = { H = { { npc = "whuut", city = "Orgrimmar" } }, A = { { npc = "telathir", city = "Stormwind City" } } } },
        { name = "Journeyman", title = "Journeyman Alchemy (55-150)", from = 55, to = 150,
          train = "Learn Journeyman Alchemy, it requires Alchemy 50 and level 10.",
          trainers = { H = { { npc = "yelmak", city = "Orgrimmar" } }, A = { { npc = "lilyssia", city = "Stormwind City" } } } },
      },
      startZones = { { races = "Orc, Troll", zone = "Durotar", text = "Whuut nearby", npcs = { "whuut" } } },
      shopping = { { title = "1-150", note = { "estimates" }, rows = {
        { mats = { { n = "Peacebloom", c = 91, i = 2447 } } },
        { mats = { { n = "Silverleaf", c = 45, i = 765 } }, alt = { { n = "Mageroyal", c = 40, i = 785 } } },
      } } },
      recipeTables = { { title = "Recipes from the Auction House", rows = { { name = "Elixir of the Sages", spell = 17555, learn = 270, yellow = 285, grey = 325, mats = "1 Dreamfoil" } } } },
      entries = {
        { k = "h", lvl = 2, title = "Apprentice Alchemy (1-55)", from = 1, to = 55 },
        { k = "s", from = 1, to = 10, crafts = { { c = 9, name = "Minor Arcane Elixir", spell = 1245246,
            mats = { { n = "Peacebloom", c = 9, i = 2447 }, { n = "Empty Vial", c = 9, i = 3371 } } } },
          alts = { { c = 9, name = "Elixir of Minor Force", spell = 1245250, mats = { { n = "Silverleaf", c = 9, i = 765 } } } },
          note = { "Or 9x Elixir of Minor Force." }, npcs = { "algernon" } },
        { k = "s", from = 10, to = 55, crafts = { { c = 45, name = "Elixir of Minor Defense", spell = 7183,
            mats = { { n = "Silverleaf", c = 45, i = 765 }, { n = "Peacebloom", c = 45, i = 2447 }, { n = "Bolt of Linen Cloth", c = 5 } } } } },
        { k = "h", lvl = 2, title = "Journeyman Alchemy (55-150)", from = 55, to = 150, text = { "To train past 75..." } },
        { k = "v", g = "Journeyman:1", labels = { "Herbs", "Oils" } },
        { k = "s", from = 55, to = 100, var = { g = "Journeyman:1", i = 1 }, crafts = { { c = 50, name = "Minor Mana Potion", spell = 2331, mats = { { n = "Mageroyal", c = 50, i = 785 } } } } },
        { k = "s", from = 55, to = 100, var = { g = "Journeyman:1", i = 2 }, crafts = { { c = 50, name = "Fire Oil", spell = 7837, mats = { { n = "Firefin Snapper", c = 100, i = 6359 } } } } },
        { k = "s", from = 100, to = 150, fac = "A", crafts = { { c = 50, name = "Alliance Brew", spell = 1, mats = {} } } },
        { k = "s", from = 100, to = 150, fac = "H", pick = "all", crafts = {
            { c = 20, name = "Horde Brew", spell = 2, mats = { { n = "Peacebloom", c = 20, i = 2447 } } },
            { c = 10, name = "Horde Tonic", spell = 3, mats = { { n = "Peacebloom", c = 10, i = 2447 } } } },
          recipes = { { i = 13477, n = "Recipe: Horde Brew", npcs = { "algernon", "telathir" } } } },
        { k = "h", lvl = 5, title = "", text = { "A note after the last step." }, way = { { m = 1445, x = 58.5, y = 59.9, title = "Nat Pagle" } } },
      } },
    { key = "fishing", name = "Fishing", skill = "Fishing", tiers = {}, trainers = { H = {}, A = {} }, startZones = {},
      shopping = {}, recipeTables = {},
      entries = {
        { k = "h", lvl = 2, title = "How to fish (1-75)", from = 1, to = 75, text = { "Buy a pole." } },
        { k = "h", lvl = 2, title = "75-150", from = 75, to = 150, text = { "Fish in a capital." }, npcs = { "nopos" } },
        { k = "h", lvl = 2, title = "Learning Artisan Fishing", text = { "Nat Pagle quest." }, way = { { m = 1445, x = 58.5, y = 59.9, title = "Nat Pagle" } } },
      } },
    { key = "cooking", name = "Cooking", skill = "Cooking", tiers = {}, trainers = { H = {}, A = {} }, startZones = {},
      shopping = {}, recipeTables = {},
      entries = { { k = "s", from = 1, to = 50, pick = "one", crafts = {
        { c = 55, name = "Brilliant Smallfish", spell = 7751, mats = { { n = "Raw Brilliant Smallfish", c = 55, i = 6291 } },
          src = "Mulgore: Harn", npcs = { "whuut", "telathir" } },
        { c = 55, name = "Charred Wolf Meat", spell = 2538, mats = { { n = "Stringy Wolf Meat", c = 55, i = 2672 } }, src = "Trainer" } } } } },
  },
}

---------------------------------------------------------------------------
-- fake WoW
---------------------------------------------------------------------------
local frames, timers, printed
local CHILD_KEYS = { NineSlice = true, PortraitContainer = true, portrait = true, Inset = true, Bg = true, CloseButton = true,
  Text = true, Instructions = true, searchIcon = true, Left = true, LeftActive = true, LeftTexture = true, TitleContainer = true,
  TitleText = true, Tabs = true, numTabs = true, skinned = true, fallbackTitle = true, contentTop = true, portraitW = true, locked = true }
local function newFrame(name)
  local f = { _scripts = {}, _events = {}, _shown = true, _name = name or false }
  setmetatable(f, { __index = function(t, k)
    if CHILD_KEYS[k] then return nil end
    if k == "SetScript" then return function(self, ev, fn) self._scripts[ev] = fn end end
    if k == "GetScript" then return function(self, ev) return self._scripts[ev] end end
    if k == "HookScript" then return function(self, ev, fn) local o = self._scripts[ev]; self._scripts[ev] = function(...) if o then o(...) end fn(...) end end end
    if k == "RegisterEvent" then return function(self, ev) self._events[ev] = true end end
    if k == "UnregisterEvent" then return function(self, ev) self._events[ev] = nil end end
    if k == "UnregisterAllEvents" then return function(self) self._events = {} end end
    if k == "Show" then return function(self) local was = self._shown; self._shown = true; if not was and self._scripts.OnShow then self._scripts.OnShow(self) end end end
    if k == "Hide" then return function(self) local was = self._shown; self._shown = false; if was and self._scripts.OnHide then self._scripts.OnHide(self) end end end
    if k == "SetShown" then return function(self, v) if v then self:Show() else self:Hide() end end end
    if k == "IsShown" or k == "IsVisible" then return function(self) return self._shown end end
    if k == "SetText" then return function(self, s) self._text = s end end
    if k == "GetText" then return function(self) return self._text or "" end end
    if k == "SetChecked" then return function(self, v) self._checked = v end end
    if k == "GetChecked" then return function(self) return self._checked end end
    if k == "GetPoint" then return function() return "CENTER", nil, "CENTER", 10, 20 end end
    if k == "GetName" then return function(self) return self._name or nil end end
    if k == "SetID" then return function(self, id) self._id = id end end
    if k == "GetID" then return function(self) return self._id or 0 end end
    if k == "GetFont" then return function() return "Fonts\\FRIZQT__.TTF", 12 end end
    if k:match("^Create") then return function(self, n) return newFrame(n) end end
    if k:match("^Get") then return function() return 0 end end
    if k:match("^Is") or k:match("^Has") or k:match("^Can") then return function() return false end end
    return function() end
  end })
  frames[#frames + 1] = f
  if name then _G[name] = f end
  return f
end

local W = {}   -- the world the fake API reads
local function setup(faction, race)
  frames, timers, printed = {}, {}, {}
  W.skills = { { "Professions", true }, { "Alchemy", false, 30, 75 }, { "Fishing", false, 80, 150 } }
  W.items = { [2447] = 12, [3371] = 9, [765] = 50, ["Bolt of Linen Cloth"] = 3 }
  W.waypoint, W.supertrack, W.external, W.tomtom = nil, nil, nil, nil
  CreateFrame = function(_, name) return newFrame(name) end
  UIParent, Minimap, GameTooltip = newFrame("UIParent"), newFrame("Minimap"), newFrame("GameTooltip")
  print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end printed[#printed + 1] = table.concat(t, " ") end
  tinsert, wipe = table.insert, function(t) for k in pairs(t) do t[k] = nil end return t end
  strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
  SlashCmdList, UISpecialFrames = {}, {}
  C_Timer = { After = function(_, f) timers[#timers + 1] = f end }
  GetCursorPosition = function() return 0, 0 end
  UnitFactionGroup = function() return faction end
  UnitRace = function() return race, race end
  UnitName = function() return "Tester" end
  GetNumSkillLines = function() return #W.skills end
  GetSkillLineInfo = function(i) local s = W.skills[i]; if s then return s[1], s[2], false, s[3], 0, 0, s[4] end end
  GetProfessions = nil
  GetItemCount = function(item, bank) return W.items[item] or 0 end
  C_Item = nil
  C_Map = { SetUserWaypoint = function(p) W.waypoint = p end, ClearUserWaypoint = function() W.waypoint = nil end }
  C_SuperTrack = { SetSuperTrackedUserWaypoint = function(v) W.supertrack = v end }
  UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { m = m, x = x, y = y } end }
  TomTom = nil
  EvergreenDB, EvergreenCharDB, EvergreenNS = nil, nil, nil
  issecretvalue = nil
  Everbid = nil
end

local function flush() for _ = 1, 5 do local t = timers; timers = {}; for _, f in ipairs(t) do f() end end end
local function fire(ev, ...)
  for _, f in ipairs(frames) do
    if f._events[ev] and f._scripts.OnEvent then f._scripts.OnEvent(f, ev, ...) end
  end
  flush()
end

-- load the core and the module the way WoW does (each addon its own private table)
local function load(data)   -- data: table (fixture), "real" (the generated file), or nil (missing file)
  local core = {}
  assert(loadfile(ROOT .. "Evergreen/Modules.lua"))("Evergreen", core)
  fire("ADDON_LOADED", "Evergreen")
  local private = {}
  for _, file in ipairs({ "Link.lua", "Prof_Data.lua", "Professions.lua", "Professions_UI.lua" }) do
    if file == "Prof_Data.lua" then
      if data == "real" then assert(loadfile(ROOT .. "Evergreen_Professions/Prof_Data.lua"))("Evergreen_Professions", private)
      elseif type(data) == "table" then private.ProfessionsData = data end
    else
      assert(loadfile(ROOT .. "Evergreen_Professions/" .. file))("Evergreen_Professions", private)
    end
  end
  fire("ADDON_LOADED", "Evergreen_Professions")
  fire("PLAYER_LOGIN")
  return core, core.Professions
end

local function contentText(C)
  local t = {}
  for i = 1, C.used.text do t[#t + 1] = C.pool.text[i]._text or "" end
  for i = 1, C.used.line do t[#t + 1] = C.pool.line[i].label or "" end
  for i = 1, C.used.check do t[#t + 1] = C.pool.check[i].label or "" end
  return table.concat(t, "\n")
end
local function findLine(C, pattern)
  for i = 1, C.used.line do
    local r = C.pool.line[i]
    if (r.label or ""):find(pattern) then return r end
  end
end
local function tab(P, name)
  for i, n in ipairs({ "Guide", "Trainers", "Shopping", "Recipes" }) do
    local b = P.ui.frame.Tabs[i]
    if n == name then b._scripts.OnClick(b) end
  end
end

---------------------------------------------------------------------------
-- fixture, Horde
---------------------------------------------------------------------------
do
  setup("Horde", "Orc")
  local ns, P = load(FIXTURE)
  check(P and P.ui and P.ui.Build, "module loaded")
  check(P.Skill("Alchemy") == 30 and select(2, P.Skill("Alchemy")) == 75, "skill from GetSkillLineInfo")
  check(P.Skill("alchemy") == 30, "skill lookup ignores case")
  check(P.Skill("Cooking") == nil, "unlearned skill is nil")
  check(#P.Learned() == 2 and P.Learned()[1].key == "alchemy", "learned guides")
  check(P.DefaultGuide().key == "alchemy", "default: the learned primary profession")

  SlashCmdList.EVERGREENPROF("")
  local UI = P.ui
  local f = P.ui.frame
  check(f and f._shown, "/prof opens the window")
  check(P.current.key == "alchemy", "opens on alchemy")
  local g = P.current
  check(UI.currentIndex == 3 and g.entries[3].from == 10, "current step at skill 30 is 10-55")
  check(UI.selected == UI.currentIndex, "current step selected")
  local d = contentText(UI.detail)
  check(d:find("25x Elixir of Minor Defense", 1, true) and d:find("25 left of 45", 1, true), "detail shows the recipe, scaled to the crafts left at skill 30")
  check(d:find("12 / 25", 1, true) and d:find("50 / 25", 1, true), "material have/need counts for the crafts left")
  check(d:find("Bolt of Linen Cloth", 1, true) and d:find("3 / 3", 1, true), "material without item ID counted by name")
  check(d:find("you are here", 1, true), "current step marked")

  -- the list marks the current step
  local marked
  for _, r in ipairs(UI.rows) do if r._shown and r.index == UI.currentIndex and (r.text._text or ""):find("> ", 1, true) then marked = true end end
  check(marked, "list row of the current step marked")

  -- skill goes up: SKILL_LINES_CHANGED moves the step
  W.skills[2][3], W.skills[2][4] = 60, 150
  fire("SKILL_LINES_CHANGED")
  check(UI.currentIndex == 6 and g.entries[6].var.i == 1, "skill 60: first route's 55-100 step")
  P.SetVariant(g, "Journeyman:1", 2)
  UI.Refresh()
  check(UI.currentIndex == 7, "route 2 picked: its step is current")
  -- the route row: second click switches
  UI.Click(5); UI.Click(5)
  check(P.Variant(g, "Journeyman:1") == 1, "clicking the route row twice switches route")
  check(EvergreenDB.professions.variants.alchemy["Journeyman:1"] == 1, "route saved")

  -- faction: the Horde step, not the Alliance one
  W.skills[2][3] = 120
  fire("SKILL_LINES_CHANGED")
  check(g.entries[UI.currentIndex].fac == "H", "Horde-only step for a Horde character")
  UI.selected = UI.currentIndex; UI.Refresh()
  d = contentText(UI.detail)
  check(d:find("Make all of these", 1, true), "pick all heading")
  check(d:find("Peacebloom|r  |cffff404012 / 18", 1, true), "all materials summed for the crafts left (12 + 6 Peacebloom)")
  check(d:find("Algernon", 1, true) and not d:find("Tel'Athir", 1, true), "recipe vendors filtered by faction")
  check(d:find("A note after the last step.", 1, true), "untitled block after a step shown with it")
  local nat = findLine(UI.detail, "Nat Pagle")
  check(nat and nat.onClick, "waypoint line in the step")
  nat.onClick(nat)
  check(W.waypoint and W.waypoint.m == 1445 and math.abs(W.waypoint.x - 0.585) < 1e-9 and W.supertrack == true, "map pin waypoint without the guide module")
  local list = UI.ListEntries(g)
  local hasA = false
  for _, i in ipairs(list) do if g.entries[i].fac == "A" then hasA = true end end
  check(not hasA, "Alliance step hidden from the list")

  -- trainers tab: next training, faction filtered, click sets a waypoint
  tab(P, "Trainers")
  check(UI.tab == "Trainers" and not UI.list._shown and UI.page.body._shown, "trainers tab shown")
  local t = contentText(UI.page)
  check(t:find("Next: Journeyman", 1, true) == nil, "skill 120/150: Journeyman already trained, no next tier")
  check(t:find("Yelmak", 1, true) and not t:find("Lilyssia", 1, true), "Horde trainers only")
  check(t:find("Orc, Troll", 1, true), "starting zone rows")
  W.waypoint = nil
  local y = findLine(UI.page, "Yelmak")
  y.onClick(y)
  check(W.waypoint and W.waypoint.m == 1454 and math.abs(W.waypoint.y - 0.329) < 1e-9, "trainer click: map pin at the trainer")
  -- with the guide module, its arrow takes the waypoint
  ns.SetExternalTarget = function(m, x, yy, title) W.external = { m, x, yy, title } end
  EvergreenCharDB = EvergreenCharDB or {}
  W.waypoint = nil
  y.onClick(y)
  check(W.external and W.external[1] == 1454 and W.external[4] == "Yelmak" and not W.waypoint, "trainer click: Evergreen arrow when the guide is on")
  EvergreenDB.modules.guide = false
  W.external = nil
  y.onClick(y)
  check(not W.external and W.waypoint, "guide module off: map pin again")
  EvergreenDB.modules.guide = nil
  ns.SetExternalTarget = nil

  W.skills[2][3], W.skills[2][4] = 40, 75
  fire("SKILL_LINES_CHANGED")
  check(P.NextTier(g).name == "Journeyman", "skill 40/75: next tier Journeyman")
  t = contentText(UI.page)
  check(t:find("Next: Journeyman", 1, true) and t:find("requires Alchemy 50", 1, true), "next training shown")

  -- shopping ticks per character
  tab(P, "Shopping")
  t = contentText(UI.page)
  check(t:find("91x Peacebloom", 1, true) and t:find("(12)", 1, true), "shopping row with bag count")
  check(t:find("or: 40x Mageroyal", 1, true), "shopping alternative")
  local c = UI.page.pool.check[1]
  c._checked = true
  c._scripts.OnClick(c)
  check(EvergreenCharDB.professions.shop["alchemy:1:1"] == true, "tick saved per character")
  check(UI.page.pool.check[1]._checked == true, "tick shown after redraw")

  tab(P, "Recipes")
  t = contentText(UI.page)
  check(t:find("Recipe: Horde Brew", 1, true) and t:find("Elixir of the Sages", 1, true), "recipes tab")

  -- prose guide: headings are the steps
  tab(P, "Guide")
  P.Select("fishing"); UI.SelectCurrent()
  check(UI.currentIndex == 2, "fishing 80: the 75-150 heading is current")
  d = contentText(UI.detail)
  check(d:find("Fish in a capital.", 1, true) and d:find("no position", 1, true), "prose heading text and an NPC without a position")

  -- cooking: not learned, one-of crafts, recipe sources filtered
  P.Select("cooking"); UI.SelectCurrent()
  check(UI.currentIndex == nil and UI.selected == 1, "unlearned: no current step, first row selected")
  d = contentText(UI.detail)
  check(d:find("Make one of these", 1, true) and d:find("Whuut", 1, true) and not d:find("Tel'Athir", 1, true), "cooking recipe sources for Horde")
  check(UI.skillText._text:find("not learned", 1, true), "header says not learned")

  -- picker menu lists learned professions first
  UI.ToggleMenu()
  check(UI.menu._shown and UI.menu.rows[1].key == "alchemy" and UI.menu.rows[3].key == "cooking", "menu: learned first")
  UI.menu.rows[2]._scripts.OnClick(UI.menu.rows[2])
  check(P.current.key == "fishing" and not UI.menu._shown and EvergreenDB.professions.prof == "fishing", "menu pick")

  -- the trade skill window reports a skill the skill lines do not
  C_TradeSkillUI = { GetBaseProfessionInfo = function() return { professionName = "Cooking", skillLevel = 77, maxSkillLevel = 150 } end }
  fire("TRADE_SKILL_SHOW")
  check(P.Skill("Cooking") == 77, "skill from the trade skill window")
  C_TradeSkillUI = nil

  -- secret values never reach a comparison
  issecretvalue = function(v) return v == "Alchemy" end
  P.ScanSkills()
  check(P.Skill("Alchemy") == nil, "secret skill name skipped")
  issecretvalue = nil
  P.ScanSkills()

  -- slash forms
  f:Hide()
  SlashCmdList.EVERGREEN("prof alch")
  check(f._shown and P.current.key == "alchemy", "/eg prof alch opens alchemy")
  SlashCmdList.EVERGREENPROF("")
  check(not f._shown, "/prof toggles closed")
  SlashCmdList.EVERGREENPROF("nosuch")
  check(printed[#printed]:find("no profession guide matches", 1, true), "/prof unknown name")
  SlashCmdList.EVERGREENPROF("skills")
  check(printed[#printed]:find("Alchemy 40/75", 1, true), "/prof skills")
  check(UISpecialFrames[1] == "EvergreenProfessionsFrame", "Escape closes the window")
  local listed = false
  for _, m in ipairs(ns.MODULES) do if m.id == "professions" then listed = true end end
  check(listed, "listed in /eg modules")
  f._scripts.OnDragStop(f)
  check(EvergreenDB.professions.pos and EvergreenDB.professions.pos[3] == 10, "window position saved")
end

---------------------------------------------------------------------------
-- fixture, Alliance
---------------------------------------------------------------------------
do
  setup("Alliance", "Human")
  local _, P = load(FIXTURE)
  W.skills[2][3], W.skills[2][4] = 120, 150
  fire("SKILL_LINES_CHANGED")
  SlashCmdList.EVERGREENPROF("alchemy")
  local g, UI = P.current, P.ui
  check(g.entries[UI.currentIndex].fac == "A", "Alliance-only step for an Alliance character")
  tab(P, "Trainers")
  local t = contentText(UI.page)
  check(t:find("Lilyssia", 1, true) and not t:find("Yelmak", 1, true), "Alliance trainers only")
end

---------------------------------------------------------------------------
-- what's left of a step, and what buying it costs (Everbid prices)
---------------------------------------------------------------------------
do
  setup("Horde", "Orc")
  local _, P = load(FIXTURE)
  local e = { from = 50, to = 100 }
  local c = { c = 50, mats = { { n = "Strange Dust", c = 50, i = 10940 }, { n = "Vial", c = 25, i = 3371 } } }
  check(P.CraftsLeft(e, c, 40) == 50, "below the step: every craft left")
  check(P.CraftsLeft(e, c, 60) == 40, "10 of 50 points done: 40 crafts left")
  check(P.CraftsLeft(e, c, 100) == 0, "past the step: none left")
  check(P.CraftsLeft(e, c, nil) == 50, "unknown skill: the guide's count")
  check(P.MatNeed(c.mats[1], c, 40) == 40 and P.MatNeed(c.mats[2], c, 40) == 20, "materials scale with crafts left")
  check(P.UnitPrice(10940) == nil and not P.HasPrices(), "no Everbid: no price")
  local rows = {}
  Everbid = { PriceDB = { Get = function(_, key) return rows[key] end }, db = { vendorBuy = { [3371] = 20 } },
    Money = function(cu) return cu .. "c" end }
  rows["10940"] = { min = 150, qty = 9 }
  rows["3371"] = { min = 30, qty = 4 }
  local price, src = P.UnitPrice(10940)
  check(price == 150 and src == "AH", "AH price from Everbid")
  price, src = P.UnitPrice(3371)
  check(price == 20 and src == "vendor", "vendor price when cheaper")
  W.items[10940] = 9
  local total, unpriced = P.BuyCost({ { mat = c.mats[1], need = 40 }, { mat = c.mats[2], need = 20 },
    { mat = { n = "Unknown", i = 999 }, need = 3 } })
  -- 31 dust x 150 + 11 vials (9 in bags) x 20
  check(total == 31 * 150 + 11 * 20 and unpriced == 1, "cost of what's missing: " .. tostring(total) .. ", " .. tostring(unpriced))
  Everbid = nil
end

---------------------------------------------------------------------------
-- no data file
---------------------------------------------------------------------------
do
  setup("Horde", "Orc")
  local _, P = load(nil)
  check(P and P.Data() == nil, "loads without data")
  SlashCmdList.EVERGREENPROF("")
  check(P.ui.frame._shown, "window opens without data")
  check(contentText(P.ui.detail):find("import_wowprof_professions.py", 1, true), "no data: says how to make it")
  for _, name in ipairs({ "Trainers", "Shopping", "Recipes" }) do
    tab(P, name)
    check(contentText(P.ui.page):find("import_wowprof_professions.py", 1, true), "no data: " .. name .. " tab")
  end
end

---------------------------------------------------------------------------
-- the real generated data, when present
---------------------------------------------------------------------------
local real = io.open(ROOT .. "Evergreen_Professions/Prof_Data.lua")
if real then
  real:close()
  for _, fac in ipairs({ "Horde", "Alliance" }) do
    setup(fac, fac == "Horde" and "Undead" or "Night Elf")
    local _, P = load("real")
    check(P.Data() and #P.Guides() >= 10, fac .. ": real data loaded")
    SlashCmdList.EVERGREENPROF("")
    local UI = P.ui
    local drawn, bad = 0, 0
    for _, g in ipairs(P.Guides()) do
      for _, skill in ipairs({ 1, 37, 120, 180, 260, 299 }) do
        W.skills = { { g.skill, false, skill, 300 }, { "Cooking", false, skill, 300 } }
        P.ScanSkills()
        P.Select(g.key)
        UI.SelectCurrent()
        local i, e = P.CurrentIndex(g)
        if e and e.k == "s" and not (e.from <= skill and skill < e.to) and not (skill < e.from) then
          bad = bad + 1
          io.write(("  %s skill %d: step %d-%d\n"):format(g.key, skill, e.from, e.to))
        end
        for _, name in ipairs({ "Trainers", "Shopping", "Recipes", "Guide" }) do tab(P, name) end
        -- click every list row once
        for _, idx in ipairs(UI.ListEntries(g)) do UI.selected = idx; UI.RefreshDetail() end
        drawn = drawn + 1
      end
      -- every trainer with coordinates
      for _, t in ipairs(g.tiers or {}) do
        for _, x in ipairs(P.TrainersFor(t)) do
          local n = P.NPC(x.npc)
          if not (n and n.m and n.x) then bad = bad + 1; io.write("  no position: " .. g.key .. " " .. x.npc .. "\n") end
        end
      end
    end
    check(drawn == #P.Guides() * 6, fac .. ": every guide drawn at 6 skill levels")
    check(bad == 0, fac .. ": current steps match the skill, trainers have positions")
  end
else
  io.write("(no generated Prof_Data.lua: real data checks skipped)\n")
end

---------------------------------------------------------------------------
-- WoW has no os/io
---------------------------------------------------------------------------
for _, f in ipairs({ "Professions.lua", "Professions_UI.lua" }) do
  local src = io.open(ROOT .. "Evergreen_Professions/" .. f):read("*a"):gsub("%-%-[^\n]*", "")
  local badApi = src:match("[^%w_]os%.%w+") or src:match("[^%w_]io%.%w+")
  check(not badApi, f .. " uses " .. tostring(badApi) .. ", which WoW doesn't have")
end

io.write(("Professions tests: %d passed, %d failed\n"):format(passes, fails))
os.exit(fails == 0 and 0 or 1)
