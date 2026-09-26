-- Evergreen module registry. Loaded first (see Evergreen.toc).
--
-- Evergreen is one addon made of modules: the leveling guide, Everbuff (buff button),
-- EverMove (window mover) and Reveal (world map fog removal). Each module checks
-- ns.ModuleEnabled(id) when the addon loads and stays dormant when switched off, so
-- turning one on or off takes effect after a /reload. Settings: EvergreenDB.modules.

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
    if ok and f and (not BUILT[t] or BUILT[t](f)) then return f, t end
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
    if f.SetTitle then f:SetTitle(title) end
    if icon and f.SetPortraitToAsset then f:SetPortraitToAsset(icon) end
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
  tex:SetTexture(icon); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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
  return h
end

ns.MODULES = {
  { id = "guide",  name = "Guide",  slash = "/eg",    desc = "Leveling route, waypoint arrow, quest tracking" },
  { id = "buffs",  name = "Buffs",  slash = "/eb",    desc = "Scans nearby players for missing buffs; one button casts the next" },
  { id = "move",   name = "Move",   slash = "/emove", desc = "Drag the map, character sheet, bags and other windows anywhere" },
  { id = "reveal", name = "Reveal", slash = "/eg reveal", desc = "Shows unexplored areas on the world map (WoW Forever map data)" },
  { id = "journal", name = "Journal", slash = "/ej", desc = "Dungeon journal: bosses, loot, dungeon quests, entrances, map markers" },
}

local byId = {}
for _, m in ipairs(ns.MODULES) do byId[m.id] = m end

function ns.ModuleEnabled(id)
  local db = EvergreenDB and EvergreenDB.modules
  if db and db[id] ~= nil then return db[id] end
  return true   -- every module is on unless switched off
end

local function listModules()
  print(HEX.green .. "Evergreen modules:|r")
  for _, m in ipairs(ns.MODULES) do
    local on = ns.ModuleEnabled(m.id)
    print(string.format("  %s%-6s|r %s  %s%s|r  %s", on and HEX.green or HEX.red, on and "on" or "off",
      m.id, HEX.muted, m.slash, m.desc))
  end
  print(HEX.muted .. "  /eg module <id> on|off, then /reload.|r")
end

local function setModule(id, state)
  local m = byId[id or ""]
  if not m then print(HEX.red .. "Evergreen:|r no module '" .. tostring(id) .. "'."); listModules(); return end
  local on
  if state == "on" then on = true elseif state == "off" then on = false else on = not ns.ModuleEnabled(id) end
  EvergreenDB.modules[id] = on
  print(HEX.green .. "Evergreen:|r " .. m.name .. " module " .. (on and "on" or "off") .. ". " .. HEX.ink .. "/reload|r to apply.")
end

-- Wrap the guide's /eg handler so module commands work even when the guide is off.
local function wrapSlash()
  local guide = SlashCmdList["EVERGREEN"]
  SlashCmdList["EVERGREEN"] = function(msg)
    local m = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = m:match("^(%S+)%s*(.*)$")
    if cmd == "modules" then
      listModules()
    elseif cmd == "module" then
      local id, state = rest:match("^(%S+)%s*(%S*)$")
      setModule(id, state)
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
      if SlashCmdList.EVERGREENJOURNAL then SlashCmdList.EVERGREENJOURNAL(rest) end
    elseif cmd == "reveal" then
      if ns.Reveal then ns.Reveal.Slash(rest) else print(HEX.green .. "Evergreen:|r Reveal module is off. /eg module reveal on, then /reload.") end
    elseif not ns.ModuleEnabled("guide") then
      print(HEX.green .. "Evergreen:|r guide module is off. /eg modules lists modules; /eg module guide on, then /reload.")
    else
      guide(msg)
      if m == "help" or m == "?" then
        print(HEX.green .. "Modules|r: /eg modules, /eg module <id> on|off, /eg reveal, /ej, /eb, /emove")
      end
    end
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, _, name)
  if name ~= ADDON then return end
  self:UnregisterEvent("ADDON_LOADED")
  EvergreenDB = EvergreenDB or {}
  EvergreenDB.modules = EvergreenDB.modules or {}
  wrapSlash()
end)
