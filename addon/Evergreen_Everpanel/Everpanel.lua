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

-- Returns true when the button's width changed, so callers that redraw on frequent events (a
-- plugin's own events, the interval ticker) only pay for a full EP.Layout() when it can matter.
local lastWidth = {}
local function Draw(id)
  local p, b = EP.byId[id], EP.buttons[id]
  if not (p and b) then return false end
  local txt = ""
  if p.text then txt = safe(id, p.text); if txt == nil then txt = "?" end end
  local showIcon = DB.icons and p.icon ~= nil
  b.icon:SetShown(showIcon)
  b.text:ClearAllPoints()
  if showIcon then b.text:SetPoint("LEFT", b.icon, "RIGHT", 3, 0) else b.text:SetPoint("LEFT", b, "LEFT", 0, 0) end
  b.text:SetText(((DB.labels and p.label) and (HEX.gold .. p.label .. ":|r ") or "") .. tostring(txt))
  local w = math.max(16, (b.text:GetStringWidth() or 0) + (showIcon and 17 or 0))
  b:SetWidth(w)
  local changed = lastWidth[id] ~= w
  lastWidth[id] = w
  return changed
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
  local changed = false
  for id in pairs(evMap[ev] or {}) do if Draw(id) then changed = true end end
  if changed then EP.Layout() end
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
    if Draw(p.id) then EP.Layout() end
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
  local changed = false
  for _, p in ipairs(EP.plugins) do
    if p.interval and EP.buttons[p.id] and now >= (nextAt[p.id] or 0) then
      nextAt[p.id] = now + p.interval
      if Draw(p.id) then changed = true end
    end
  end
  if changed then EP.Layout() end
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
    menu:SetClampedToScreen(true)
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
local OTHER_BARS = { "Titan", "ElvUI", "Bazooka" }

-- Another bar addon (Titan Panel, ElvUI, Bazooka) already pushes the screen around; Everpanel
-- stays out of the way entirely rather than fight it (and Edit Mode) for the same real estate.
local function OtherBarAddon()
  if _G.TitanPanelBarButton or _G.ElvUI or _G.Bazooka then return true end
  local isLoaded = (_G.C_AddOns and _G.C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
  if isLoaded then
    for _, name in ipairs(OTHER_BARS) do
      local ok, loaded = pcall(isLoaded, name)
      if ok and loaded then return true end
    end
  end
  return false
end

local shifted, pendingOffset = {}, false
function EP.ApplyOffset()
  if not DB then return end
  if InCombatLockdown() then pendingOffset = true; return end
  pendingOffset = false
  local want = DB.shown and DB.offset and not OtherBarAddon()
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
        -- restore only if nothing else has since moved the frame away from where we put it;
        -- otherwise leave it alone rather than snap it back to a stale position
        if p and math.abs((y or 0) - (s[4] - BAR_H)) < 0.5 then
          f:ClearAllPoints(); f:SetPoint(s[1], UIParent, s[2], s[3], s[4])
        end
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
pcall(boot.RegisterEvent, boot, "EDIT_MODE_LAYOUTS_UPDATED")   -- may not exist on every client
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
