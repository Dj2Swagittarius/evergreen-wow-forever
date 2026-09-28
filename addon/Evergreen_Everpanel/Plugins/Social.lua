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

-- ask the server for a fresh roster at most every ROSTER_EVERY seconds (GUILD_ROSTER_UPDATE redraws)
local ROSTER_EVERY, lastRoster = 10, nil
local function RequestRoster()
  local now = GetTime()
  if lastRoster and now - lastRoster < ROSTER_EVERY then return end
  lastRoster = now
  if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() elseif GuildRoster then GuildRoster() end
end

EP.Add{ id = "guild", label = "Guild", side = "left", icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
  events = { "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE" },
  visible = function() return IsInGuild and IsInGuild() and true or false end,
  text = function() return tostring(#OnlineGuild()) end,
  tooltip = function(tt)
    RequestRoster()
    Tip(tt, OnlineGuild(), "Nobody online")
  end,
  onClick = function()
    if ToggleGuildFrame then ToggleGuildFrame() elseif ToggleFriendsFrame then ToggleFriendsFrame(3) end
  end,
}
