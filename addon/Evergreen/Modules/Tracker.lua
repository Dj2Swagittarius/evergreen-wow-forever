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
