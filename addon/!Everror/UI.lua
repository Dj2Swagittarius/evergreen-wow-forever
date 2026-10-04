-- !Everror UI: the red "! N" button, the copy window, the Blizzard popup switch and /err.
local ADDON, ns = ...
local C = ns.Core
local Skin = ns.Skin

local RED = "|cffff5555"
local function say(text) print(RED .. "Everror:|r " .. text) end

---------------------------------------------------------------------------
-- Copy window
---------------------------------------------------------------------------
local win, box, shownText
local view = "current"

local function textFor(which)
  local db = ns.db
  if not db then return "Everror has not loaded yet." end
  if which == "last" then return C.FormatSession(C.Last(db)) end
  if which == "all" then return C.FormatAll(db) end
  return C.FormatSession(C.Current(db))
end

local function refresh()
  if not win or not win:IsShown() then return end
  shownText = textFor(view)
  box:SetText(shownText)
  box:SetCursorPosition(0)
  box:HighlightText()
  box:SetFocus()
  win.Title:SetText(("Everror - %s"):format(view == "current" and "this session" or view == "last" and "last session" or "all sessions"))
end

local function button(parent, label, width, onClick)
  return Skin.Button(parent, label, width, 22, onClick)
end

local function buildWindow()
  win = Skin.Window("EverrorFrame", 720, 480, "Everror", "Interface\\Icons\\INV_Misc_Note_01")
  win.Title = Skin.Text(win, "GameFontHighlight")
  win.Title:SetPoint("TOPLEFT", win.portraitW + 12, win.top - 10)

  -- the text, in a recessed inset below the portrait
  local inset = Skin.Inset(win)
  inset:SetPoint("TOPLEFT", 12, win.top - 40)
  inset:SetPoint("BOTTOMRIGHT", -12, 44)
  local scroll = CreateFrame("ScrollFrame", "EverrorScroll", win, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 8, -6)
  scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -28, 6)
  box = CreateFrame("EditBox", nil, scroll)
  box:SetMultiLine(true)
  box:SetAutoFocus(false)
  box:SetFontObject(ChatFontNormal)
  -- a scroll child with no height is never drawn
  box:SetSize(660, 380)
  box:SetScript("OnEscapePressed", function() win:Hide() end)
  -- read-only: any typing puts the text back
  box:SetScript("OnTextChanged", function(self, user)
    if user and shownText then self:SetText(shownText); self:HighlightText() end
  end)
  scroll:SetScrollChild(box)
  scroll:SetScript("OnMouseDown", function() box:SetFocus(); box:HighlightText() end)

  local hint = Skin.Text(win, "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", 16, 18)
  hint:SetText("All text is selected: Ctrl+C to copy.  Or /reload and tell Claude \"check errors\".")

  local x = -12
  local function add(label, w, fn)
    local b = button(win, label, w, fn)
    b:SetPoint("BOTTOMRIGHT", x, 14)
    x = x - w - 4
  end
  add("Clear", 60, function()
    local s = ns.db and C.Current(ns.db)
    if s then wipe(s.errors); s.dropped = nil end
    ns.UpdateButton(); refresh()
  end)
  add("All", 50, function() view = "all"; refresh() end)
  add("Last session", 100, function() view = "last"; refresh() end)
  add("This session", 100, function() view = "current"; refresh() end)
  win:SetScript("OnShow", refresh)
end

local function toggleWindow(which)
  if not win then buildWindow() end
  if which then view = which end
  if win:IsShown() and not which then win:Hide() else win:Show(); refresh() end
end

---------------------------------------------------------------------------
-- Error button
---------------------------------------------------------------------------
local btn
local function buildButton()
  btn = CreateFrame("Button", "EverrorButton", UIParent, "BackdropTemplate")
  btn:SetSize(52, 24)
  btn:SetFrameStrata("HIGH")
  -- the Forever heads-up box (dark with a bronze edge), red count
  Skin.Hud(btn)
  btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
  btn.Text:SetPoint("CENTER")
  local p = ns.db.button
  if p then btn:SetPoint(p[1], UIParent, p[1], p[2], p[3]) else btn:SetPoint("TOP", UIParent, "TOP", 0, -120) end
  btn:SetMovable(true)
  btn:RegisterForDrag("LeftButton")
  btn:SetScript("OnDragStart", btn.StartMoving)
  btn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    ns.db.button = { point, x, y }
  end)
  btn:SetScript("OnClick", function() toggleWindow("current") end)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Lua errors this session")
    GameTooltip:AddLine("Click to open and copy. Drag to move.", 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

end

function ns.UpdateButton()
  if not btn then return end
  local n = C.CountCurrent(ns.db)
  btn.Text:SetText("! " .. n)
  btn:SetShown(n > 0)
end

---------------------------------------------------------------------------
-- Hooks from Capture.lua
---------------------------------------------------------------------------
-- Blink the button a few times on a new error (timer-driven; no animation API needed).
local blinking = false
local function blink()
  if blinking or not C_Timer then return end
  blinking = true
  local n = 0
  local ticker
  ticker = C_Timer.NewTicker(0.2, function()
    n = n + 1
    btn:SetAlpha(n % 2 == 1 and 0.3 or 1)
    if n >= 6 then ticker:Cancel(); btn:SetAlpha(1); blinking = false end
  end)
end

function ns.OnNewError()
  if not btn then return end
  ns.UpdateButton()
  blink()
  refresh()
end

-- Blizzard's popup only shows while CVar scriptErrors is on.
local function applyPopup()
  local db = ns.db
  if db.popupOff then
    if GetCVar("scriptErrors") == "1" then db.restoreScriptErrors = true; SetCVar("scriptErrors", "0") end
  elseif db.restoreScriptErrors then
    SetCVar("scriptErrors", "1"); db.restoreScriptErrors = nil
  end
end

function ns.OnLoaded()
  buildButton()
  ns.UpdateButton()
  applyPopup()
end

-- scriptErrors is an account setting synced from the server after addons load, which turns the
-- popup back on; apply again once settings are in and whenever the setting changes.
local cv = CreateFrame("Frame")
cv:RegisterEvent("VARIABLES_LOADED")
cv:RegisterEvent("PLAYER_LOGIN")
cv:RegisterEvent("CVAR_UPDATE")
cv:SetScript("OnEvent", function(_, event, name)
  if not ns.db then return end
  if event ~= "CVAR_UPDATE" or (type(name) == "string" and name:lower() == "scripterrors") then applyPopup() end
end)

SLASH_EVERROR1, SLASH_EVERROR2 = "/err", "/everror"
SlashCmdList.EVERROR = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  if msg == "" then toggleWindow()
  elseif msg == "last" or msg == "all" then toggleWindow(msg)
  elseif msg == "clear" then
    local s = C.Current(ns.db); wipe(s.errors); s.dropped = nil; ns.UpdateButton(); refresh(); say("cleared this session's errors.")
  elseif msg == "popup" then
    ns.db.popupOff = not ns.db.popupOff
    if not ns.db.popupOff then ns.db.restoreScriptErrors = true end
    applyPopup()
    say("Blizzard's error popup " .. (ns.db.popupOff and "off (errors go to the ! button)." or "back on."))
  elseif msg == "test" then
    -- thrown on the next frame: an error inside the chat box's send handler leaves the box stuck open
    C_Timer.After(0, function() error("Everror test error") end)
  else
    say("/err - copy window  |  /err last, /err all  |  /err clear  |  /err popup (Blizzard popup on/off)  |  /err test")
  end
end
