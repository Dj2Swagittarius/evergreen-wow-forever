-- Unit tests for !Everror's pure core. Run from addon/tools: luajit test_everror.lua
local ns = {}
assert(loadfile("../!Everror/Core.lua"))("!Everror", ns)
local C = ns.Core

local fails, passes = 0, 0
local function check(ok, what)
  if ok then passes = passes + 1 else fails = fails + 1; print("FAIL " .. what) end
end

local STACK = table.concat({
  "[Interface/AddOns/!Everror/Capture.lua]:30: in function <Interface/AddOns/!Everror/Capture.lua:25>",
  "[Interface/AddOns/ExampleGuide/ExampleGuide.lua]:5983: in function 'GetQuestInfoByTargetName'",
  "[Interface/AddOns/ExampleGuide/ExampleGuide.lua]:6067: in function 'OnTolltipShow'",
}, "\n")
local LOCALS = table.concat({
  'name = "Mangy Duskbat"',
  "result = <table> {",
  " objectives = <table> {",
  " }",
  "}",
  "DGV = <table> {",
  " questId2Title_RU = <table> {",
  " }",
  ' version = "1.95"',
  "}",
  "(*temporary) = nil",
}, "\n")
local MSG = "...erface/AddOns/ExampleGuide/ExampleGuide.lua:5983: attempt to call a nil value"

-- sessions
local db = {}
C.Init(db)
local s1 = C.NewSession(db, 1000)
check(s1.id == 1 and s1.kind == "login" and #db.sessions == 1, "first session")
C.SetKind(db, "reload")
check(C.Current(db).kind == "reload", "kind set on current session")

-- record + dedupe
local e = C.Record(db, { msg = MSG, stack = STACK, locals = LOCALS }, 1001)
check(e.count == 1 and e.addon == "ExampleGuide", "recorded with addon " .. tostring(e.addon))
for t = 1002, 1010 do C.Record(db, { msg = MSG, stack = STACK, locals = LOCALS }, t) end
check(#C.Current(db).errors == 1 and e.count == 10 and e.first == 1001 and e.last == 1010, "repeats merge into one entry")
C.Record(db, { msg = "other error", stack = STACK }, 1011)
check(#C.Current(db).errors == 2, "different message is a new entry")
check(C.CountCurrent(db) == 2, "current session count")

-- trimming
check(not e.stack:find("!Everror"), "own frames dropped from stack")
check(e.stack:find("GetQuestInfoByTargetName", 1, true) ~= nil, "real frames kept")
check(e.locals:find('name = "Mangy Duskbat"', 1, true) ~= nil, "plain local kept")
check(e.locals:find("result = <table>", 1, true) ~= nil and not e.locals:find("objectives"), "table local collapsed")
check(not e.locals:find("questId2Title_RU") and not e.locals:find("version"), "table contents dropped")
local long = {}
for i = 1, 60 do long[i] = "[Interface/AddOns/X/x.lua]:" .. i .. ": in function 'f'" end
check(select(2, C.TrimStack(table.concat(long, "\n")):gsub("\n", "")) == 19 + 1, "stack capped at 20 lines (+ note)")
check(#C.TrimLocals("x = \"" .. string.rep("a", 400) .. "\"") <= 163, "local line capped")
check(C.TrimLocals("i=1\n(*temporary)=nil\n(for state) = <table>\nmsg=\"x\"") == "i=1\nmsg=\"x\"", "internal slots dropped")

-- addon attribution
check(C.AddonOf("Interface/AddOns/Everbid/Craft.lua:31: attempt", "") == "Everbid", "addon from message")
check(C.AddonOf("bad", "[Interface/AddOns/!Everror/a.lua]:1\n[Interface/AddOns/Questie/q.lua]:2") == "Questie", "addon from stack, skipping ourselves")
check(C.AddonOf("bad", "") == "?", "unknown addon")

-- format
local text = C.FormatSession(C.Current(db))
check(text:find("== Session #1", 1, true) and text:find("reload", 1, true) and text:find("(2 errors)", 1, true), "session header")
check(text:find("[x10] ExampleGuide", 1, true) ~= nil, "entry header with count")
check(text:find("Message: " .. MSG, 1, true) ~= nil and text:find("Stack:", 1, true) and text:find("Locals:", 1, true), "entry body")

-- new session, last session
local s2 = C.NewSession(db, 2000)
check(s2.id == 2 and C.CountCurrent(db) == 0, "new session starts empty")
check(C.Last(db) == s1, "last session is the previous one")
check(C.FormatAll(db):find("Session #1", 1, true) and C.FormatAll(db):find("Session #2", 1, true), "all sessions")

-- limits: 10 sessions
for i = 1, 12 do C.NewSession(db, 3000 + i) end
check(#db.sessions == 10 and db.sessions[10].id == 14, "keeps 10 newest sessions")

-- limits: 200 errors total, oldest sessions drop first
local db2 = {}
C.Init(db2)
C.NewSession(db2, 1)
for i = 1, 150 do C.Record(db2, { msg = "a" .. i }, i) end
C.NewSession(db2, 2)
for i = 1, 100 do C.Record(db2, { msg = "b" .. i }, i) end
local total = 0
for _, s in ipairs(db2.sessions) do total = total + #s.errors end
check(total == 200 and #C.Current(db2).errors == 100, "200 total, current session kept (" .. total .. ")")
C.NewSession(db2, 3)
for i = 1, 230 do C.Record(db2, { msg = "c" .. i }, i) end
check(#C.Current(db2).errors == 200 and C.Current(db2).dropped == 30, "current session capped, dropped counted")
check(C.FormatSession(C.Current(db2)):find("30 more not kept", 1, true) ~= nil, "dropped shown in text")

-- empty
local db3 = {}
C.Init(db3)
C.NewSession(db3, 5)
check(C.FormatSession(C.Current(db3)):find("No errors", 1, true) ~= nil, "empty session text")
check(C.Last(db3) == nil and C.FormatSession(nil):find("No earlier session", 1, true), "no last session")


-- Smoke: load Capture + UI against a fake WoW API and drive the handler, events and slash command.
do
  local function fake(extra)
    return setmetatable(extra or {}, { __index = function(t, k)
      if type(k) ~= "string" or not k:match("^%u") then return nil end
      local f = function() end
      rawset(t, k, f)
      return f
    end })
  end
  local handlers, shown = {}, {}
  local function newFrame(kind, name)
    local f = fake()
    f.CreateFontString = function() return newFrame() end
    f.CreateAnimationGroup = function() local g = fake(); g.CreateAnimation = function() return fake() end; g.IsPlaying = function() return false end; return g end
    f.SetScript = function(self, k, fn) self["_" .. k] = fn end
    f.IsShown = function(self) return shown[self] end
    f.Show = function(self) shown[self] = true; if self._OnShow then self._OnShow(self) end end
    f.Hide = function(self) shown[self] = false end
    f.SetShown = function(self, v) shown[self] = v end
    f.GetPoint = function() return "TOP", nil, "TOP", 5, -100 end
    f.StopMovingOrSizing = function() end
    f.SetText = function(self, t) self.text = t end
    if name then _G[name] = f end
    handlers[#handlers + 1] = f
    return f
  end
  _G.CreateFrame = newFrame
  _G.UIParent = newFrame()
  _G.UISpecialFrames = {}
  _G.tinsert = table.insert
  _G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  _G.time = os.time
  _G.C_Timer = { NewTicker = function(_, fn) for _ = 1, 6 do fn() end return { Cancel = function() end } end, After = function(_, fn) fn() end }
  _G.GameTooltip = fake()
  _G.ChatFontNormal = {}
  local cvars = { scriptErrors = "1" }
  _G.GetCVar = function(k) return cvars[k] end
  _G.SetCVar = function(k, v) cvars[k] = v end
  _G.SlashCmdList = {}
  local blizzardCalls = 0
  local current = function() blizzardCalls = blizzardCalls + 1 end
  _G.geterrorhandler = function() return current end
  _G.seterrorhandler = function(fn) current = fn end
  _G.debugstack = function() return "[Interface/AddOns/Everbid/Craft.lua]:31: in function <x>" end
  _G.debuglocals = function() return table.concat({ "id = 2901", "ns = <table> {", " Flip = <table> {", " }", "}" }, "\n") end
  _G.GetCallstackHeight = function() return 10 end
  _G.GetErrorCallstackHeight = function() return 4 end
  _G.EverrorDB = { sessions = {}, nextID = 7 }
  local sns = {}
  for _, f in ipairs({ "Core.lua", "Capture.lua", "UI.lua" }) do assert(loadfile("../!Everror/" .. f))("!Everror", sns) end
  local function fire(...) for _, fr in ipairs(handlers) do if fr._OnEvent then fr._OnEvent(fr, ...) end end end
  -- errors before ADDON_LOADED are buffered
  current("Interface/AddOns/Everbid/Craft.lua:31: attempt to call a nil value")
  check(blizzardCalls == 1, "chains to Blizzard's handler")
  check(sns.db == nil, "buffered before SavedVariables")
  fire("ADDON_LOADED", "!Everror")
  local s = sns.Core.Current(sns.db)
  check(s and s.id == 7 and #s.errors == 1 and s.errors[1].addon == "Everbid", "buffered error flushed into new session")
  check(s.errors[1].locals == "id = 2901\nns = <table>", "locals trimmed in game path")
  check(cvars.scriptErrors == "0" and sns.db.restoreScriptErrors, "Blizzard popup turned off, old value remembered")
  check(shown[_G.EverrorButton] == true and _G.EverrorButton.Text.text == "! 1", "button shows count")
  fire("PLAYER_ENTERING_WORLD", false, true)
  check(s.kind == "reload", "reload session kind")
  fire("PLAYER_ENTERING_WORLD", false, false)
  check(s.kind == "reload", "zone change keeps kind")
  current("second error")
  check(#s.errors == 2 and blizzardCalls == 2, "live error recorded and chained")
  fire("ADDON_ACTION_BLOCKED", "ExampleGuide", "CastSpellByName")
  check(s.errors[3].kind == "blocked", "blocked action recorded")
  SlashCmdList.EVERROR("")
  check(shown[_G.EverrorFrame] == true, "/err opens the window")
  SlashCmdList.EVERROR("all")
  cvars.scriptErrors = "1" -- account settings synced from the server turn it back on
  fire("CVAR_UPDATE", "scriptErrors")
  check(cvars.scriptErrors == "0", "popup setting re-applied after server sync")
  cvars.scriptErrors = "1"
  fire("VARIABLES_LOADED")
  check(cvars.scriptErrors == "0", "popup setting re-applied at VARIABLES_LOADED")
  SlashCmdList.EVERROR("popup")
  check(cvars.scriptErrors == "1" and not sns.db.popupOff, "/err popup restores Blizzard popup")
  SlashCmdList.EVERROR("clear")
  check(#s.errors == 0 and shown[_G.EverrorButton] == false, "/err clear empties and hides button")
end

-- WoW's Lua has no os/io libraries (only the date/time globals); the tests run where they exist,
-- so check the source instead.
for _, f in ipairs({ "Core.lua", "Capture.lua", "UI.lua" }) do
  local src = io.open("../!Everror/" .. f):read("*a")
  local bad = src:gsub("%-%-[^\n]*", ""):gsub("date or os%.date", ""):match("[^%w_]os%.%w+") or
    src:match("[^%w_]io%.%w+")
  check(not bad, f .. " uses " .. tostring(bad) .. ", which WoW doesn't have")
end

print(("Everror tests: %d passed, %d failed"):format(passes, fails))
os.exit(fails == 0 and 0 or 1)
