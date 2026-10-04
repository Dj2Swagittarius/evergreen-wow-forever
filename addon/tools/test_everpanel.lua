-- EVERPANEL=1 mode of test_harness.lua: the bar, the plugin API, the menu and the screen offset.
local ns, fire, printed = ...

-- the buff module's /eb diag records every check without erroring (BUFFS=1 runs load it)
if SlashCmdList.EVERBUFF then
  SlashCmdList.EVERBUFF("diag")
  assert(EverbuffDB and EverbuffDB.diag and EverbuffDB.diag.apis and EverbuffDB.diag.units, "/eb diag saved nothing")
end
local EP = assert(ns.Everpanel, "everpanel module not loaded")
assert(EP.bar and EP.bar._shown, "bar not built")

-- plugins the addon ships (grown by later tasks)
local EXPECT = { "clock", "perf", "location", "bags", "durability", "ammo", "guide", "everbuff", "journal", "friends", "guild" }
for _, id in ipairs(EXPECT) do assert(EP.byId[id], "missing plugin " .. id) end
-- every plugin has a button and draws a string
for _, p in ipairs(EP.plugins) do
  assert(EP.buttons[p.id], p.id .. " has no button")
  if p.text then
    local ok, s = pcall(p.text)
    assert(ok, p.id .. " text() failed: " .. tostring(s))
    assert(type(s) == "string", p.id .. " text() returned " .. type(s))
  end
end

-- a plugin added after the bar exists: drawn, redrawn on its event and on its interval
local n = 0
EP.Add{ id = "test", label = "Test", side = "left", events = { "EVERPANEL_TEST" }, interval = 5,
  text = function() n = n + 1; return "t" .. n end }
local b = assert(EP.buttons.test, "Add after build did not make a button")
assert(b._shown, "test plugin hidden")
assert(b.text:GetText() == "t1", "first draw: " .. b.text:GetText())
fire("EVERPANEL_TEST")
assert(b.text:GetText() == "t2", "event redraw: " .. b.text:GetText())
EP.Tick(1000); EP.Tick(1001)
assert(b.text:GetText() == "t3", "interval redraw: " .. b.text:GetText())

-- a broken plugin shows ? and reports once
EP.Add{ id = "broken", text = function() error("boom") end }
EP.Update("broken"); EP.Update("broken")
local errs = 0
for _, m in ipairs(printed) do if m:find("plugin 'broken' error", 1, true) then errs = errs + 1 end end
assert(errs == 1, "broken plugin should report once, got " .. errs)
assert(EP.buttons.broken.text:GetText() == "?", "broken plugin should show ?")

-- right-click menu: hide, bring back, move sides
EP.OpenMenu(EP.bar, "test")
assert(EP.menu and EP.menu._shown, "menu did not open")
local function click(id, label)
  for _, e in ipairs(EP.MenuEntries(id)) do
    if e.func and e.text:find(label, 1, true) then e.func(); return end
  end
  error("no menu entry '" .. label .. "'")
end
click("test", "Hide")
assert(not EP.buttons.test._shown, "Hide did not hide the plugin")
EP.db.hidden.test = false; EP.Layout()
assert(EP.buttons.test._shown, "plugin did not come back")
click("test", "Move to right side")
assert(EP.db.order.right[#EP.db.order.right] == "test", "move to the right side failed")
click(nil, "Lock plugin order")
assert(EP.db.locked, "lock did not stick")
for _, e in ipairs(EP.MenuEntries("test")) do assert(not e.text:find("Move", 1, true), "locked menu still offers moves") end
click(nil, "Unlock plugin order")

-- top-anchored Blizzard frames move down under the bar, and back when it hides
local pf = CreateFrame("Frame", "PlayerFrame")
local pfPoint = { "TOPLEFT", nil, "TOPLEFT", 10, -4 }
pf.GetPoint = function() return pfPoint[1], pfPoint[2], pfPoint[3], pfPoint[4], pfPoint[5] end
pf.SetPoint = function(_, p, rel, rp, x, y) pfPoint = { p, rel, rp, x, y } end
EP.ApplyOffset()
assert(pfPoint[5] == -30, "PlayerFrame not pushed down: " .. tostring(pfPoint[5]))
EP.SetShown(false)
assert(not EP.bar._shown, "bar did not hide")
assert(pfPoint[5] == -4, "PlayerFrame not restored: " .. tostring(pfPoint[5]))
SlashCmdList.EVERGREEN("panel")
assert(EP.bar._shown, "/eg panel did not show the bar")

-- I4: a frame something else repositioned after the shift must not be snapped back
EP.ApplyOffset()
assert(pfPoint[5] == -30, "PlayerFrame not re-pushed down: " .. tostring(pfPoint[5]))
pfPoint = { "TOPLEFT", nil, "TOPLEFT", 10, -100 }   -- another addon/user repositioned it
EP.SetShown(false)
assert(pfPoint[5] == -100, "a moved frame should not be snapped back on hide")
SlashCmdList.EVERGREEN("panel")

-- I3: another bar addon on screen disables the offset entirely
local tf = CreateFrame("Frame", "TargetFrame")
local tfPoint = { "TOPLEFT", nil, "TOPLEFT", 0, -4 }
tf.GetPoint = function() return tfPoint[1], tfPoint[2], tfPoint[3], tfPoint[4], tfPoint[5] end
tf.SetPoint = function(_, p, rel, rp, x, y) tfPoint = { p, rel, rp, x, y } end
_G.TitanPanelBarButton = CreateFrame("Frame")
EP.ApplyOffset()
assert(tfPoint[5] == -4, "TargetFrame should not move when another bar addon is loaded")
_G.TitanPanelBarButton = nil
EP.ApplyOffset()
assert(tfPoint[5] == -30, "TargetFrame should shift once the other bar addon is gone")

-- clock click switches between local and server time
local was = EP.db.clockServer
EP.byId.clock.onClick("LeftButton")
assert(EP.db.clockServer == not was, "clock click did not toggle server time")

-- durability shows the lowest item
GetInventoryItemDurability = function(slot) if slot == 1 then return 30, 100 elseif slot == 5 then return 90, 100 end end
local dur = EP.byId.durability.text()
assert(dur == "30%", "durability text: " .. tostring(dur))
GetInventoryItemDurability = nil

assert(type(ns.GuideStepText) == "function", "Core does not expose GuideStepText")
assert(type(ns.EverbuffInfo) == "function", "Buffs does not expose EverbuffInfo")
assert(EP.Visible("journal"), "journal plugin should show when the journal module is on")

C_FriendList = { GetNumFriends = function() return 2 end,
  GetFriendInfoByIndex = function(i) return { name = "F" .. i, level = 20, area = "Barrens", connected = i == 1 } end }
assert(EP.byId.friends.text() == "1", "friends online: " .. tostring(EP.byId.friends.text()))
C_FriendList = nil
assert(not EP.Visible("guild"), "guild plugin should hide without a guild")

-- other addons' LibDataBroker plugins, only when switched on
local objs = { Fake = { type = "data source", text = "42", label = "Fake" } }
LibStub = function(name) if name == "LibDataBroker-1.1" then
  return { DataObjectIterator = function() return pairs(objs) end, RegisterCallback = function() end } end end
EP.db.ldb = false
assert(EP.ScanLDB, "no LDB bridge")
EP.ScanLDB()
assert(EP.buttons["ldb:Fake"], "LDB plugin not added")
assert(not EP.Visible("ldb:Fake"), "LDB plugin must stay hidden while switched off")
EP.db.ldb = true; EP.Update()
assert(EP.Visible("ldb:Fake") and EP.buttons["ldb:Fake"].text:GetText() == "42", "LDB plugin not shown")
LibStub = nil

io.write(string.format("OK everpanel: %d plugins, %d chat lines\n", #EP.plugins, #printed))
