-- Evergreen core: the shared skin, the namespace every Evergreen module addon shares, and /eg.
--
-- The modules are separate addons listed under Evergreen in the AddOns list (Evergreen_Guide,
-- Evergreen_Journal, Evergreen_Buffs, Evergreen_Move, Evergreen_Reveal, Evergreen_Everpanel,
-- Evergreen_Trackers), each switched on or off there. They share this addon's namespace through
-- EvergreenNS and its saved variables (EvergreenDB...), which this addon declares.

local ADDON, ns = ...

local HEX = { green = "|cff7fd35e", muted = "|cff8f958a", red = "|cffe08a7a", ink = "|cffd9dccf" }

-- ------------------------------------------------------------------ shared skin
-- Every Evergreen window is built from Blizzard's own frame templates, so it wears whatever skin
-- the client ships: on WoW Forever (the "Camelot" UI) that is the bronze metal frame with the round
-- portrait, dark red title bar, red buttons and bottom tabs seen on the character sheet and quest
-- log; on Classic Era the classic grey-gold frames. A template the client lacks falls back to a
-- plain dark backdrop, so nothing breaks on an older client.
local Skin = {}
ns.Skin = Skin

-- Blizzard-like text colours: gold headings, white body, warm grey secondary.
Skin.HEX = { gold = "|cffffd100", white = "|cffffffff", body = "|cffe8e4d8", muted = "|cffa39e93", green = "|cff40c040", red = "|cffff4040", violet = "|cffb48cff", blue = "|cff6f9dff" }

-- WoW may hand back a bare frame (with a chat warning) for a template it does not know, so
-- check that the template actually built its parts before trusting it.
local BUILT = {
  PortraitFrameTemplate  = function(f) return f.NineSlice or f.PortraitContainer or f.portrait end,
  ButtonFrameTemplate    = function(f) return f.NineSlice or f.Inset end,
  InsetFrameTemplate     = function(f) return f.Bg or f.NineSlice end,
  UIPanelButtonTemplate  = function(f) return f.Left or f.LeftTexture or (f.GetFontString and f:GetFontString()) end,
  PanelTabButtonTemplate = function(f) return f.Left or f.LeftActive or f.LeftTexture or (f.GetFontString and f:GetFontString()) end,
  SearchBoxTemplate      = function(f) return f.Instructions or f.searchIcon end,
  InputBoxTemplate       = function(f) return f.Left or true end,
  BackdropTemplate       = function(f) return f.SetBackdrop end,
}
local function make(ftype, name, parent, templates)
  for _, t in ipairs(templates) do
    local ok, f = pcall(CreateFrame, ftype, name, parent, t)
    if ok and f and (not BUILT[t] or BUILT[t](f)) then
      -- the template's border (NineSlice) sits at frame level 500 over the whole frame and, on
      -- the Forever client, takes the mouse: every button inside the window went dead under it.
      -- Drop it to the frame's own level so content (level +1) sits above it, and no mouse.
      if f.NineSlice then
        if f.NineSlice.EnableMouse then f.NineSlice:EnableMouse(false) end
        if f.NineSlice.SetFrameLevel and f.GetFrameLevel then f.NineSlice:SetFrameLevel(f:GetFrameLevel()) end
      end
      return f, t
    end
    if ok and f then f:Hide(); name = nil end   -- a half-built named frame: do not reuse its name
  end
  return CreateFrame(ftype, name, parent), nil
end

local function plainBackdrop(f, a)
  if not f.SetBackdrop then return end
  f:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                  edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  f:SetBackdropColor(0.06, 0.05, 0.04, a or 0.95)
  f:SetBackdropBorderColor(0.62, 0.50, 0.32, 1)
end

-- A font string using one of Blizzard's font objects ("GameFontNormal" = gold, "GameFontHighlight"
-- = white, "...Small", "...Large"), so size and face follow the client's own UI.
function Skin.Text(parent, fontObject, justify, layer)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY", fontObject or "GameFontHighlight")
  if not fs:GetFont() then fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "") end
  fs:SetJustifyH(justify or "LEFT")
  fs:SetJustifyV("TOP")
  return fs
end

-- ------------------------------------------------------------------ Evergreen Grove art
-- Our own painted pieces on top of the Forever frame (art/concepts holds the sources):
-- the pine medallion in every portrait, a wooden plank sign with pine boughs behind the title,
-- and dark bark behind the window body and every inset. All power-of-two TGAs in Evergreen\Art.
local ART = "Interface\\AddOns\\Evergreen\\Art\\"
Skin.ART = { emblem = ART .. "emblem", plank = ART .. "plank", bark = ART .. "bark" }
-- painted module icons (minimap buttons), by module id
Skin.ICONS = {}
for _, id in ipairs({ "guide", "journal", "buffs", "professions", "farming" }) do Skin.ICONS[id] = ART .. "icon_" .. id end
-- pine-green accents (headings stay Blizzard gold)
Skin.HEX.pine = "|cff7fd35e"
Skin.PINE = { 0.50, 0.83, 0.37 }

-- bark tiled over a region, under the content
local function barkFill(f, alpha, l, t, r, b)
  if type(f.CreateTexture) ~= "function" then return end
  local tex = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  if type(tex) ~= "table" then return end
  tex:SetTexture(Skin.ART.bark, "REPEAT", "REPEAT")
  if tex.SetHorizTile then tex:SetHorizTile(true); tex:SetVertTile(true) end
  tex:SetPoint("TOPLEFT", l or 3, t or -3)
  tex:SetPoint("BOTTOMRIGHT", r or -3, b or 3)
  tex:SetAlpha(alpha or 0.9)
  return tex
end
Skin.BarkFill = barkFill

-- The plank sign: left boughs | plain wood (stretched) | right boughs, cut from the 512x128 art
-- (content spans x 48..464; plain wood between 210 and 300). Sits over the top edge of the window
-- with the title written on it.
local PLANK_H = 34
local function plankSign(f, title)
  local sign = CreateFrame("Frame", nil, f)
  if type(sign) ~= "table" or type(sign.CreateTexture) ~= "function" then return end
  sign:SetHeight(PLANK_H)
  sign:SetPoint("TOP", f, "TOP", 10, 12)
  if sign.SetFrameLevel and f.GetFrameLevel then sign:SetFrameLevel((f:GetFrameLevel() or 1) + 20) end
  local s = PLANK_H / 128
  local function part(x0, x1)
    local t = sign:CreateTexture(nil, "ARTWORK")
    if type(t) ~= "table" then return nil, 0 end
    t:SetTexture(Skin.ART.plank)
    t:SetTexCoord(x0 / 512, x1 / 512, 0, 1)
    t:SetHeight(PLANK_H)
    return t, (x1 - x0) * s
  end
  local left, lw = part(48, 210)
  local right, rw = part(300, 464)
  local mid = part(210, 300)
  if not (left and right and mid) then return end
  left:SetPoint("LEFT"); left:SetWidth(lw)
  right:SetPoint("RIGHT"); right:SetWidth(rw)
  mid:SetPoint("LEFT", left, "RIGHT"); mid:SetPoint("RIGHT", right, "LEFT")
  sign.text = Skin.Text(sign, "GameFontNormal", "CENTER", "OVERLAY")
  sign.text:SetPoint("CENTER", 0, 1)
  if sign.text.SetShadowOffset then sign.text:SetShadowOffset(1, -1) end
  function sign.SetTitle(self, t)
    self.text:SetText(t or "")
    local tw = (self.text.GetStringWidth and self.text:GetStringWidth()) or 100
    if type(tw) ~= "number" then tw = 100 end
    self:SetWidth(math.max(lw + rw + 40, tw + lw + rw - 30))
  end
  sign:SetTitle(title)
  return sign
end

-- Main window: portrait frame with title bar and close button. Draggable by its title area.
function Skin.Window(name, w, h, title, icon, onMoved)
  local f, t = make("Frame", name, UIParent, { "PortraitFrameTemplate", "BackdropTemplate" })
  f:SetSize(w, h)
  f:SetPoint("CENTER")
  f:SetFrameStrata("HIGH")
  f:SetToplevel(true)
  f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(s) if not s.locked then s:StartMoving() end end)
  f:SetScript("OnDragStop", function(s) s:StopMovingOrSizing(); if onMoved then onMoved(s) end end)
  f.skinned = t == "PortraitFrameTemplate"
  if f.skinned then
    -- Grove: our pine medallion in the portrait (the module icon only if the art is missing),
    -- bark under the body, the title on a plank sign instead of the plain title bar text
    if f.SetPortraitToAsset then
      if not pcall(f.SetPortraitToAsset, f, Skin.ART.emblem) and icon then f:SetPortraitToAsset(icon) end
    end
    barkFill(f, 0.55, 2, -21, -2, 2)
    local sign = plankSign(f, title)
    if sign then
      f.sign = sign
      local blizzSetTitle = f.SetTitle
      if blizzSetTitle then pcall(blizzSetTitle, f, "") end
      f.SetTitle = function(self, s) sign:SetTitle(s) end
    elseif f.SetTitle then
      f:SetTitle(title)
    end
  else
    plainBackdrop(f)
    f.fallbackTitle = Skin.Text(f, "GameFontNormal", "CENTER")
    f.fallbackTitle:SetPoint("TOP", 0, -8)
    f.fallbackTitle:SetText(title)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    f.CloseButton = close
  end
  -- content starts below the title bar; with a portrait, the top-left 60x60 is taken
  f.contentTop = f.skinned and -26 or -28
  f.portraitW = f.skinned and 58 or 8
  if name then tinsert(UISpecialFrames, name) end
  return f
end

-- Smaller floating panel: the same metal frame without a portrait.
function Skin.Panel(name, w, h, title)
  local f, t = make("Frame", name, UIParent, { "ButtonFrameTemplate", "BackdropTemplate" })
  f:SetSize(w, h)
  f.skinned = t == "ButtonFrameTemplate"
  if f.skinned then
    if ButtonFrameTemplate_HidePortrait then pcall(ButtonFrameTemplate_HidePortrait, f) end
    if ButtonFrameTemplate_HideButtonBar then pcall(ButtonFrameTemplate_HideButtonBar, f) end
    if ButtonFrameTemplate_HideAttic then pcall(ButtonFrameTemplate_HideAttic, f) end
    if f.Inset then f.Inset:Hide() end
    if f.SetTitle then f:SetTitle(title) end
  else
    plainBackdrop(f)
    f.fallbackTitle = Skin.Text(f, "GameFontNormal", "CENTER")
    f.fallbackTitle:SetPoint("TOP", 0, -8)
    f.fallbackTitle:SetText(title)
  end
  return f
end

-- Recessed dark area inside a window (the quest-log / character-stats look).
function Skin.Inset(parent)
  local f, t = make("Frame", nil, parent, { "InsetFrameTemplate", "BackdropTemplate" })
  if t ~= "InsetFrameTemplate" then
    plainBackdrop(f, 0.6)
    if f.SetBackdropBorderColor then f:SetBackdropBorderColor(0.35, 0.29, 0.20, 1) end
  end
  f.bark = barkFill(f, 0.9)
  return f
end

-- Standard red push button.
function Skin.Button(parent, text, w, h)
  local b, t = make("Button", nil, parent, { "UIPanelButtonTemplate" })
  b:SetSize(w or 90, h or 22)
  local fs = t and ((type(b.Text) == "table" and b.Text) or (b.GetFontString and b:GetFontString()))
  if t and type(fs) == "table" and fs.SetText then
    b:SetText(text)
    b.text = fs
  else
    t = nil
    plainBackdrop(b)
    b.text = Skin.Text(b, "GameFontNormalSmall", "CENTER")
    b.text:SetPoint("CENTER")
    b.text:SetText(text)
  end
  function b.SetLabel(self, s) if self.SetText and t then self:SetText(s) else self.text:SetText(s) end end
  return b
end

-- Bottom tabs, like the character sheet and spellbook. Returns the list of tab buttons;
-- onSelect(i) runs when one is clicked. Falls back to push buttons along the bottom.
function Skin.Tabs(frame, names, onSelect)
  local tabs = {}
  for i, n in ipairs(names) do
    local tab, t = make("Button", (frame:GetName() or "EvergreenAnon") .. "Tab" .. i, frame, { "PanelTabButtonTemplate" })
    tab:SetID(i)
    if t then
      tab:SetText(n)
      if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 0) end
    else
      tab = Skin.Button(frame, n, 90, 22)
      tab:SetID(i)
    end
    if i == 1 then tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 12, 2)
    else tab:SetPoint("LEFT", tabs[i - 1], "RIGHT", -12 + (t and 0 or 16), 0) end
    tab:SetScript("OnClick", function(s)
      if PanelTemplates_SetTab then pcall(PanelTemplates_SetTab, frame, s:GetID()) end
      onSelect(s:GetID())
    end)
    tabs[i] = tab
  end
  frame.Tabs = tabs
  frame.numTabs = #tabs
  if PanelTemplates_SetNumTabs then pcall(PanelTemplates_SetNumTabs, frame, #tabs) end
  return tabs
end
function Skin.SelectTab(frame, i)
  if PanelTemplates_SetTab then pcall(PanelTemplates_SetTab, frame, i) end
end

-- Search box with the magnifier and clear button.
function Skin.Search(parent, w, hint)
  local e, t = make("EditBox", nil, parent, { "SearchBoxTemplate", "InputBoxTemplate" })
  e:SetSize(w, 20)
  e:SetAutoFocus(false)
  if e.Instructions and hint then e.Instructions:SetText(hint) end
  return e, t
end

-- Heads-up box (the waypoint arrow, the buff button): tooltip-style dark box with a bronze edge.
function Skin.Hud(f) plainBackdrop(f, 0.82) end

-- Minimap button in Blizzard's round tracking-button style, draggable around the minimap edge.
-- Each module has its own (id "guide", "journal", "buffs"); angles live in
-- EvergreenDB.minimapButtons[id], hidden ones in EvergreenDB.hideMinimap[id] (/eg minimap <id>).
-- onClick(mouseButton) runs on left / right click; tooltip(tt) fills the tooltip.
Skin.minimapButtons = {}
function Skin.MinimapButton(id, icon, defaultAngle, onClick, tooltip)
  EvergreenDB.minimapButtons = EvergreenDB.minimapButtons or {}
  EvergreenDB.hideMinimap = EvergreenDB.hideMinimap or {}
  local store = EvergreenDB.minimapButtons
  if store[id] == nil then store[id] = defaultAngle end
  if not Minimap then return nil end
  local btn = CreateFrame("Button", "EvergreenMinimap_" .. id, Minimap)
  btn:SetSize(31, 31); btn:SetFrameStrata("MEDIUM"); btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp"); btn:RegisterForDrag("LeftButton")
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local overlay = btn:CreateTexture(nil, "OVERLAY"); overlay:SetSize(53, 53); overlay:SetPoint("TOPLEFT")
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  local bg = btn:CreateTexture(nil, "BACKGROUND"); bg:SetSize(20, 20); bg:SetPoint("TOPLEFT", 7, -5)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  local tex = btn:CreateTexture(nil, "ARTWORK"); tex:SetSize(20, 20); tex:SetPoint("TOPLEFT", 7, -5)
  -- Grove: our painted module icon when there is one, else the module's game icon
  local grove = Skin.ICONS[id]
  if grove then tex:SetTexture(grove); tex:SetTexCoord(0, 1, 0, 1)
  else tex:SetTexture(icon); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
  btn.icon = tex
  local function place()
    local angle = math.rad(store[id] or defaultAngle)
    local r = (Minimap:GetWidth() or 140) / 2 + 10
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
  end
  btn:SetScript("OnDragStart", function(s) s:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter(); local cx, cy = GetCursorPosition(); local sc = Minimap:GetEffectiveScale()
    store[id] = math.deg(math.atan2(cy / sc - my, cx / sc - mx)); place()
  end) end)
  btn:SetScript("OnDragStop", function(s) s:SetScript("OnUpdate", nil) end)
  btn:SetScript("OnClick", function(_, b) onClick(b) end)
  btn:SetScript("OnEnter", function(s)
    GameTooltip:SetOwner(s, "ANCHOR_LEFT")
    tooltip(GameTooltip)
    GameTooltip:AddLine("Drag to move around the minimap", 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  place()
  if EvergreenDB.hideMinimap[id] then btn:Hide() end
  Skin.minimapButtons[id] = btn
  return btn
end

-- Row highlight in the quest-log style.
function Skin.RowHighlight(r)
  local h = r:CreateTexture(nil, "HIGHLIGHT")
  h:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  h:SetBlendMode("ADD")
  h:SetAllPoints()
  h:SetAlpha(0.45)
  if h.SetVertexColor then h:SetVertexColor(Skin.PINE[1], Skin.PINE[2], Skin.PINE[3]) end -- Grove: pine glow
  return h
end

-- ------------------------------------------------------------------ modules (child addons)
-- Each module is its own addon (Evergreen_Guide, Evergreen_Journal...) listed under Evergreen in the
-- AddOns list, so it is switched on or off there. EvergreenDB.modules can still switch a module off
-- (the test harness uses it); the first load of the split version clears old flags from the
-- in-game /eg module toggles so the AddOns list is the only switch players see.
ns.MODULES = {
  { id = "guide",     addon = "Evergreen_Guide",     name = "Guide",        slash = "/eg",        desc = "Leveling route, waypoint arrow, quest tracking" },
  { id = "journal",   addon = "Evergreen_Journal",   name = "Journal",      slash = "/ej",        desc = "Dungeon journal: bosses, loot, dungeon quests, entrances, map markers" },
  { id = "buffs",     addon = "Evergreen_Buffs",     name = "Buffs",        slash = "/eb",        desc = "Scans nearby players for missing buffs; one button casts the next" },
  { id = "move",      addon = "Evergreen_Move",      name = "Move",         slash = "/emove",     desc = "Drag the map, character sheet, bags and other windows anywhere" },
  { id = "reveal",    addon = "Evergreen_Reveal",    name = "Map Reveal",   slash = "/eg reveal", desc = "Shows unexplored areas on the world map (WoW Forever map data)" },
  { id = "everpanel", addon = "Evergreen_Everpanel", name = "Everpanel",    slash = "/eg panel",  desc = "Titan Panel-style info bar across the top of the screen" },
  { id = "xp",        addon = "Evergreen_Trackers",  name = "XP tracker",   slash = "/eg track",  desc = "XP per hour, time to level, XP by source, time per level" },
  { id = "gold",      addon = "Evergreen_Trackers",  name = "Gold tracker", slash = "/eg track",  desc = "Gold per hour, income and spending by source" },
}

local byId = {}
for _, m in ipairs(ns.MODULES) do byId[m.id] = m end

-- Loaded (or loading), or enabled for this character and so about to load. Clients without the
-- C_AddOns API (the test harness) count every module as present.
local function addonOn(name)
  local A = _G.C_AddOns
  if not A then return true end
  if A.IsAddOnLoaded and A.IsAddOnLoaded(name) then return true end
  if A.GetAddOnEnableState then
    local ok, state = pcall(A.GetAddOnEnableState, name, UnitName and UnitName("player") or nil)
    if ok and state ~= nil then return (tonumber(state) or 0) > 0 end
  end
  return true
end

function ns.ModuleEnabled(id)
  local db = EvergreenDB and EvergreenDB.modules
  if db and db[id] == false then return false end
  local m = byId[id]
  return not m or addonOn(m.addon)
end

local function listModules()
  print(HEX.green .. "Evergreen modules|r (turn each on or off in the AddOns list, under Evergreen):")
  for _, m in ipairs(ns.MODULES) do
    local on = ns.ModuleEnabled(m.id)
    print(string.format("  %s%-3s|r %s  %s%s|r  %s", on and HEX.green or HEX.red, on and "on" or "off",
      m.name, HEX.muted, m.slash, m.desc))
  end
end

local function offMessage(id)
  local m = byId[id]
  print(HEX.green .. "Evergreen:|r " .. m.name .. " is off. Turn on \"Evergreen - " ..
    (m.addon:gsub("^Evergreen_", "")) .. "\" in the AddOns list, then /reload.")
end

-- /eg belongs to the core so module commands work whichever modules are loaded; everything else
-- goes to the guide (Evergreen_Guide sets ns.GuideSlash).
SLASH_EVERGREEN1 = "/eg"
SLASH_EVERGREEN2 = "/evergreen"
SlashCmdList["EVERGREEN"] = function(msg)
  local m = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  local cmd, rest = m:match("^(%S+)%s*(.*)$")
  if cmd == "modules" then
    listModules()
  elseif cmd == "module" then
    print(HEX.green .. "Evergreen:|r modules are now separate addons: turn them on or off in the AddOns list, under Evergreen.")
    listModules()
  elseif cmd == "minimap" or cmd == "icons" then
    EvergreenDB.hideMinimap = EvergreenDB.hideMinimap or {}
    local id = rest ~= "" and rest or nil
    for bid, btn in pairs(Skin.minimapButtons) do
      if not id or id == bid or id == "all" then
        EvergreenDB.hideMinimap[bid] = not EvergreenDB.hideMinimap[bid] or nil
        btn:SetShown(not EvergreenDB.hideMinimap[bid])
      end
    end
    local st = {}
    for bid in pairs(Skin.minimapButtons) do st[#st + 1] = bid .. (EvergreenDB.hideMinimap[bid] and " (hidden)" or "") end
    table.sort(st)
    print(HEX.green .. "Evergreen:|r minimap buttons: " .. table.concat(st, ", ") .. ". /eg minimap <guide|journal|buffs> toggles one.")
  elseif cmd == "journal" or cmd == "ej" then
    if SlashCmdList.EVERGREENJOURNAL then SlashCmdList.EVERGREENJOURNAL(rest) else offMessage("journal") end
  elseif cmd == "reveal" then
    if ns.Reveal then ns.Reveal.Slash(rest) else offMessage("reveal") end
  elseif cmd == "panel" then
    if ns.Everpanel and not ns.Everpanel.disabled and ns.Everpanel.bar then ns.Everpanel.Slash(rest) else offMessage("everpanel") end
  elseif cmd == "track" then
    if ns.Tracker and ns.Tracker.enabled then ns.Tracker.Slash(rest) else offMessage("xp") end
  elseif not ns.GuideSlash or not ns.ModuleEnabled("guide") then
    offMessage("guide")
    print(HEX.muted .. "  /eg modules lists the Evergreen modules.|r")
  else
    ns.GuideSlash(msg)
    if m == "help" or m == "?" then
      print(HEX.green .. "Modules|r: /eg modules, /eg reveal, /eg panel, /eg track, /ej, /eb, /emove")
    end
  end
end

-- Child addons reach the core's namespace through this global (see Link.lua in each of them).
EvergreenNS = ns

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, _, name)
  if name ~= ADDON then return end
  self:UnregisterEvent("ADDON_LOADED")
  EvergreenDB = EvergreenDB or {}
  if not EvergreenDB.split then
    EvergreenDB.modules = {}   -- old in-game toggles; the AddOns list switches modules now
    EvergreenDB.split = true
  end
  EvergreenDB.modules = EvergreenDB.modules or {}
end)

-- ------------------------------------------------------------------ GatherMate2 on Forever
-- Map pins call SetPassThroughButtons when acquired, which this client only allows Blizzard code
-- to call: GatherMate2's world map pins got ADDON_ACTION_BLOCKED (hundreds per map open). A pin
-- doesn't need it; give GatherMate2's pin mixin a no-op before its first pin is created (the
-- template copies the mixin's functions onto each pin), like retail map addons do.
local function fixGatherMate2Pins()
  local mixin = _G.GatherMate2WorldMapPinMixin
  if type(mixin) == "table" and not mixin.everForever then
    mixin.SetPassThroughButtons = function() end
    mixin.everForever = true
  end
end
local gm = CreateFrame("Frame")
gm:RegisterEvent("ADDON_LOADED")
gm:SetScript("OnEvent", function(_, _, name) if name == "GatherMate2" then fixGatherMate2Pins() end end)
fixGatherMate2Pins() -- if GatherMate2 loaded first
