-- EVERPANEL=1 mode of test_harness.lua: the bar, the plugin API, the menu and the screen offset.
local ns, fire, printed = ...
local EP = assert(ns.Everpanel, "everpanel module not loaded")
assert(EP.bar and EP.bar._shown, "bar not built")

-- plugins the addon ships (grown by later tasks)
local EXPECT = { "clock", "perf", "location", "bags" }
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
local placedY
pf.GetPoint = function() return "TOPLEFT", nil, "TOPLEFT", 10, -4 end
pf.SetPoint = function(_, _, _, _, _, y) placedY = y end
EP.ApplyOffset()
assert(placedY == -24, "PlayerFrame not pushed down: " .. tostring(placedY))
EP.SetShown(false)
assert(not EP.bar._shown, "bar did not hide")
assert(placedY == -4, "PlayerFrame not restored: " .. tostring(placedY))
SlashCmdList.EVERGREEN("panel")
assert(EP.bar._shown, "/eg panel did not show the bar")

-- clock click switches between local and server time
local was = EP.db.clockServer
EP.byId.clock.onClick("LeftButton")
assert(EP.db.clockServer == not was, "clock click did not toggle server time")

io.write(string.format("OK everpanel: %d plugins, %d chat lines\n", #EP.plugins, #printed))
