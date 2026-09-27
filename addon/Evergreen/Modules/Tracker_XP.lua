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
