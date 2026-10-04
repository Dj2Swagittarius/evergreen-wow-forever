-- ForeverSkin: the WoW Forever look for standalone addons (Everblock, Evertaxi, !Everror...), the
-- same approach as Evergreen's ns.Skin. Windows are built from Blizzard's own frame templates, so on
-- WoW Forever (the "Camelot" UI) they wear its bronze metal frame, round portrait, dark red title
-- bar and red buttons; on Classic Era the grey-gold frames. A template the client lacks falls back
-- to a dark backdrop with a bronze edge, so nothing breaks.
--
-- Canonical copy: addon/_shared/ForeverSkin.lua. rebuild.sh copies it into each standalone addon;
-- edit it there, not in the copies. Load it first in the addon's TOC; it sets ns.Skin.
local ADDON, ns = ...
local Skin = {}
ns.Skin = Skin

-- Evergreen Grove art (the same pieces as Evergreen's core skin): the pine medallion portrait, the
-- plank sign behind the title and dark bark behind the body and insets. rebuild.sh copies
-- Evergreen/Art into each standalone addon as Art/.
local ART = "Interface\\AddOns\\" .. (ADDON or "Evergreen") .. "\\Art\\"
Skin.ART = { emblem = ART .. "emblem", plank = ART .. "plank", bark = ART .. "bark" }
Skin.PINE = { 0.50, 0.83, 0.37 }

-- Blizzard-like text colours: gold headings, white body, warm grey secondary.
Skin.HEX = { gold = "|cffffd100", white = "|cffffffff", body = "|cffe8e4d8", muted = "|cffa39e93",
  green = "|cff40c040", red = "|cffff4040", violet = "|cffb48cff", blue = "|cff6f9dff", pine = "|cff7fd35e" }

-- WoW may hand back a bare frame for a template it does not know; check the parts were built.
local BUILT = {
  PortraitFrameTemplate = function(f) return f.NineSlice or f.PortraitContainer or f.portrait end,
  ButtonFrameTemplate = function(f) return f.NineSlice or f.Inset end,
  InsetFrameTemplate = function(f) return f.Bg or f.NineSlice end,
  UIPanelButtonTemplate = function(f) return f.Left or f.LeftTexture or (f.GetFontString and f:GetFontString()) end,
  InputBoxTemplate = function(f) return f.Left or true end,
  BackdropTemplate = function(f) return f.SetBackdrop end,
}

local function make(ftype, name, parent, templates)
  for _, t in ipairs(templates) do
    local ok, f = pcall(CreateFrame, ftype, name, parent, t)
    if ok and f and (not BUILT[t] or BUILT[t](f)) then
      -- the template border (NineSlice) sits at level 500 and, on Forever, takes the mouse: drop it
      -- to the frame's own level so content sits above it, and no mouse.
      if type(f.NineSlice) == "table" then
        if f.NineSlice.EnableMouse then f.NineSlice:EnableMouse(false) end
        if f.NineSlice.SetFrameLevel and f.GetFrameLevel then f.NineSlice:SetFrameLevel(f:GetFrameLevel()) end
      end
      return f, t
    end
    if ok and f then f:Hide(); name = nil end
  end
  return CreateFrame(ftype, name, parent), nil
end
Skin.Make = make

local function plainBackdrop(f, a)
  if not f.SetBackdrop then return end
  f:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  f:SetBackdropColor(0.06, 0.05, 0.04, a or 0.95)
  f:SetBackdropBorderColor(0.62, 0.50, 0.32, 1)
end
Skin.Backdrop = plainBackdrop

function Skin.Text(parent, fontObject, text, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlight")
  if fs.GetFont and not fs:GetFont() then fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "") end
  fs:SetJustifyH(justify or "LEFT")
  if text then fs:SetText(text) end
  return fs
end

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

-- The plank sign over the top edge with the title on it: left boughs | plain wood (stretched) |
-- right boughs, cut from the 512x128 art (content x 48..464, plain wood 210..300).
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
  sign.text = sign:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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

-- Main window: portrait frame with title bar and close button, draggable, closes on Escape.
-- f.top is where content starts below the title bar; the portrait takes the top-left ~60x60.
function Skin.Window(name, w, h, title, icon)
  local f, t = make("Frame", name, UIParent, { "PortraitFrameTemplate", "BackdropTemplate" })
  f:SetSize(w, h)
  f:SetPoint("CENTER")
  f:SetFrameStrata("HIGH")
  if f.SetToplevel then f:SetToplevel(true) end
  f:SetMovable(true); f:EnableMouse(true)
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(s) if not s.locked then s:StartMoving() end end)
  f:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
  f.skinned = t == "PortraitFrameTemplate"
  if f.skinned then
    -- Grove: pine medallion portrait (the given icon only if the art is missing), bark under the
    -- body, the title on the plank sign
    if not (f.SetPortraitToAsset and pcall(f.SetPortraitToAsset, f, Skin.ART.emblem)) and icon then Skin.SetPortrait(f, icon) end
    barkFill(f, 0.55, 2, -21, -2, 2)
    local sign = plankSign(f, title)
    if sign then
      f.sign = sign
      if f.SetTitle then pcall(f.SetTitle, f, "") end
      f.SetTitle = function(self, s) sign:SetTitle(s) end
    elseif f.SetTitle then
      f:SetTitle(title)
    end
  else
    plainBackdrop(f)
    f.fallbackTitle = Skin.Text(f, "GameFontNormal", title, "CENTER")
    f.fallbackTitle:SetPoint("TOP", 0, -8)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    f.CloseButton = close
  end
  f.top = f.skinned and -26 or -28
  f.portraitW = f.skinned and 58 or 8
  f:Hide()
  if name then tinsert(UISpecialFrames, name) end
  return f
end

-- Portrait: a texture path, or "unit:player" for the unit's face.
function Skin.SetPortrait(f, icon)
  local pc = type(f.PortraitContainer) == "table" and f.PortraitContainer
  local tex = (f.GetPortrait and f:GetPortrait()) or (pc and pc.portrait) or f.portrait
  if type(icon) == "string" and icon:find("^unit:") then
    local unit = icon:sub(6)
    if f.SetPortraitToUnit then f:SetPortraitToUnit(unit)
    elseif tex and SetPortraitTexture then SetPortraitTexture(tex, unit) end
  elseif f.SetPortraitToAsset then f:SetPortraitToAsset(icon)
  elseif tex then tex:SetTexture(icon) end
end

-- Recessed dark area inside a window (quest-log / character-stats look).
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
function Skin.Button(parent, text, w, h, onClick)
  local b, t = make("Button", nil, parent, { "UIPanelButtonTemplate" })
  b:SetSize(w or 90, h or 22)
  if t then
    b:SetText(text)
  else
    plainBackdrop(b)
    b.text = Skin.Text(b, "GameFontNormalSmall", text, "CENTER")
    b.text:SetPoint("CENTER")
    b.SetText = function(self, s) self.text:SetText(s) end
  end
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end

function Skin.Check(parent, label, onClick)
  local b = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  b:SetSize(22, 22)
  b.Label = Skin.Text(b, "GameFontHighlightSmall", label)
  b.Label:SetPoint("LEFT", b, "RIGHT", 1, 0)
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end

-- Text entry. Single line: Blizzard's input box. Multi line: an edit box in an inset, returned as
-- the inset with .Edit (single line returns the edit box, with .Edit pointing at itself).
function Skin.Edit(parent, w, h, multi)
  if not multi then
    local e = make("EditBox", nil, parent, { "InputBoxTemplate" })
    e:SetSize(w, h or 20)
    e:SetAutoFocus(false)
    e:SetFontObject(ChatFontNormal)
    e:SetMaxLetters(255)
    e:SetScript("OnEscapePressed", e.ClearFocus)
    e.Edit = e
    return e
  end
  local box = Skin.Inset(parent)
  box:SetSize(w, h)
  local e = CreateFrame("EditBox", nil, box)
  e:SetPoint("TOPLEFT", 6, -5)
  e:SetPoint("BOTTOMRIGHT", -6, 5)
  e:SetFontObject(ChatFontNormal)
  e:SetAutoFocus(false)
  e:SetMultiLine(true)
  e:SetMaxLetters(255)
  e:SetScript("OnEscapePressed", e.ClearFocus)
  box:EnableMouse(true)
  box:SetScript("OnMouseDown", function() e:SetFocus() end)
  box.Edit = e
  return box
end

-- Heads-up box (a floating button or counter): tooltip-style dark box with a bronze edge.
function Skin.Hud(f) plainBackdrop(f, 0.85) end

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
