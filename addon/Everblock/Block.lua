-- Everblock game side: learn guild members from visible units and /who, filter chat, turn away
-- trades, party invites, duels and guild invites, dim nameplates, mark tooltips.
local ADDON, ns = ...
local C = ns.Core

local PINK = "|cffff7fbf"
function ns.Say(text) print(PINK .. "Everblock:|r " .. text) end

-- Modern clients can hand out "secret" values (combat/instance restrictions); treat them as unknown.
local function usable(v)
  if v == nil then return false end
  if issecretvalue and issecretvalue(v) then return false end
  return true
end

---------------------------------------------------------------------------
-- Learning
---------------------------------------------------------------------------
local function unitIsPlayer(unit)
  local ok, yes = pcall(UnitIsPlayer, unit)
  return ok and usable(yes) and yes
end

local dimUnit -- set below

-- Look at a unit: remember it if its guild is blocked, forget it if it left.
function ns.LearnUnit(unit)
  local db = ns.db
  if not db or not unitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
  local ok, name = pcall(UnitName, unit)
  if not ok or not usable(name) then return end
  local gok, guild = pcall(GetGuildInfo, unit)
  if not gok or not usable(guild) then guild = nil end
  -- a unit's guild is often still loading (nil), so only a different guild forgets a member here;
  -- /who is the reliable "no guild any more"
  local what = guild and C.Learn(db, name, guild, time())
  if what == "added" and db.announce then ns.Say(("learned %s <%s>"):format(name, guild)) end
  if what then ns.Refresh() end
  if unit:find("^nameplate") then dimUnit(unit) end
end

-- /who results carry the guild for every player listed.
local function learnWho()
  local db = ns.db
  if not db or not C_FriendList or not C_FriendList.GetNumWhoResults then return end
  local added = 0
  for i = 1, C_FriendList.GetNumWhoResults() do
    local info = C_FriendList.GetWhoInfo(i)
    if info and usable(info.fullName) then
      if C.Learn(db, info.fullName, info.fullGuildName ~= "" and info.fullGuildName or nil, time()) == "added" then
        added = added + 1
      end
    end
  end
  if added > 0 then ns.Say(("learned %d member%s from /who."):format(added, added == 1 and "" or "s")); ns.Refresh() end
end

-- Queue one /who per blocked guild. SendWho needs a keypress, so each step runs from a slash
-- command or button click: /block scan sends the next query.
local scanQueue = {}
function ns.ScanNext()
  if #scanQueue == 0 then
    for _, g in ipairs(C.SortedGuilds(ns.db)) do scanQueue[#scanQueue + 1] = g.name end
    if #scanQueue == 0 then ns.Say("no guilds blocked yet."); return end
  end
  local g = table.remove(scanQueue, 1)
  C_FriendList.SendWho('g-"' .. g .. '"')
  ns.Say(("searching /who for <%s>%s"):format(g,
    #scanQueue > 0 and (" (%d more: /block scan again)"):format(#scanQueue) or ""))
end

---------------------------------------------------------------------------
-- Nameplates and tooltips
---------------------------------------------------------------------------
local DIM = 0.25
local dimmed = {}

function dimUnit(unit)
  if not C_NamePlate then return end
  local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
  if not ok or not plate or (plate.IsForbidden and plate:IsForbidden()) then return end
  local frame = plate.UnitFrame
  if not frame then return end
  local name = UnitName(unit)
  local blocked = ns.db.dim and usable(name) and C.Blocked(ns.db, name)
  if blocked then
    frame:SetAlpha(DIM); dimmed[frame] = true
  elseif dimmed[frame] then
    frame:SetAlpha(1); dimmed[frame] = nil
  end
end

function ns.RefreshPlates()
  if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
  for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
    local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    if unit then ns.LearnUnit(unit) end
  end
end

local function tooltipUnit(tip)
  if not ns.db or not tip.GetUnit then return end
  local ok, _, unit = pcall(tip.GetUnit, tip)
  if not ok or not unit then return end
  ns.LearnUnit(unit)
  local name = UnitName(unit)
  local why = usable(name) and C.Blocked(ns.db, name)
  if why then
    tip:AddLine(why == "player" and "Blocked player (Everblock)" or ("Blocked guild <%s> (Everblock)"):format(why), 1, 0.5, 0.75)
  end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tip)
    if tip == GameTooltip then tooltipUnit(tip) end
  end)
elseif GameTooltip and GameTooltip.HookScript then
  GameTooltip:HookScript("OnTooltipSetUnit", tooltipUnit)
end

---------------------------------------------------------------------------
-- Chat
---------------------------------------------------------------------------
local CHAT_EVENTS = {
  CHAT_MSG_WHISPER = "whisper", CHAT_MSG_SAY = "chat", CHAT_MSG_YELL = "chat", CHAT_MSG_EMOTE = "chat",
  CHAT_MSG_TEXT_EMOTE = "chat", CHAT_MSG_CHANNEL = "chat",
}
local lastLine = {}

-- Every chat frame runs the filter for the same line; count each line once by its line id.
local function filter(_, event, msg, author, ...)
  local db = ns.db
  if not db or not usable(author) then return false end
  if not C.Blocked(db, author) then return false end
  local lineID = select(9, ...)
  if lineID == nil or lastLine[event] ~= lineID then
    lastLine[event] = lineID
    C.Count(db, CHAT_EVENTS[event])
    ns.Refresh()
  end
  return true
end

for event in pairs(CHAT_EVENTS) do ChatFrame_AddMessageEventFilter(event, filter) end

---------------------------------------------------------------------------
-- Trades, invites, duels
---------------------------------------------------------------------------
local function hidePopup(which)
  if StaticPopup_Hide then StaticPopup_Hide(which) end
end

local function turnedAway(kind, who, why)
  C.Count(ns.db, kind)
  ns.Refresh()
  if not ns.db.quiet then
    ns.Say(("declined %s from %s (%s)."):format(kind == "party" and "party invite" or kind == "guild" and "guild invite" or kind,
      who, why == "player" and "blocked player" or ("<" .. why .. ">")))
  end
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT",
  "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "GROUP_ROSTER_UPDATE", "WHO_LIST_UPDATE", "TRADE_SHOW",
  "PARTY_INVITE_REQUEST", "DUEL_REQUESTED", "GUILD_INVITE_REQUEST" }) do
  pcall(f.RegisterEvent, f, e)
end

f:SetScript("OnEvent", function(_, event, a1, a2)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    EverblockDB = EverblockDB or {}
    ns.db = C.Init(EverblockDB)
    return
  end
  local db = ns.db
  if not db then return end
  if event == "PLAYER_LOGIN" then
    if C_Timer then C_Timer.NewTicker(3, ns.RefreshPlates) end
  elseif event == "PLAYER_TARGET_CHANGED" then ns.LearnUnit("target")
  elseif event == "UPDATE_MOUSEOVER_UNIT" then ns.LearnUnit("mouseover")
  elseif event == "NAME_PLATE_UNIT_ADDED" then ns.LearnUnit(a1)
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, a1)
    if ok and plate and plate.UnitFrame and dimmed[plate.UnitFrame] then plate.UnitFrame:SetAlpha(1); dimmed[plate.UnitFrame] = nil end
  elseif event == "GROUP_ROSTER_UPDATE" then
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do ns.LearnUnit(prefix .. i) end
  elseif event == "WHO_LIST_UPDATE" then learnWho()
  elseif event == "TRADE_SHOW" then
    ns.LearnUnit("NPC")
    local name = UnitName("NPC")
    local why = usable(name) and C.Blocked(db, name)
    if why then CancelTrade(); turnedAway("trade", name, why) end
  elseif event == "PARTY_INVITE_REQUEST" then
    local why = usable(a1) and C.Blocked(db, a1)
    if why then DeclineGroup(); hidePopup("PARTY_INVITE"); turnedAway("party", a1, why) end
  elseif event == "DUEL_REQUESTED" then
    local why = usable(a1) and C.Blocked(db, a1)
    if why then CancelDuel(); hidePopup("DUEL_REQUESTED"); turnedAway("duel", a1, why) end
  elseif event == "GUILD_INVITE_REQUEST" then
    -- the invite names the guild, so this works even for someone we haven't seen before
    if db.enabled and usable(a2) and C.IsGuildBlocked(db, a2) then
      if usable(a1) then C.Learn(db, a1, a2, time()) end
      DeclineGuild(); hidePopup("GUILD_INVITE"); turnedAway("guild", usable(a1) and a1 or "?", db.guilds[C.GuildKey(a2)])
    end
  end
end)
