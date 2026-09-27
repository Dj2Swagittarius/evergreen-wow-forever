# Everpanel + XP/Gold Trackers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Everpanel (a Titan Panel–style plugin bar) and XP / Gold tracker modules to the Evergreen addon, with the trackers shown as Everpanel plugins plus a detailed pop-up panel.

**Architecture:** Three new Evergreen modules (`everpanel`, `xp`, `gold`) registered in `ns.MODULES`. `Modules/Everpanel.lua` owns the bar and a plugin registry (`ns.Everpanel.Add{...}`); plugin files under `Modules/Everpanel/` register at load time. `Modules/Tracker.lua` owns the session clock, rolling rates, pop-up panel and history; `Tracker_XP.lua` / `Tracker_Gold.lua` add sections and Everpanel plugins at `ADDON_LOADED`. Accounting logic lives in plain functions (`X.OnXP`, `G.OnMoney`, …) so the headless harness can drive it with a fake clock.

**Tech Stack:** WoW Lua 5.1 addon (WoW Forever 1.60 client, retail-based UI), LuaJIT headless harness `addon/tools/test_harness.lua`.

Spec: `docs/superpowers/specs/2026-09-26-everpanel-trackers-design.md`.

## Global Constraints

- Paths: addon source `addon/Evergreen/`; harness and tools `addon/tools/`; run tests from `addon/tools`.
- LuaJIT: `/c/Users/DJ/AppData/Local/Programs/LuaJIT/bin/luajit` (below: `$LJ`). Syntax check: `$LJ -bl <file> >/dev/null`.
- Beta deploy folder: `/e/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/Evergreen`. New files in the TOC need a full client restart, not `/reload`.
- Module gating: every module checks `ns.ModuleEnabled(id)` at `ADDON_LOADED`; ids `everpanel`, `xp`, `gold`.
- Frames use the shared skin: `ns.Skin.Panel`, `ns.Skin.Text`, `ns.Skin.Button`, `ns.Skin.Hud`, `ns.Skin.RowHighlight`; colours from `ns.Skin.HEX` (`gold`, `white`, `body`, `muted`, `green`, `red`, `violet`, `blue`).
- Call WoW APIs through globals at call time (`GetTime()`, `UnitXP(...)`), never cache them in file locals: the harness replaces them after load.
- Every API that may be missing on a client is guarded (`if X then ... end`, `x or 0`).
- Bar: height 20, top of screen, full width, strata `MEDIUM`.
- Rolling window 15 one-minute buckets; estimates use the recent rate once the session is ≥ 180 s and the recent rate > 0.
- History: last 20 sessions and per-level times in `EvergreenCharDB.tracker`.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Files use LF line endings (the repo's `.lua` files are LF in the working tree).

---

### Task 1: Everpanel core (bar, plugin API, menu, screen offset) + harness mode

**Files:**
- Create: `addon/Evergreen/Modules/Everpanel.lua`
- Create: `addon/tools/test_everpanel.lua`
- Modify: `addon/Evergreen/Modules.lua` (`ns.MODULES`, `wrapSlash`)
- Modify: `addon/Evergreen/Evergreen.toc` (append file)
- Modify: `addon/tools/test_harness.lua` (stubs, module switches, test-mode dispatch)

**Interfaces:**
- Produces:
  - `ns.Everpanel` (`EP`) table: `EP.Add(p)`, `EP.Update(id?)`, `EP.Layout()`, `EP.Visible(id) -> bool`, `EP.Tick(now?)`, `EP.OpenMenu(anchor, id?)`, `EP.MenuEntries(id?) -> {{text=, func=?}, ...}`, `EP.Move(id, "side" | -1 | 1)`, `EP.SetShown(bool)`, `EP.ApplyOffset()`, `EP.Slash(rest)`.
  - Fields: `EP.plugins` (array), `EP.byId`, `EP.buttons[id]` (Button with `.icon`, `.text`), `EP.bar`, `EP.menu`, `EP.db` (= `EvergreenDB.everpanel`), `EP.disabled`.
  - Plugin table: `{ id, label?, icon?, side? ("left"|"right", default right), text?() -> string, tooltip?(tt), onClick?(mouseButton), rightClick? (bool: plugin handles right-click itself), events? {names}, interval? seconds, hidden? (default hidden), visible?() -> bool }`.
  - Settings `EvergreenDB.everpanel`: `{ shown, locked, icons, labels, offset, ldb, clockServer, order = {left={}, right={}}, hidden = {[id]=true|false} }`.
  - Harness: `EVERPANEL=1` runs `test_everpanel.lua(ns, fire, printed)`; `TRACKER=1` runs `test_tracker.lua(ns, fire, printed)`; test files end with an `OK <name>` line and `os.exit(0)`.

- [ ] **Step 1: Harness support**

In `addon/tools/test_harness.lua`, inside `newFrame`'s `__index` function, add after the `Hide` line:

```lua
    if k == "SetShown" then return function(self, v) self._shown = v and true or false end end
```

After the `GetTime = function() return os.clock() end` line add:

```lua
time, date = os.time, os.date
```

Replace the `EvergreenDB = ...` line with:

```lua
local TRACK = os.getenv("TRACKER") ~= nil
EvergreenDB = { modules = { buffs = (os.getenv("BUFFS") ~= nil), move = false, reveal = false,
  everpanel = (os.getenv("EVERPANEL") ~= nil) or TRACK, xp = TRACK, gold = TRACK } }  -- guide (+ journal) always
```

After the `if os.getenv("JOURNAL") then ... end` block (before `-- the bot`), add:

```lua
-- EVERPANEL=1 / TRACKER=1: module tests in their own files, given the loaded addon
for _, mode in ipairs({ "EVERPANEL", "TRACKER" }) do
  if os.getenv(mode) then
    local here = arg[0]:match("^(.*[/\\])") or ""
    local run = assert(loadfile(here .. "test_" .. mode:lower() .. ".lua"))
    run(ns, fire, printed)
    os.exit(0)
  end
end
```

- [ ] **Step 2: Write the failing test** — create `addon/tools/test_everpanel.lua`:

```lua
-- EVERPANEL=1 mode of test_harness.lua: the bar, the plugin API, the menu and the screen offset.
local ns, fire, printed = ...
local EP = assert(ns.Everpanel, "everpanel module not loaded")
assert(EP.bar and EP.bar._shown, "bar not built")

-- plugins the addon ships (grown by later tasks)
local EXPECT = {}
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

io.write(string.format("OK everpanel: %d plugins, %d chat lines\n", #EP.plugins, #printed))
```

- [ ] **Step 3: Run it to see it fail**

Run (from `addon/tools`): `EVERPANEL=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN 2>&1 | tail -3`
Expected: FAIL — `everpanel module not loaded`.

- [ ] **Step 4: Register the module and slash command** — in `addon/Evergreen/Modules.lua`, add to `ns.MODULES` after the journal entry:

```lua
  { id = "everpanel", name = "Everpanel", slash = "/eg panel", desc = "Titan Panel-style info bar across the top of the screen" },
  { id = "xp",     name = "XP tracker",   slash = "/eg track", desc = "XP per hour, time to level, XP by source, time per level" },
  { id = "gold",   name = "Gold tracker", slash = "/eg track", desc = "Gold per hour, income and spending by source" },
```

In `wrapSlash`, before `elseif not ns.ModuleEnabled("guide") then`, add:

```lua
    elseif cmd == "panel" then
      if ns.Everpanel and not ns.Everpanel.disabled and ns.Everpanel.bar then ns.Everpanel.Slash(rest)
      else print(HEX.green .. "Evergreen:|r Everpanel module is off. /eg module everpanel on, then /reload.") end
    elseif cmd == "track" then
      if ns.Tracker and ns.Tracker.enabled then ns.Tracker.Slash(rest)
      else print(HEX.green .. "Evergreen:|r XP and gold trackers are off. /eg module xp on (or gold), then /reload.") end
```

Append to `addon/Evergreen/Evergreen.toc` (after `Modules\Journal_Map.lua`):

```
Modules\Everpanel.lua
```

- [ ] **Step 5: Implement** — create `addon/Evergreen/Modules/Everpanel.lua`:

```lua
-- Everpanel module: a Titan Panel-style bar across the top of the screen.
--
-- Plugins register with ns.Everpanel.Add{...} (Modules/Everpanel/*.lua, the XP and Gold trackers);
-- each shows an optional icon and label plus live text, a tooltip and click actions. Right-click
-- the bar for the menu. /eg panel toggles the bar. Settings: EvergreenDB.everpanel.

local ADDON, ns = ...
local HEX = ns.Skin.HEX
local BAR_H, GAP = 20, 12

local EP = { plugins = {}, byId = {}, buttons = {} }
ns.Everpanel = EP

local DEFAULTS = { shown = true, locked = false, icons = true, labels = false, offset = true, ldb = false,
  clockServer = false, order = { left = {}, right = {} }, hidden = {} }

local DB
local warned = {}
local function safe(id, fn, ...)
  local ok, r = pcall(fn, ...)
  if ok then return r end
  if not warned[id] then warned[id] = true; print(HEX.red .. "Everpanel:|r plugin '" .. id .. "' error: " .. tostring(r)) end
  return nil
end

local function InList(t, v) for i, x in ipairs(t) do if x == v then return i end end end
local function SideOf(id)
  if InList(DB.order.left, id) then return "left" end
  if InList(DB.order.right, id) then return "right" end
end

function EP.Visible(id)
  local p = EP.byId[id]
  if not p or DB.hidden[id] == true then return false end
  if p.visible then return safe(id, p.visible) and true or false end
  return true
end

local function Draw(id)
  local p, b = EP.byId[id], EP.buttons[id]
  if not (p and b) then return end
  local txt = ""
  if p.text then txt = safe(id, p.text); if txt == nil then txt = "?" end end
  local showIcon = DB.icons and p.icon ~= nil
  b.icon:SetShown(showIcon)
  b.text:ClearAllPoints()
  if showIcon then b.text:SetPoint("LEFT", b.icon, "RIGHT", 3, 0) else b.text:SetPoint("LEFT", b, "LEFT", 0, 0) end
  b.text:SetText(((DB.labels and p.label) and (HEX.gold .. p.label .. ":|r ") or "") .. tostring(txt))
  b:SetWidth(math.max(16, (b.text:GetStringWidth() or 0) + (showIcon and 17 or 0)))
end

-- right group from the right edge; left group from the left edge, hidden where it would overlap
function EP.Layout()
  if not EP.bar then return end
  local barW = EP.bar:GetWidth() or 0
  local x = -8
  for _, id in ipairs(DB.order.right) do
    local b = EP.buttons[id]
    if b then
      if EP.Visible(id) then
        b:ClearAllPoints(); b:SetPoint("RIGHT", EP.bar, "RIGHT", x, 0); b:Show()
        x = x - (b:GetWidth() or 0) - GAP
      else b:Hide() end
    end
  end
  local limit, lx = barW + x, 8
  for _, id in ipairs(DB.order.left) do
    local b = EP.buttons[id]
    if b then
      local w = b:GetWidth() or 0
      if EP.Visible(id) and (barW == 0 or lx + w <= limit) then
        b:ClearAllPoints(); b:SetPoint("LEFT", EP.bar, "LEFT", lx, 0); b:Show()
        lx = lx + w + GAP
      else b:Hide() end
    end
  end
end

function EP.Update(id)
  if not EP.bar then return end
  if id then Draw(id) else for pid in pairs(EP.buttons) do Draw(pid) end end
  EP.Layout()
end

-- plugin events: one frame, event -> set of plugin ids
local evFrame = CreateFrame("Frame")
local evMap = {}
evFrame:SetScript("OnEvent", function(_, ev)
  for id in pairs(evMap[ev] or {}) do Draw(id) end
  EP.Layout()
end)

local function MakeButton(p)
  local b = CreateFrame("Button", "EverpanelPlugin_" .. p.id:gsub("%W", "_"), EP.bar)
  b:SetHeight(BAR_H)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(14, 14); b.icon:SetPoint("LEFT", 0, 0)
  if p.icon then b.icon:SetTexture(p.icon) end
  b.text = ns.Skin.Text(b, "GameFontHighlightSmall"); b.text:SetJustifyV("MIDDLE"); b.text:SetWordWrap(false)
  b:SetScript("OnClick", function(s, btn)
    GameTooltip:Hide()
    if btn == "RightButton" and not p.rightClick then EP.OpenMenu(s, p.id); return end
    if p.onClick then safe(p.id, p.onClick, btn) end
    Draw(p.id); EP.Layout()
  end)
  b:SetScript("OnEnter", function(s)
    if not p.tooltip then return end
    GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
    GameTooltip:AddLine(p.label or p.id, 1, 0.82, 0)
    safe(p.id, p.tooltip, GameTooltip)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

function EP.Attach(p)
  if EP.buttons[p.id] then return end
  if not SideOf(p.id) then table.insert(DB.order[p.side == "left" and "left" or "right"], p.id) end
  if p.hidden and DB.hidden[p.id] == nil then DB.hidden[p.id] = true end
  EP.buttons[p.id] = MakeButton(p)
  for _, ev in ipairs(p.events or {}) do
    if not evMap[ev] then evMap[ev] = {}; pcall(evFrame.RegisterEvent, evFrame, ev) end
    evMap[ev][p.id] = true
  end
  Draw(p.id)
end

function EP.Add(p)
  assert(type(p) == "table" and p.id, "Everpanel.Add needs an id")
  if EP.byId[p.id] then return end
  EP.plugins[#EP.plugins + 1] = p
  EP.byId[p.id] = p
  if EP.bar then EP.Attach(p); EP.Layout() end
end

-- interval plugins; driven by a 0.5 s ticker
local nextAt = {}
function EP.Tick(now)
  now = now or GetTime()
  local any = false
  for _, p in ipairs(EP.plugins) do
    if p.interval and EP.buttons[p.id] and now >= (nextAt[p.id] or 0) then
      nextAt[p.id] = now + p.interval
      Draw(p.id); any = true
    end
  end
  if any then EP.Layout() end
end

-- ------------------------------------------------------------------ plugin order
function EP.Move(id, how)
  local side = SideOf(id)
  if not side then return end
  local list = DB.order[side]
  local i = InList(list, id)
  if how == "side" then
    table.remove(list, i)
    table.insert(DB.order[side == "left" and "right" or "left"], id)
  elseif list[i + how] then
    list[i], list[i + how] = list[i + how], list[i]
  end
  EP.Layout()
end

-- ------------------------------------------------------------------ right-click menu
-- Plain skinned buttons instead of UIDropDownMenu, which taints on retail-based clients.
function EP.MenuEntries(id)
  local e = {}
  local function add(text, func) e[#e + 1] = { text = text, func = func } end
  local function header(text) e[#e + 1] = { text = HEX.gold .. text .. "|r" } end
  local p = id and EP.byId[id]
  if p then
    header(p.label or p.id)
    add("Hide", function() DB.hidden[id] = true; EP.Layout() end)
    if not DB.locked then
      local side = SideOf(id)
      -- the right group is laid out from the right edge, so index order runs right to left there
      local leftStep = side == "left" and -1 or 1
      add(side == "left" and "Move to right side" or "Move to left side", function() EP.Move(id, "side") end)
      add("Move left", function() EP.Move(id, leftStep) end)
      add("Move right", function() EP.Move(id, -leftStep) end)
    end
  end
  header("Plugins")
  for _, q in ipairs(EP.plugins) do
    local qid, on = q.id, DB.hidden[q.id] ~= true
    add((on and (HEX.green .. "on |r ") or (HEX.muted .. "off|r ")) .. (q.label or qid), function() DB.hidden[qid] = on; EP.Update() end)
  end
  header("Bar")
  add((DB.icons and "Hide" or "Show") .. " icons", function() DB.icons = not DB.icons; EP.Update() end)
  add((DB.labels and "Hide" or "Show") .. " labels", function() DB.labels = not DB.labels; EP.Update() end)
  add((DB.locked and "Unlock" or "Lock") .. " plugin order", function() DB.locked = not DB.locked end)
  add((DB.offset and "Overlap" or "Push down") .. " Blizzard frames", function() DB.offset = not DB.offset; EP.ApplyOffset() end)
  add((DB.ldb and "Hide" or "Show") .. " other addons' plugins", function()
    DB.ldb = not DB.ldb
    if DB.ldb and EP.ScanLDB then EP.ScanLDB() end
    EP.Update()
  end)
  add("Hide bar  (/eg panel shows it)", function() EP.SetShown(false) end)
  return e
end

local menu
function EP.OpenMenu(anchor, id)
  if not menu then
    menu = CreateFrame("Frame", "EverpanelMenu", UIParent, "BackdropTemplate")
    ns.Skin.Hud(menu)
    menu:SetFrameStrata("DIALOG")
    menu:EnableMouse(true)
    menu.rows = {}
    tinsert(UISpecialFrames, "EverpanelMenu")
    EP.menu = menu
  end
  local entries = EP.MenuEntries(id)
  for i, e in ipairs(entries) do
    local r = menu.rows[i]
    if not r then
      r = CreateFrame("Button", nil, menu)
      r:SetSize(190, 16)
      r.text = ns.Skin.Text(r, "GameFontHighlightSmall"); r.text:SetPoint("LEFT", 6, 0)
      ns.Skin.RowHighlight(r)
      menu.rows[i] = r
    end
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4 - (i - 1) * 16)
    r.text:SetText(e.text)
    r:SetScript("OnClick", e.func and function() menu:Hide(); e.func() end or nil)
    r:Show()
  end
  for i = #entries + 1, #menu.rows do menu.rows[i]:Hide() end
  menu:SetSize(198, #entries * 16 + 8)
  menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  menu:Show()
end

-- ------------------------------------------------------------------ screen offset
-- Top-anchored Blizzard frames move down by the bar height so the bar covers nothing. Only out of
-- combat; re-applied after loading screens (Blizzard may re-anchor them).
local SHIFT = { "MinimapCluster", "BuffFrame", "PlayerFrame", "TargetFrame" }
local shifted, pendingOffset = {}, false
function EP.ApplyOffset()
  if not DB then return end
  if InCombatLockdown() then pendingOffset = true; return end
  pendingOffset = false
  local want = DB.shown and DB.offset
  for _, name in ipairs(SHIFT) do
    local f = _G[name]
    if f and f.GetPoint then
      local p, rel, rp, x, y = f:GetPoint(1)
      local s = shifted[f]
      if want then
        -- not shifted yet, or Blizzard put it back where it was
        if p and p:match("^TOP") and (rel == nil or rel == UIParent) and (not s or math.abs((y or 0) - s[4]) < 0.5) then
          shifted[f] = s or { p, rp, x, y or 0 }
          local o = shifted[f]
          f:ClearAllPoints(); f:SetPoint(o[1], UIParent, o[2], o[3], o[4] - BAR_H)
        end
      elseif s then
        shifted[f] = nil
        f:ClearAllPoints(); f:SetPoint(s[1], UIParent, s[2], s[3], s[4])
      end
    end
  end
end

function EP.SetShown(on)
  DB.shown = on and true or false
  if EP.bar then EP.bar:SetShown(DB.shown) end
  EP.ApplyOffset()
  if DB.shown then EP.Update() end
end

function EP.Slash(rest)
  EP.SetShown(not DB.shown)
  print(HEX.green .. "Evergreen:|r Everpanel " .. (DB.shown and "shown" or "hidden (/eg panel shows it)") .. ".")
end

-- ------------------------------------------------------------------ boot
local function Build()
  local bar = CreateFrame("Frame", "EverpanelBar", UIParent, "BackdropTemplate")
  ns.Skin.Hud(bar)
  bar:SetHeight(BAR_H)
  bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
  bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
  bar:SetFrameStrata("MEDIUM")
  bar:EnableMouse(true)
  bar:SetScript("OnMouseUp", function(s, btn) if btn == "RightButton" then EP.OpenMenu(s, nil) end end)
  bar:SetScript("OnSizeChanged", function() EP.Layout() end)
  EP.bar = bar
  for _, p in ipairs(EP.plugins) do EP.Attach(p) end
  bar:SetShown(DB.shown)
  EP.Layout()
  C_Timer.NewTicker(0.5, function() if bar:IsShown() then EP.Tick() end end)
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:RegisterEvent("PLAYER_REGEN_ENABLED")
boot:RegisterEvent("UI_SCALE_CHANGED")
boot:SetScript("OnEvent", function(self, event, name)
  if event == "ADDON_LOADED" then
    if name ~= ADDON then return end
    if not ns.ModuleEnabled("everpanel") then EP.disabled = true; self:UnregisterAllEvents(); return end
    EvergreenDB.everpanel = EvergreenDB.everpanel or {}
    DB = EvergreenDB.everpanel
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = type(v) == "table" and CopyTable(v) or v end end
    EP.db = DB
    Build()
  elseif not DB then
    return
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pendingOffset then EP.ApplyOffset() end
  else
    if event == "PLAYER_ENTERING_WORLD" and DB.ldb and EP.ScanLDB then EP.ScanLDB() end
    EP.ApplyOffset()
    EP.Update()
  end
end)
```

- [ ] **Step 6: Run the test**

Run: `EVERPANEL=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN 2>&1 | grep -E "^OK|rror"`
Expected: `OK everpanel: 2 plugins, ...` (the `test` and `broken` plugins).
Also run `BUFFS=1 JOURNAL=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN | grep ^OK` → `OK journal: ...`, and one route: `MISSED=1 $LJ test_harness.lua ../Evergreen Scourge PRIEST auto 30 | grep ^OK`.

- [ ] **Step 7: Commit**

```bash
git add addon/Evergreen/Modules/Everpanel.lua addon/Evergreen/Modules.lua addon/Evergreen/Evergreen.toc addon/tools/test_harness.lua addon/tools/test_everpanel.lua
git commit -m "Everpanel: plugin bar core, menu and screen offset"
```

---

### Task 2: Basics plugins (clock, performance, location, bags)

**Files:**
- Create: `addon/Evergreen/Modules/Everpanel/Basics.lua`
- Modify: `addon/Evergreen/Evergreen.toc`, `addon/tools/test_everpanel.lua`

**Interfaces:**
- Consumes: `EP.Add`, `EP.db.clockServer`.
- Produces: plugin ids `clock`, `perf`, `location`, `bags`.

- [ ] **Step 1: Failing test** — in `test_everpanel.lua` change the EXPECT line to:

```lua
local EXPECT = { "clock", "perf", "location", "bags" }
```

and add before the final `io.write` line:

```lua
-- clock click switches between local and server time
local was = EP.db.clockServer
EP.byId.clock.onClick("LeftButton")
assert(EP.db.clockServer == not was, "clock click did not toggle server time")
```

Run: `EVERPANEL=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN 2>&1 | tail -2` → FAIL `missing plugin clock`.

- [ ] **Step 2: Implement** — create `addon/Evergreen/Modules/Everpanel/Basics.lua`:

```lua
-- Everpanel plugins: clock, performance, location, bag space.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

local function ServerTime()
  if GetGameTime then
    local h, m = GetGameTime()
    if h then return string.format("%02d:%02d", h, m) end
  end
  return "--:--"
end
local function LocalTime() return date("%H:%M") end

EP.Add{ id = "clock", label = "Clock", side = "right", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", interval = 1,
  text = function() return (EP.db and EP.db.clockServer) and ServerTime() or LocalTime() end,
  tooltip = function(tt)
    tt:AddDoubleLine("Local time", LocalTime(), 0.9, 0.9, 0.9, 1, 1, 1)
    tt:AddDoubleLine("Server time", ServerTime(), 0.9, 0.9, 0.9, 1, 1, 1)
    tt:AddLine("Click: show " .. ((EP.db and EP.db.clockServer) and "local" or "server") .. " time on the bar", 0.6, 0.6, 0.6)
  end,
  onClick = function() if EP.db then EP.db.clockServer = not EP.db.clockServer end end,
}

local function Latency()
  if not GetNetStats then return 0, 0 end
  local _, _, home, world = GetNetStats()
  return home or 0, world or 0
end
EP.Add{ id = "perf", label = "Performance", side = "right", icon = "Interface\\Icons\\Trade_Engineering", interval = 2,
  text = function()
    local fps = (GetFramerate and GetFramerate()) or 0
    local home, world = Latency()
    return string.format("%dfps %dms", math.floor(fps + 0.5), math.max(home, world))
  end,
  tooltip = function(tt)
    local home, world = Latency()
    tt:AddDoubleLine("Home latency", home .. " ms", 0.9, 0.9, 0.9, 1, 1, 1)
    tt:AddDoubleLine("World latency", world .. " ms", 0.9, 0.9, 0.9, 1, 1, 1)
  end,
}

local function Coords()
  local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return nil end
  local x, y = pos:GetXY()
  if not x or (x == 0 and y == 0) then return nil end
  return x * 100, y * 100
end
EP.Add{ id = "location", label = "Location", side = "left", icon = "Interface\\Icons\\INV_Misc_Map_01", interval = 0.5,
  events = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" },
  text = function()
    local zone = (GetZoneText and GetZoneText()) or ""
    local x, y = Coords()
    return x and string.format("%s %.1f, %.1f", zone, x, y) or zone
  end,
  tooltip = function(tt)
    tt:AddLine((GetZoneText and GetZoneText()) or "", 1, 1, 1)
    local sub = GetSubZoneText and GetSubZoneText()
    if sub and sub ~= "" then tt:AddLine(sub, 0.9, 0.9, 0.9) end
    tt:AddLine("Click: world map", 0.6, 0.6, 0.6)
  end,
  onClick = function() if ToggleWorldMap then ToggleWorldMap() end end,
}

local function BagSlots(bag)
  local C = C_Container
  local free = (C and C.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
  local total = (C and C.GetContainerNumSlots) or GetContainerNumSlots
  if not (free and total) then return 0, 0 end
  return free(bag) or 0, total(bag) or 0
end
EP.Add{ id = "bags", label = "Bags", side = "right", icon = "Interface\\Icons\\INV_Misc_Bag_08",
  events = { "BAG_UPDATE", "PLAYER_ENTERING_WORLD" },
  text = function()
    local f, t = 0, 0
    for bag = 0, 4 do local a, b = BagSlots(bag); f, t = f + a, t + b end
    return f .. "/" .. t
  end,
  tooltip = function(tt)
    for bag = 0, 4 do
      local a, b = BagSlots(bag)
      if b > 0 then tt:AddDoubleLine(bag == 0 and "Backpack" or ("Bag " .. bag), a .. " free of " .. b, 0.9, 0.9, 0.9, 1, 1, 1) end
    end
    tt:AddLine("Click: open bags", 0.6, 0.6, 0.6)
  end,
  onClick = function() if ToggleAllBags then ToggleAllBags() end end,
}
```

Append to `Evergreen.toc`: `Modules\Everpanel\Basics.lua`

- [ ] **Step 3: Run the test** → `OK everpanel: 6 plugins, ...`
- [ ] **Step 4: Commit** — `git add addon/Evergreen/Modules/Everpanel/Basics.lua addon/Evergreen/Evergreen.toc addon/tools/test_everpanel.lua` and commit `"Everpanel: clock, performance, location and bag plugins"`.

---

### Task 3: Tracker core (rates, formatting, panel, history)

**Files:**
- Create: `addon/Evergreen/Modules/Tracker.lua`
- Create: `addon/tools/test_tracker.lua`
- Modify: `addon/Evergreen/Evergreen.toc`

**Interfaces:**
- Produces `ns.Tracker` (`T`):
  - `T.NewStat() -> {total=0, buckets={}}`, `T.Add(stat, amount, now?)`, `T.Elapsed(now?)`, `T.SessionRate(stat, now?)`, `T.RecentRate(stat, now?)`, `T.BestRate(stat, now?)` — rates per hour.
  - `T.FmtNum(n)`, `T.FmtTime(seconds)`, `T.FmtMoney(copper, short?, signed?)`.
  - `T.AddSection{ id, title, lines() -> {string}, reset?(), summary?() -> table }`.
  - `T.Reset()`, `T.SaveSession()`, `T.History() -> EvergreenCharDB.tracker` (`{sessions={...}, levelTimes={}}`), `T.Refresh()`, `T.Toggle()`, `T.Slash(rest)`.
  - Fields: `T.enabled`, `T.panel` (frame with `.body` FontString), `T.session = {start=, date=}`, `T.showHistory`, `T.db` (= `EvergreenDB.tracker`).

- [ ] **Step 1: Failing test** — create `addon/tools/test_tracker.lua`:

```lua
-- TRACKER=1 mode of test_harness.lua: tracker core, XP and gold accounting with a fake clock.
local ns, fire, printed = ...
local T = assert(ns.Tracker, "tracker module not loaded")
assert(T.enabled and T.panel, "tracker panel not built")
local function eq(a, b, what) assert(a == b, what .. ": expected " .. tostring(b) .. ", got " .. tostring(a)) end
local function near(a, b, what) assert(math.abs(a - b) < 0.01, what .. ": expected " .. b .. ", got " .. a) end

-- formatting
eq(T.FmtMoney(34205), "3g 42s 5c", "FmtMoney")
eq(T.FmtMoney(34205, true), "3g 42s", "FmtMoney short")
eq(T.FmtMoney(-3000, true), "-30s", "FmtMoney negative")
eq(T.FmtMoney(190, false, true), "+1s 90c", "FmtMoney signed")
eq(T.FmtNum(1240), "1,240", "FmtNum")
eq(T.FmtNum(24100), "24.1k", "FmtNum k")
eq(T.FmtTime(14 * 60 + 5), "14m", "FmtTime minutes")
eq(T.FmtTime(3900), "1h 05m", "FmtTime hours")

-- rates with a fake clock
local now = 1000
GetTime = function() return now end
T.Reset()
local s = T.NewStat()
T.Add(s, 600); now = now + 600          -- 600 in the first 10 minutes
near(T.SessionRate(s), 3600, "session rate")
near(T.RecentRate(s), 3600, "recent rate")
now = now + 20 * 60                     -- 20 quiet minutes: recent window empties
eq(T.RecentRate(s), 0, "recent rate after a break")
near(T.BestRate(s), T.SessionRate(s), "best rate falls back to the session rate")

-- the panel opens from /eg track
SlashCmdList.EVERGREEN("track")
assert(T.panel._shown, "/eg track did not open the panel")

-- (XP and gold checks are added by Tasks 4 and 5 here)

io.write(string.format("OK tracker: %d sections, %d chat lines\n", #T.sections, #printed))
```

Run: `TRACKER=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN 2>&1 | tail -2` → FAIL `tracker module not loaded`.

- [ ] **Step 2: Implement** — create `addon/Evergreen/Modules/Tracker.lua`:

```lua
-- Tracker core: session clock, rolling rates, the pop-up panel and per-character history for the
-- XP and Gold trackers (Tracker_XP.lua, Tracker_Gold.lua). /eg track toggles the panel,
-- /eg track reset starts a new session, /eg track history shows past sessions and level times.

local ADDON, ns = ...
local HEX = ns.Skin.HEX
local WINDOW = 15          -- minutes in the rolling window
local MIN_RECENT = 180     -- seconds of session before estimates trust the recent rate
local MAX_SESSIONS = 20

local T = { sections = {} }
ns.Tracker = T
T.session = { start = GetTime(), date = time and time() or 0 }

local CDB

-- ------------------------------------------------------------------ formatting
function T.FmtNum(n)
  n = n or 0
  local sign, a = n < 0 and "-" or "", math.abs(n)
  if a >= 1e6 then return string.format("%s%.1fm", sign, a / 1e6) end
  if a >= 1e4 then return string.format("%s%.1fk", sign, a / 1e3) end
  if a >= 1e3 then return string.format("%s%d,%03d", sign, math.floor(a / 1e3), math.floor(a % 1e3)) end
  return sign .. math.floor(a + 0.5)
end

function T.FmtTime(sec)
  if not sec or sec ~= sec or sec == math.huge or sec < 0 then return "—" end
  sec = math.floor(sec + 0.5)
  if sec < 60 then return sec .. "s" end
  if sec < 3600 then return math.floor(sec / 60) .. "m" end
  local h = math.floor(sec / 3600)
  if h >= 48 then return math.floor(h / 24) .. "d" end
  return string.format("%dh %02dm", h, math.floor(sec % 3600 / 60))
end

function T.FmtMoney(c, short, signed)
  c = math.floor((c or 0) + 0.5)
  local sign = c < 0 and "-" or (signed and c > 0 and "+" or "")
  c = math.abs(c)
  local g, s, k = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
  local out
  if g > 0 then out = T.FmtNum(g) .. "g " .. s .. "s" .. (short and "" or (" " .. k .. "c"))
  elseif s > 0 then out = s .. "s" .. (short and "" or (" " .. k .. "c"))
  else out = k .. "c" end
  return sign .. out
end

-- ------------------------------------------------------------------ stats and rates
function T.Elapsed(now) return math.max(0, (now or GetTime()) - T.session.start) end
function T.NewStat() return { total = 0, buckets = {} } end

function T.Add(stat, amount, now)
  now = now or GetTime()
  stat.total = stat.total + amount
  local m = math.floor(now / 60)
  stat.buckets[m] = (stat.buckets[m] or 0) + amount
  for k in pairs(stat.buckets) do if k <= m - WINDOW then stat.buckets[k] = nil end end
end

function T.SessionRate(stat, now)
  local el = T.Elapsed(now)
  if el < 1 then return 0 end
  return stat.total / el * 3600
end

function T.RecentRate(stat, now)
  now = now or GetTime()
  local m, sum = math.floor(now / 60), 0
  for k, v in pairs(stat.buckets) do if k > m - WINDOW then sum = sum + v end end
  local minutes = math.min(WINDOW, math.max(1, T.Elapsed(now) / 60))
  return sum / minutes * 60
end

function T.BestRate(stat, now)
  local r = T.RecentRate(stat, now)
  if T.Elapsed(now) >= MIN_RECENT and r > 0 then return r end
  return T.SessionRate(stat, now)
end

-- ------------------------------------------------------------------ sections and history
function T.AddSection(s)
  T.sections[#T.sections + 1] = s
  T.Refresh()
end

function T.History() return CDB end

function T.SaveSession()
  if not CDB or T.Elapsed() < 60 then return end
  local e = { date = T.session.date, seconds = math.floor(T.Elapsed()) }
  for _, s in ipairs(T.sections) do
    if s.summary then for k, v in pairs(s.summary()) do e[k] = v end end
  end
  table.insert(CDB.sessions, 1, e)
  while #CDB.sessions > MAX_SESSIONS do table.remove(CDB.sessions) end
end

function T.Reset()
  T.SaveSession()
  T.session = { start = GetTime(), date = time and time() or 0 }
  for _, s in ipairs(T.sections) do if s.reset then s.reset() end end
  T.Refresh()
end

local function HistoryLines()
  local L = { HEX.gold .. "Sessions|r" }
  for i, e in ipairs(CDB and CDB.sessions or {}) do
    if i > 10 then break end
    L[#L + 1] = string.format("  %s  %s  %s xp  %s%s", date and date("%m-%d %H:%M", e.date) or "", T.FmtTime(e.seconds),
      T.FmtNum(e.xp or 0), T.FmtMoney(e.money or 0, true, true), (e.levels or 0) > 0 and ("  +" .. e.levels .. " lvl") or "")
  end
  if #L == 1 then L[2] = HEX.muted .. "  none yet|r" end
  L[#L + 1] = HEX.gold .. "Time per level|r"
  local lv = {}
  for k in pairs(CDB and CDB.levelTimes or {}) do lv[#lv + 1] = k end
  table.sort(lv, function(a, b) return a > b end)
  for i, k in ipairs(lv) do
    if i > 12 then break end
    L[#L + 1] = string.format("  level %d  %s", k, T.FmtTime(CDB.levelTimes[k]))
  end
  if #lv == 0 then L[#L + 1] = HEX.muted .. "  recorded from your next level-up|r" end
  return L
end

function T.Lines()
  if T.showHistory then return HistoryLines() end
  local L = {}
  for _, s in ipairs(T.sections) do
    L[#L + 1] = HEX.gold .. s.title .. "|r"
    local ok, ls = pcall(s.lines)
    for _, l in ipairs(ok and ls or { HEX.red .. "error: " .. tostring(ls) .. "|r" }) do L[#L + 1] = "  " .. l end
    L[#L + 1] = " "
  end
  L[#L + 1] = HEX.muted .. "session " .. T.FmtTime(T.Elapsed()) .. "|r"
  return L
end

-- ------------------------------------------------------------------ panel
function T.Refresh()
  local f = T.panel
  if not f then return end
  f.body:SetText(table.concat(T.Lines(), "\n"))
  f.hist:SetLabel(T.showHistory and "Back" or "History")
  f:SetHeight(math.max(120, (f.body:GetStringHeight() or 0) + 76))
end

local function Build()
  local f = ns.Skin.Panel("EvergreenTrackerFrame", 340, 200, "Evergreen Tracker")
  f:SetParent(UIParent)
  f:SetPoint("CENTER", UIParent, "CENTER", 300, 150)
  f:SetFrameStrata("MEDIUM")
  f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(s) s:StartMoving() end)
  f:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    local p, _, rp, x, y = s:GetPoint(1)
    T.db.pos = { p, rp, x, y }
  end)
  if T.db.pos then f:ClearAllPoints(); f:SetPoint(T.db.pos[1], UIParent, T.db.pos[2], T.db.pos[3], T.db.pos[4]) end
  if f.CloseButton then f.CloseButton:SetScript("OnClick", function() f:Hide() end) end
  f.body = ns.Skin.Text(f, "GameFontHighlightSmall")
  f.body:SetPoint("TOPLEFT", 14, -30); f.body:SetPoint("RIGHT", -14, 0)
  f.body:SetSpacing(3)
  f.reset = ns.Skin.Button(f, "Reset", 80, 22); f.reset:SetPoint("BOTTOMLEFT", 12, 10)
  f.reset:SetScript("OnClick", function() T.Reset() end)
  f.hist = ns.Skin.Button(f, "History", 80, 22); f.hist:SetPoint("LEFT", f.reset, "RIGHT", 6, 0)
  f.hist:SetScript("OnClick", function() T.showHistory = not T.showHistory; T.Refresh() end)
  f:SetScript("OnShow", function() T.Refresh() end)
  f:Hide()
  T.panel = f
  C_Timer.NewTicker(1, function() if f:IsShown() then T.Refresh() end end)
end

function T.Slash(rest)
  rest = rest or ""
  if rest == "reset" then T.Reset(); print(HEX.green .. "Evergreen:|r tracker session reset."); return end
  if rest == "history" then T.showHistory = true; T.panel:Show(); T.Refresh(); return end
  T.showHistory = false
  T.panel:SetShown(not T.panel:IsShown())
end
function T.Toggle() T.Slash("") end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGOUT")
boot:SetScript("OnEvent", function(self, event, name)
  if event == "ADDON_LOADED" then
    if name ~= ADDON then return end
    T.enabled = ns.ModuleEnabled("xp") or ns.ModuleEnabled("gold")
    if not T.enabled then self:UnregisterAllEvents(); return end
    EvergreenDB.tracker = EvergreenDB.tracker or {}
    T.db = EvergreenDB.tracker
    EvergreenCharDB = EvergreenCharDB or {}
    EvergreenCharDB.tracker = EvergreenCharDB.tracker or { sessions = {}, levelTimes = {} }
    CDB = EvergreenCharDB.tracker
    Build()
  elseif event == "PLAYER_LOGOUT" then
    T.SaveSession()
  end
end)
```

Append to `Evergreen.toc`: `Modules\Tracker.lua`

- [ ] **Step 3: Run the test** → `OK tracker: 0 sections, ...`. Re-run the Everpanel and journal tests (both still `OK`).
- [ ] **Step 4: Commit** — `git add addon/Evergreen/Modules/Tracker.lua addon/Evergreen/Evergreen.toc addon/tools/test_tracker.lua`, commit `"Tracker core: session, rolling rates, panel, history"`.

---

### Task 4: XP tracker

**Files:**
- Create: `addon/Evergreen/Modules/Tracker_XP.lua`
- Modify: `addon/Evergreen/Evergreen.toc`, `addon/tools/test_tracker.lua`

**Interfaces:**
- Consumes: `T.NewStat`, `T.Add`, `T.SessionRate`, `T.RecentRate`, `T.BestRate`, `T.Fmt*`, `T.AddSection`, `T.History`, `T.Toggle`, `T.Refresh`; `ns.Everpanel.Add`.
- Produces `T.XP` (`X`): `X.KILL` (Lua pattern), `X.Reset()`, `X.Snapshot()`, `X.OnXP(xp, max, level) -> delta`, `X.OnChat(msg)`, `X.OnQuest(xp)`, `X.OnPlayed(total, thisLevel)`, `X.RequestPlayed()`, `X.AtMax()`, `X.Lines()`, `X.BarText()`; fields `X.stat, X.kills, X.killXP, X.quests, X.questXP, X.levels`. Everpanel plugin id `xp`; section summary keys `xp`, `levels`.

- [ ] **Step 1: Failing test** — in `test_tracker.lua` replace the line `-- (XP and gold checks are added by Tasks 4 and 5 here)` with:

```lua
-- ---------------------------------------------------------------- XP
local X = assert(T.XP, "XP tracker not loaded")
local xp, max, level = 100, 1000, 10
UnitXP = function() return xp end
UnitXPMax = function() return max end
UnitLevel = function() return level end
GetXPExhaustion = function() return 300 end
RequestTimePlayed = function() end
now = 5000; T.Reset(); X.Snapshot()

local _, amt = ("Gnoll dies, you gain 120 experience."):match(X.KILL)
eq(amt, "120", "kill pattern")
_, amt = ("Gnoll dies, you gain 180 experience. (+60 exp Rested bonus)"):match(X.KILL)
eq(amt, "180", "kill pattern with rested bonus")

for _ = 1, 3 do                           -- three kills of 100, a minute apart
  now = now + 60
  fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold dies, you gain 100 experience.")
  xp = xp + 100; fire("PLAYER_XP_UPDATE", "player")
end
eq(X.kills, 3, "kills"); eq(X.killXP, 300, "kill xp"); eq(X.stat.total, 300, "xp total")
now = now + 30
fire("QUEST_TURNED_IN", 123, 250, 0)      -- 250 xp, no money (gold is checked in Task 5)
xp = xp + 250; fire("PLAYER_XP_UPDATE", "player")
eq(X.questXP, 250, "quest xp")
now = now + 70                            -- level-up: 350 finishes level 10, 40 into level 11
level, xp, max = 11, 40, 1200
fire("PLAYER_XP_UPDATE", "player")
eq(X.stat.total, 300 + 250 + 350 + 40, "xp across a level-up")
near(T.SessionRate(X.stat), 940 / 280 * 3600, "xp per hour")

-- time per level from /played
X.RequestPlayed(); fire("TIME_PLAYED_MSG", 5000, 1200)   -- level 10 began at 3800 s played
fire("PLAYER_LEVEL_UP", 11); fire("TIME_PLAYED_MSG", 6000, 5)
eq(T.History().levelTimes[10], 2195, "time spent at level 10")
eq(X.levels, 1, "levels gained")

for _, l in ipairs(X.Lines()) do assert(type(l) == "string", "XP line not a string") end
assert(ns.Everpanel.byId.xp, "no XP plugin on Everpanel")
assert(type(ns.Everpanel.byId.xp.text()) == "string", "XP plugin text")

-- (gold checks are added by Task 5 here)
```

Run → FAIL `XP tracker not loaded`.

- [ ] **Step 2: Implement** — create `addon/Evergreen/Modules/Tracker_XP.lua`:

```lua
-- XP tracker: XP per hour (session and last 15 minutes), time to level, XP by source (kills,
-- quests, other), kills / quests to level, rested XP, and how long each level took.

local ADDON, ns = ...
local T = ns.Tracker
local HEX = ns.Skin.HEX

local X = {}
T.XP = X

-- "%s dies, you gain %d experience." -> a Lua pattern capturing (name, amount)
local function KillPattern(fmt)
  local p = (fmt or "%s dies, you gain %d experience."):gsub("%%s", "\1"):gsub("%%d", "\2")
  p = p:gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
  p = p:gsub("\1", "(.+)"):gsub("\2", "(%%d+)")
  return "^" .. p
end
X.KILL = KillPattern(COMBATLOG_XPGAIN_FIRSTPERSON)

function X.Reset()
  X.stat = T.NewStat()
  X.kills, X.killXP, X.quests, X.questXP, X.levels = 0, 0, 0, 0, 0
end
X.Reset()

function X.Snapshot()
  X.lastXP, X.lastMax, X.lastLevel = UnitXP("player") or 0, UnitXPMax("player") or 0, UnitLevel("player") or 0
end

-- XP gained since the last update. A level-up wraps the bar: the rest of the old level plus the new
-- XP. The bar never shrinks otherwise, so a smaller value also means a level-up (event order varies).
function X.OnXP(xp, max, level)
  local delta
  if X.lastXP and ((X.lastLevel and level > X.lastLevel) or xp < X.lastXP) then
    delta = (X.lastMax - X.lastXP) + xp
  else
    delta = xp - (X.lastXP or xp)
  end
  X.lastXP, X.lastMax, X.lastLevel = xp, max, level
  if delta > 0 then T.Add(X.stat, delta) end
  return delta
end

function X.OnChat(msg)
  local _, amount = (msg or ""):match(X.KILL)
  amount = tonumber(amount)
  if amount then X.kills = X.kills + 1; X.killXP = X.killXP + amount end
end

function X.OnQuest(xp)
  xp = tonumber(xp) or 0
  if xp > 0 then X.quests = X.quests + 1; X.questXP = X.questXP + xp end
end

-- Time per level: /played reports total and this-level seconds, so total - thisLevel is the played
-- time when the current level began. Ask at login and after each level-up; the chat print is muted.
local awaiting, levelStart
function X.RequestPlayed()
  if not RequestTimePlayed then return end
  awaiting = true
  if ChatFrame_DisplayTimePlayed and not X.origDisplay then
    X.origDisplay = ChatFrame_DisplayTimePlayed
    ChatFrame_DisplayTimePlayed = function() end
  end
  RequestTimePlayed()
end

function X.OnPlayed(total, thisLevel)
  if not awaiting then return end
  awaiting = false
  if X.origDisplay then ChatFrame_DisplayTimePlayed = X.origDisplay; X.origDisplay = nil end
  local started = (total or 0) - (thisLevel or 0)
  local H = T.History()
  if H and levelStart and X.pendingLevel and started > levelStart then
    H.levelTimes[X.pendingLevel] = started - levelStart
  end
  levelStart, X.pendingLevel = started, nil
end

local function MaxLevel() return (GetMaxPlayerLevel and GetMaxPlayerLevel()) or MAX_PLAYER_LEVEL or 60 end
function X.AtMax() return (UnitLevel("player") or 0) >= MaxLevel() end

local function ToGo() return math.max(0, (UnitXPMax("player") or 0) - (UnitXP("player") or 0)) end
local function pct(a, t) return t > 0 and math.floor(a / t * 100 + 0.5) or 0 end

function X.Lines()
  if X.AtMax() then return { HEX.muted .. "max level|r" } end
  local xp, max, toGo = UnitXP("player") or 0, UnitXPMax("player") or 0, ToGo()
  local rested = GetXPExhaustion and GetXPExhaustion()
  local L = {}
  L[1] = T.FmtNum(xp) .. " / " .. T.FmtNum(max) .. HEX.muted .. "  (" .. T.FmtNum(toGo) .. " to go)|r"
    .. ((rested and rested > 0) and (HEX.blue .. "  rested " .. T.FmtNum(rested) .. "|r") or "")
  L[2] = "per hour  session " .. T.FmtNum(T.SessionRate(X.stat)) .. "  ·  last 15m " .. T.FmtNum(T.RecentRate(X.stat))
  local rate = T.BestRate(X.stat)
  local s = "level in  " .. (rate > 0 and T.FmtTime(toGo / rate * 3600) or "—")
  if X.kills > 0 then s = s .. "  ·  ~" .. math.ceil(toGo / (X.killXP / X.kills)) .. " kills" end
  if X.quests > 0 then s = s .. "  ·  ~" .. math.ceil(toGo / (X.questXP / X.quests)) .. " quests" end
  L[3] = s
  local total = X.stat.total
  if total > 0 then
    local other = math.max(0, total - X.killXP - X.questXP)
    L[4] = string.format("sources  kills %d%%  quests %d%%  other %d%%", pct(X.killXP, total), pct(X.questXP, total), pct(other, total))
  end
  return L
end

function X.BarText()
  if X.AtMax() then return "max level" end
  local rate = T.BestRate(X.stat)
  return T.FmtNum(rate) .. "/h · " .. (rate > 0 and T.FmtTime(ToGo() / rate * 3600) or "—")
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, event, a1, a2)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    if not ns.ModuleEnabled("xp") then self:UnregisterAllEvents(); return end
    for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_XP_UPDATE", "CHAT_MSG_COMBAT_XP_GAIN", "QUEST_TURNED_IN",
                         "PLAYER_LEVEL_UP", "TIME_PLAYED_MSG" }) do
      pcall(self.RegisterEvent, self, e)
    end
    T.AddSection{ id = "xp", title = "Experience", lines = X.Lines, reset = X.Reset,
      summary = function() return { xp = X.stat.total, levels = X.levels } end }
    if ns.Everpanel then
      ns.Everpanel.Add{ id = "xp", label = "XP", side = "left", icon = "Interface\\Icons\\INV_Misc_Book_11",
        events = { "PLAYER_XP_UPDATE" }, interval = 5, text = X.BarText,
        visible = function() return not X.AtMax() end,
        tooltip = function(tt)
          for _, l in ipairs(X.Lines()) do tt:AddLine(l, 1, 1, 1) end
          tt:AddLine("Click: tracker panel", 0.6, 0.6, 0.6)
        end,
        onClick = function() T.Toggle() end }
    end
  elseif event == "PLAYER_LOGIN" then
    X.Snapshot(); X.RequestPlayed()
  elseif event == "PLAYER_XP_UPDATE" then
    X.OnXP(UnitXP("player") or 0, UnitXPMax("player") or 0, UnitLevel("player") or 0)
    T.Refresh()
  elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
    X.OnChat(a1)
  elseif event == "QUEST_TURNED_IN" then
    X.OnQuest(a2)
  elseif event == "PLAYER_LEVEL_UP" then
    X.levels = X.levels + 1
    X.pendingLevel = (tonumber(a1) or UnitLevel("player") or 1) - 1
    X.RequestPlayed()
  elseif event == "TIME_PLAYED_MSG" then
    X.OnPlayed(a1, a2)
  end
end)
```

Append to `Evergreen.toc`: `Modules\Tracker_XP.lua`

- [ ] **Step 3: Run the test** → `OK tracker: 1 sections, ...`; Everpanel/journal tests still `OK`.
- [ ] **Step 4: Commit** — `"XP tracker: rates, time to level, sources, time per level"`.

---

### Task 5: Gold tracker

**Files:**
- Create: `addon/Evergreen/Modules/Tracker_Gold.lua`
- Modify: `addon/Evergreen/Evergreen.toc`, `addon/tools/test_tracker.lua`

**Interfaces:**
- Consumes: Task 3 core; `ns.Everpanel.Add`.
- Produces `T.Gold` (`G`): `G.Reset()`, `G.Classify(delta, now?) -> category`, `G.OnMoney(money, now?) -> category|nil`, `G.OnLootChat(now?)`, `G.OnQuestMoney(amount, now?)`, `G.Lines()`, `G.BarText()`; fields `G.net` (stat), `G.inc` {loot, vendor, quests, auction, other}, `G.out` {repairs, training, purchases, auction, other}, `G.ctx` {merchant, trainer, mail, auction, repair, lootAt, questMoney}, `G.last`. Everpanel plugin id `gold`; summary key `money`.

- [ ] **Step 1: Failing test** — in `test_tracker.lua` replace `-- (gold checks are added by Task 5 here)` with:

```lua
-- ---------------------------------------------------------------- gold
local G = assert(T.Gold, "gold tracker not loaded")
local money = 50000
GetMoney = function() return money end
G.last = money
local net0 = G.net.total
fire("QUEST_TURNED_IN", 124, 0, 15000); money = money + 15000; fire("PLAYER_MONEY")   -- quest event first
now = now + 10
money = money + 523; fire("PLAYER_MONEY"); fire("CHAT_MSG_MONEY", "You loot 5 Silver, 23 Copper")  -- chat after
now = now + 10
money = money + 7000; fire("PLAYER_MONEY"); fire("QUEST_TURNED_IN", 125, 0, 7000)     -- quest event after
fire("MERCHANT_SHOW")
money = money + 2000; fire("PLAYER_MONEY")
G.ctx.repair = true                                   -- what the RepairAllItems hook sets
money = money - 700; fire("PLAYER_MONEY")
money = money - 300; fire("PLAYER_MONEY")
fire("MERCHANT_CLOSED")
money = money - 50; fire("PLAYER_MONEY")
eq(G.inc.quests, 22000, "quest money"); eq(G.inc.loot, 523, "loot"); eq(G.inc.vendor, 2000, "vendor")
eq(G.inc.other, 0, "nothing left in other income")
eq(G.out.repairs, 700, "repairs"); eq(G.out.purchases, 300, "purchases"); eq(G.out.other, 50, "other spending")
eq(G.net.total - net0, 22000 + 523 + 2000 - 700 - 300 - 50, "net money")
for _, l in ipairs(G.Lines()) do assert(type(l) == "string", "gold line not a string") end
assert(type(ns.Everpanel.byId.gold.text()) == "string", "gold plugin text")

-- ---------------------------------------------------------------- history and max level
now = now + 600
T.Reset()
local e = T.History().sessions[1]
assert(e, "session not saved on reset")
eq(e.xp, 940, "saved session xp"); eq(e.levels, 1, "saved session levels")
eq(e.money, 22000 + 523 + 2000 - 700 - 300 - 50 + net0, "saved session money")
eq(X.stat.total, 0, "xp reset"); eq(G.net.total, 0, "gold reset")
level = 60
assert(X.Lines()[1]:find("max level", 1, true), "max level line")
assert(not ns.Everpanel.Visible("xp"), "XP plugin should hide at max level")
T.showHistory = true; T.Refresh()
assert(T.panel.body:GetText():find("level 10", 1, true), "history shows level times")
```

Run → FAIL `gold tracker not loaded`.

- [ ] **Step 2: Implement** — create `addon/Evergreen/Modules/Tracker_Gold.lua`:

```lua
-- Gold tracker: net gold per hour (session and last 15 minutes), income by source (loot, vendor,
-- quests, auction, other) and spending (repairs, training, purchases, auction, other).
-- Each money change is sorted by what is going on at that moment (merchant, trainer, mailbox, ...).

local ADDON, ns = ...
local T = ns.Tracker
local HEX = ns.Skin.HEX

local G = { ctx = {} }
T.Gold = G
local IN = { "loot", "vendor", "quests", "auction", "other" }
local OUT = { "repairs", "training", "purchases", "auction", "other" }
local MATCH_S = 1   -- seconds within which a chat line / quest event belongs to a money change

function G.Reset()
  G.net = T.NewStat()
  G.inc, G.out = {}, {}
  for _, k in ipairs(IN) do G.inc[k] = 0 end
  for _, k in ipairs(OUT) do G.out[k] = 0 end
  G.lastOther = nil
end
G.Reset()

function G.Classify(delta, now)
  now = now or GetTime()
  local c = G.ctx
  if delta > 0 and (c.questMoney or 0) > 0 then c.questMoney = math.max(0, c.questMoney - delta); return "quests" end
  if delta > 0 and c.lootAt and now - c.lootAt <= MATCH_S then c.lootAt = nil; return "loot" end
  if delta < 0 and c.repair then c.repair = nil; return "repairs" end
  if delta < 0 and c.trainer then return "training" end
  if c.merchant then return delta > 0 and "vendor" or "purchases" end
  if delta > 0 and c.mail then return "auction" end
  if delta < 0 and c.auction then return "auction" end
  return "other"
end

function G.OnMoney(money, now)
  now = now or GetTime()
  local delta = money - (G.last or money)
  G.last = money
  if delta == 0 then return nil end
  local cat = G.Classify(delta, now)
  if delta > 0 then G.inc[cat] = G.inc[cat] + delta else G.out[cat] = G.out[cat] - delta end
  T.Add(G.net, delta, now)
  G.lastOther = (cat == "other" and delta > 0) and { amount = delta, at = now } or nil
  return cat
end

-- The loot chat line and the quest event can each arrive before or after the money change.
local function Reclaim(cat, amount, now)
  local o = G.lastOther
  if o and now - o.at <= MATCH_S and (not amount or o.amount == amount) then
    G.inc.other = G.inc.other - o.amount
    G.inc[cat] = G.inc[cat] + o.amount
    G.lastOther = nil
    return true
  end
end

function G.OnLootChat(now)
  now = now or GetTime()
  if not Reclaim("loot", nil, now) then G.ctx.lootAt = now end
end

function G.OnQuestMoney(amount, now)
  now = now or GetTime()
  amount = tonumber(amount) or 0
  if amount <= 0 then return end
  if not Reclaim("quests", amount, now) then G.ctx.questMoney = (G.ctx.questMoney or 0) + amount end
end

local function List(t, keys)
  local parts = {}
  for _, k in ipairs(keys) do if t[k] > 0 then parts[#parts + 1] = k .. " " .. T.FmtMoney(t[k], true) end end
  return #parts > 0 and table.concat(parts, "  ·  ") or (HEX.muted .. "none|r")
end

function G.Lines()
  return {
    "net  " .. T.FmtMoney(G.net.total, true, true) .. HEX.muted .. "  this session|r",
    "per hour  session " .. T.FmtMoney(T.SessionRate(G.net), true, true) .. "  ·  last 15m " .. T.FmtMoney(T.RecentRate(G.net), true, true),
    "in   " .. List(G.inc, IN),
    "out  " .. List(G.out, OUT),
  }
end

function G.BarText()
  return T.FmtMoney((GetMoney and GetMoney()) or 0, true) .. " · " .. T.FmtMoney(T.BestRate(G.net), true, true) .. "/h"
end

local CONTEXT = {
  MERCHANT_SHOW = { "merchant", true }, MERCHANT_CLOSED = { "merchant", nil },
  TRAINER_SHOW = { "trainer", true }, TRAINER_CLOSED = { "trainer", nil },
  MAIL_SHOW = { "mail", true }, MAIL_CLOSED = { "mail", nil },
  AUCTION_HOUSE_SHOW = { "auction", true }, AUCTION_HOUSE_CLOSED = { "auction", nil },
}

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, event, a1, a2, a3)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    if not ns.ModuleEnabled("gold") then self:UnregisterAllEvents(); return end
    for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_MONEY", "CHAT_MSG_MONEY", "QUEST_TURNED_IN" }) do pcall(self.RegisterEvent, self, e) end
    for e in pairs(CONTEXT) do pcall(self.RegisterEvent, self, e) end
    if hooksecurefunc and RepairAllItems then hooksecurefunc("RepairAllItems", function() G.ctx.repair = true end) end
    T.AddSection{ id = "gold", title = "Gold", lines = G.Lines, reset = G.Reset,
      summary = function() return { money = G.net.total } end }
    if ns.Everpanel then
      ns.Everpanel.Add{ id = "gold", label = "Gold", side = "right", icon = "Interface\\Icons\\INV_Misc_Coin_01",
        events = { "PLAYER_MONEY" }, interval = 5, text = G.BarText,
        tooltip = function(tt)
          for _, l in ipairs(G.Lines()) do tt:AddLine(l, 1, 1, 1) end
          tt:AddLine("Click: tracker panel", 0.6, 0.6, 0.6)
        end,
        onClick = function() T.Toggle() end }
    end
  elseif event == "PLAYER_LOGIN" then
    G.last = (GetMoney and GetMoney()) or 0
  elseif event == "PLAYER_MONEY" then
    G.OnMoney((GetMoney and GetMoney()) or 0)
    T.Refresh()
  elseif event == "CHAT_MSG_MONEY" then
    G.OnLootChat()
  elseif event == "QUEST_TURNED_IN" then
    G.OnQuestMoney(a3)
  elseif CONTEXT[event] then
    G.ctx[CONTEXT[event][1]] = CONTEXT[event][2]
    if event == "MERCHANT_CLOSED" then G.ctx.repair = nil end
  end
end)
```

Append to `Evergreen.toc`: `Modules\Tracker_Gold.lua`

- [ ] **Step 3: Run the test** → `OK tracker: 2 sections, ...`; Everpanel/journal/route tests still `OK`.
- [ ] **Step 4: Commit** — `"Gold tracker: gold per hour, income and spending by source"`.

---

### Task 6: Gear plugins (durability, ammo/reagents)

**Files:**
- Create: `addon/Evergreen/Modules/Everpanel/Gear.lua`
- Modify: `addon/Evergreen/Evergreen.toc`, `addon/tools/test_everpanel.lua`

**Interfaces:** Produces plugin ids `durability`, `ammo`.

- [ ] **Step 1: Failing test** — add `"durability", "ammo"` to `EXPECT` in `test_everpanel.lua`, and before the final `io.write`:

```lua
-- durability shows the lowest item
GetInventoryItemDurability = function(slot) if slot == 1 then return 30, 100 elseif slot == 5 then return 90, 100 end end
local dur = EP.byId.durability.text()
assert(dur == "30%", "durability text: " .. tostring(dur))
GetInventoryItemDurability = nil
```

Run → FAIL `missing plugin durability`.

- [ ] **Step 2: Implement** — create `addon/Evergreen/Modules/Everpanel/Gear.lua`:

```lua
-- Everpanel plugins: durability (lowest equipped item) and ammo / reagents for classes that use them.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

local SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17, 18 }   -- head .. ranged: the slots that wear down

local function Durability()
  local low, items = nil, {}
  if not GetInventoryItemDurability then return nil, items end
  for _, slot in ipairs(SLOTS) do
    local cur, max = GetInventoryItemDurability(slot)
    if cur and max and max > 0 then
      local p = cur / max * 100
      items[#items + 1] = { slot = slot, pct = p }
      if not low or p < low then low = p end
    end
  end
  return low, items
end

local function PctColor(p) if p < 25 then return 1, 0.25, 0.25 elseif p < 60 then return 1, 0.82, 0 end return 0.25, 0.75, 0.25 end

EP.Add{ id = "durability", label = "Durability", side = "right", icon = "Interface\\Icons\\Trade_BlackSmithing",
  events = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD" },
  text = function() local low = Durability(); return low and (math.floor(low + 0.5) .. "%") or "—" end,
  tooltip = function(tt)
    local _, items = Durability()
    for _, it in ipairs(items) do
      local link = GetInventoryItemLink and GetInventoryItemLink("player", it.slot)
      local r, g, b = PctColor(it.pct)
      tt:AddDoubleLine(link or ("slot " .. it.slot), math.floor(it.pct + 0.5) .. "%", 1, 1, 1, r, g, b)
    end
    tt:AddLine("Click: character sheet", 0.6, 0.6, 0.6)
  end,
  onClick = function() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end,
}

-- what each class carries; ammo counts the equipped ammo slot (0)
local REAGENTS = {
  HUNTER  = { { ammo = true, name = "ammo" } },
  WARLOCK = { { id = 6265, name = "Soul Shards" } },
  MAGE    = { { id = 17020, name = "Arcane Powder" }, { id = 17031, name = "Rune of Teleportation" }, { id = 17032, name = "Rune of Portals" } },
  PRIEST  = { { id = 17028, name = "Holy Candle" }, { id = 17029, name = "Sacred Candle" } },
  PALADIN = { { id = 21177, name = "Symbol of Kings" }, { id = 17033, name = "Symbol of Divinity" } },
  SHAMAN  = { { id = 17030, name = "Ankh" } },
  DRUID   = { { id = 17034, name = "Maple Seed" }, { id = 17026, name = "Wild Thornroot" } },
  ROGUE   = { { id = 5140, name = "Flash Powder" }, { id = 5530, name = "Blinding Powder" } },
}
local function List() local _, cls = UnitClass("player"); return REAGENTS[cls or ""] end
local function Count(r)
  if r.ammo then return (GetInventoryItemCount and GetInventoryItemCount("player", 0)) or 0 end
  local f = (C_Item and C_Item.GetItemCount) or GetItemCount
  return (f and f(r.id)) or 0
end
local function Commas(n) local s = tostring(n); while true do local k; s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2"); if k == 0 then return s end end end

EP.Add{ id = "ammo", label = "Reagents", side = "right", icon = "Interface\\Icons\\INV_Misc_Ammo_Arrow_01",
  events = { "BAG_UPDATE", "UNIT_INVENTORY_CHANGED", "PLAYER_ENTERING_WORLD" },
  visible = function() return List() ~= nil end,
  text = function()
    local l = List()
    if not l then return "" end
    return Commas(Count(l[1])) .. " " .. l[1].name:lower()
  end,
  tooltip = function(tt)
    for _, r in ipairs(List() or {}) do tt:AddDoubleLine(r.name, Commas(Count(r)), 0.9, 0.9, 0.9, 1, 1, 1) end
  end,
}
```

Append to `Evergreen.toc`: `Modules\Everpanel\Gear.lua`

- [ ] **Step 3: Run the test** → `OK everpanel: 8 plugins, ...`
- [ ] **Step 4: Commit** — `"Everpanel: durability and ammo/reagent plugins"`.

---

### Task 7: Evergreen shortcut plugins (guide step, Everbuff, journal)

**Files:**
- Create: `addon/Evergreen/Modules/Everpanel/Evergreen.lua`
- Modify: `addon/Evergreen/Core.lua` (after `StepTitle`), `addon/Evergreen/Modules/Buffs.lua` (after `Scan`), `addon/Evergreen/Evergreen.toc`, `addon/tools/test_everpanel.lua`

**Interfaces:**
- Produces: `ns.GuideStepText() -> string|nil` (plain text of the step the arrow follows), `ns.EverbuffInfo() -> count, queue` (queue entries `{name=, spell=, unit=}`); plugin ids `guide`, `everbuff`, `journal`.

- [ ] **Step 1: Failing test** — add `"guide", "everbuff", "journal"` to `EXPECT`, and before the final `io.write`:

```lua
assert(type(ns.GuideStepText) == "function", "Core does not expose GuideStepText")
assert(type(ns.EverbuffInfo) == "function", "Buffs does not expose EverbuffInfo")
assert(EP.Visible("journal"), "journal plugin should show when the journal module is on")
```

Run (`BUFFS=1 EVERPANEL=1 ...`) → FAIL `missing plugin guide`.

- [ ] **Step 2: Expose guide and buff state.** In `addon/Evergreen/Core.lua`, directly after the `StepTitle` function (the `end` before `local function StepBody(b, step)`), add:

```lua
-- For Everpanel: the step the arrow follows, as plain text (nil before the guide has loaded).
function ns.GuideStepText()
  if not CDB then return nil end
  local b = CurrentBracket()
  local step = b and CurrentStep(b)
  if not step then return nil end
  return (StepTitle(step):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end
```

In `addon/Evergreen/Modules/Buffs.lua`, directly before the line `-- ------------------------------------------------------------------ UI` add:

```lua
-- For Everpanel: how many casts are queued, and the queue itself ({name=, spell=, unit=}, ...).
function ns.EverbuffInfo() return #queue, queue end
```

- [ ] **Step 3: Implement** — create `addon/Evergreen/Modules/Everpanel/Evergreen.lua`:

```lua
-- Everpanel plugins for Evergreen's own modules: current guide step, Everbuff queue, journal launcher.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

EP.Add{ id = "guide", label = "Guide", side = "left", icon = "Interface\\Icons\\INV_Misc_Book_08", interval = 2,
  events = { "QUEST_LOG_UPDATE", "QUEST_TURNED_IN" },
  visible = function() return ns.ModuleEnabled("guide") end,
  text = function()
    local s = (ns.GuideStepText and ns.GuideStepText()) or "route done"
    if #s > 40 then s = s:sub(1, 38) .. "..." end
    return s
  end,
  tooltip = function(tt)
    tt:AddLine((ns.GuideStepText and ns.GuideStepText()) or "route done", 1, 1, 1, true)
    tt:AddLine("Click: guide window", 0.6, 0.6, 0.6)
  end,
  onClick = function() if SlashCmdList.EVERGREEN then SlashCmdList.EVERGREEN("") end end,
}

EP.Add{ id = "everbuff", label = "Everbuff", side = "left", icon = "Interface\\Icons\\Spell_Holy_WordFortitude", interval = 2,
  visible = function() return ns.ModuleEnabled("buffs") and ns.EverbuffInfo ~= nil end,
  text = function()
    if not ns.EverbuffInfo then return "" end
    local n = ns.EverbuffInfo()
    return n .. " buff" .. (n == 1 and "" or "s")
  end,
  tooltip = function(tt)
    local n, queue = 0, {}
    if ns.EverbuffInfo then n, queue = ns.EverbuffInfo() end
    if n == 0 then tt:AddLine("Everyone in range is buffed", 0.6, 0.6, 0.6) end
    for i, q in ipairs(queue) do
      if i > 15 then break end
      tt:AddDoubleLine(q.name or q.unit or "?", q.spell, 1, 1, 1, 0.9, 0.9, 0.9)
    end
    tt:AddLine("Click: buff button", 0.6, 0.6, 0.6)
  end,
  onClick = function() if SlashCmdList.EVERBUFF then SlashCmdList.EVERBUFF("") end end,
}

EP.Add{ id = "journal", label = "Journal", side = "left", icon = "Interface\\Icons\\INV_Misc_Book_09",
  visible = function() return ns.ModuleEnabled("journal") and ns.Journal ~= nil end,
  text = function() return "" end,
  tooltip = function(tt) tt:AddLine("Click: dungeon journal", 0.6, 0.6, 0.6) end,
  onClick = function() if SlashCmdList.EVERGREENJOURNAL then SlashCmdList.EVERGREENJOURNAL("") end end,
}
```

Append to `Evergreen.toc`: `Modules\Everpanel\Evergreen.lua`

- [ ] **Step 4: Run** `BUFFS=1 EVERPANEL=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN | grep -E "^OK|rror"` → `OK everpanel: 11 plugins, ...`; also the journal test and 3 route runs (`Scourge PRIEST`, `Orc WARRIOR`, `Human PALADIN`, all `auto 30`) → `OK`.
- [ ] **Step 5: Commit** — `"Everpanel: guide step, Everbuff and journal plugins"`.

---

### Task 8: Social plugins (friends, guild)

**Files:**
- Create: `addon/Evergreen/Modules/Everpanel/Social.lua`
- Modify: `addon/Evergreen/Evergreen.toc`, `addon/tools/test_everpanel.lua`

**Interfaces:** Produces plugin ids `friends`, `guild`.

- [ ] **Step 1: Failing test** — add `"friends", "guild"` to `EXPECT`, and before the final `io.write`:

```lua
C_FriendList = { GetNumFriends = function() return 2 end,
  GetFriendInfoByIndex = function(i) return { name = "F" .. i, level = 20, area = "Barrens", connected = i == 1 } end }
assert(EP.byId.friends.text() == "1", "friends online: " .. tostring(EP.byId.friends.text()))
C_FriendList = nil
assert(not EP.Visible("guild"), "guild plugin should hide without a guild")
```

Run → FAIL `missing plugin friends`.

- [ ] **Step 2: Implement** — create `addon/Evergreen/Modules/Everpanel/Social.lua`:

```lua
-- Everpanel plugins: friends and guild members online.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

local function OnlineFriends()
  local list = {}
  if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
    for i = 1, C_FriendList.GetNumFriends() or 0 do
      local f = C_FriendList.GetFriendInfoByIndex(i)
      if f and f.connected then list[#list + 1] = { name = f.name, level = f.level, area = f.area } end
    end
  end
  return list
end

local function OnlineGuild()
  local list = {}
  if IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo then
    for i = 1, GetNumGuildMembers() or 0 do
      local name, _, _, level, _, zone, _, _, online = GetGuildRosterInfo(i)
      if online then list[#list + 1] = { name = name and (name:gsub("%-.*", "")), level = level, area = zone } end
    end
  end
  return list
end

local function Tip(tt, list, empty)
  if #list == 0 then tt:AddLine(empty, 0.6, 0.6, 0.6) end
  for i, p in ipairs(list) do
    if i > 25 then tt:AddLine("... " .. (#list - 25) .. " more", 0.6, 0.6, 0.6); break end
    tt:AddDoubleLine((p.name or "?") .. (p.level and (" (" .. p.level .. ")") or ""), p.area or "", 1, 1, 1, 0.7, 0.7, 0.7)
  end
end

EP.Add{ id = "friends", label = "Friends", side = "left", icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
  events = { "FRIENDLIST_UPDATE", "PLAYER_ENTERING_WORLD" },
  text = function() return tostring(#OnlineFriends()) end,
  tooltip = function(tt) Tip(tt, OnlineFriends(), "No friends online") end,
  onClick = function() if ToggleFriendsFrame then ToggleFriendsFrame(1) end end,
}

EP.Add{ id = "guild", label = "Guild", side = "left", icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
  events = { "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE" },
  visible = function() return IsInGuild and IsInGuild() and true or false end,
  text = function() return tostring(#OnlineGuild()) end,
  tooltip = function(tt)
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() elseif GuildRoster then GuildRoster() end
    Tip(tt, OnlineGuild(), "Nobody online")
  end,
  onClick = function()
    if ToggleGuildFrame then ToggleGuildFrame() elseif ToggleFriendsFrame then ToggleFriendsFrame(3) end
  end,
}
```

Append to `Evergreen.toc`: `Modules\Everpanel\Social.lua`

- [ ] **Step 3: Run the test** → `OK everpanel: 13 plugins, ...`
- [ ] **Step 4: Commit** — `"Everpanel: friends and guild plugins"`.

---

### Task 9: LibDataBroker bridge (other addons' plugins, off by default)

**Files:**
- Create: `addon/Evergreen/Modules/Everpanel/LDB.lua`
- Modify: `addon/Evergreen/Evergreen.toc`, `addon/tools/test_everpanel.lua`

**Interfaces:**
- Consumes: `EP.Add`, `EP.Update`, `EP.buttons`, `EP.db.ldb` (menu entry and `PLAYER_ENTERING_WORLD` scan already in Task 1).
- Produces: `EP.ScanLDB() -> count`; plugin ids `ldb:<name>`, visible only while `EP.db.ldb`.

- [ ] **Step 1: Failing test** — before the final `io.write` in `test_everpanel.lua`:

```lua
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
```

Run → FAIL `no LDB bridge`.

- [ ] **Step 2: Implement** — create `addon/Evergreen/Modules/Everpanel/LDB.lua`:

```lua
-- Everpanel: other addons' LibDataBroker plugins (Questie and others publish them). Off by
-- default; "Show other addons' plugins" in the right-click menu turns it on.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

local function Bridge(name, obj)
  local id = "ldb:" .. name
  if EP.byId[id] then return end
  EP.Add{ id = id, label = obj.label or name, side = "right", icon = obj.icon,
    visible = function() return EP.db and EP.db.ldb end,
    text = function() return tostring(obj.text or obj.label or name) end,
    tooltip = obj.OnTooltipShow and function(tt) obj.OnTooltipShow(tt) end or nil,
    onClick = obj.OnClick and function(btn) obj.OnClick(EP.buttons[id], btn) end or nil,
    rightClick = obj.OnClick ~= nil,
  }
end

function EP.ScanLDB()
  local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
  if not ldb then return 0 end
  local n = 0
  for name, obj in ldb:DataObjectIterator() do Bridge(name, obj); n = n + 1 end
  if not EP.ldbHooked then
    EP.ldbHooked = true
    ldb.RegisterCallback(EP, "LibDataBroker_DataObjectCreated", function(_, name, obj) Bridge(name, obj) end)
    ldb.RegisterCallback(EP, "LibDataBroker_AttributeChanged", function(_, name) EP.Update("ldb:" .. name) end)
  end
  return n
end
```

Append to `Evergreen.toc`: `Modules\Everpanel\LDB.lua`

- [ ] **Step 3: Run the test** → `OK everpanel: 14 plugins, ...`
- [ ] **Step 4: Commit** — `"Everpanel: optional LibDataBroker bridge"`.

---

### Task 10: Wire tests into rebuild.sh, deploy, check in game

**Files:**
- Modify: `addon/tools/rebuild.sh`

- [ ] **Step 1: Add the new test runs** — in `rebuild.sh`, after the `FAIL journal` line add:

```bash
runs=$((runs+1)); if ! BUFFS=1 EVERPANEL=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN | grep -q "^OK everpanel"; then fails=$((fails+1)); echo "FAIL everpanel"; fi
runs=$((runs+1)); if ! TRACKER=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN | grep -q "^OK tracker"; then fails=$((fails+1)); echo "FAIL tracker"; fi
```

- [ ] **Step 2: Run the whole test section.** From `addon/tools` run the `== test` block of `rebuild.sh` (or `./rebuild.sh` if the Questie/AtlasLoot sources are present). Expected: `test runs: N, failures: 0`.

- [ ] **Step 3: Commit** — `"rebuild.sh: run the Everpanel and tracker tests"`.

- [ ] **Step 4: Deploy** — copy `addon/Evergreen/.` to the beta folder (`cp -r ../Evergreen/. "$BETA/"`), then fully restart the game (new TOC files).

- [ ] **Step 5: In-game checklist** (report results to the user; fix what fails):
  - Bar across the top; minimap, buffs, player and target frames sit below it, nothing covered. If Edit Mode snaps them back or errors appear, set `offset` off via the menu and note it.
  - Each plugin's tooltip and click: clock toggle, location opens the map, bags open, durability opens the character sheet, guide / Everbuff / journal open their windows, friends / guild frames.
  - Right-click menu: hide/show plugins, move left/right/side, icons, labels, lock, hide bar, `/eg panel` brings it back; `/reload` keeps the layout.
  - Kill mobs: XP/h and time to level move; kill share rises. Turn in a quest: quest share.
  - Vendor, repair, train, loot: gold categories land correctly (`/eg track`).
  - Level up: after the next level, `/eg track history` lists the level time; relog: session appears in history.
