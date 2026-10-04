-- Everblock core: the blocked-guild list, learned members, manual players and counters. Pure Lua
-- (no WoW API), so it runs in the LuaJIT tests as well as in game.
--
-- WoW only tells us a player's guild for a unit we can see (target, mouseover, nameplate, group,
-- trade partner) or a /who result. Chat carries no guild, so members are learned whenever such a
-- unit shows up and remembered by name; chat and invites are then blocked by that name.
local _, ns = ...
local C = {}
ns.Core = C

local MAX_MEMBERS = 5000

-- Guild names: case-insensitive, surrounding spaces and quotes ignored.
function C.GuildKey(g)
  if type(g) ~= "string" then return nil end
  g = g:gsub('^[%s"]+', ""):gsub('[%s"]+$', "")
  if g == "" then return nil end
  return g:lower()
end

-- Player names: "Name", "Name-Realm" and "name" are the same player (Forever shows a realm-ish
-- suffix like "-War" on some names; chat senders carry it, UnitName doesn't).
function C.NameKey(n)
  if type(n) ~= "string" then return nil end
  n = n:match("^%s*([^%-%s]+)")
  return n and n:lower() or nil
end

local function display(n) return (n:match("^%s*([^%-%s]+)")) end

function C.Init(db)
  db.guilds = db.guilds or {}    -- key -> display name
  db.members = db.members or {}  -- name key -> { name, guild = key, seen }
  db.players = db.players or {}  -- name key -> display name (blocked by hand)
  db.stats = db.stats or {}      -- kind -> count
  db.memberCount = 0
  for _ in pairs(db.members) do db.memberCount = db.memberCount + 1 end
  if db.enabled == nil then db.enabled = true end
  if db.dim == nil then db.dim = true end
  return db
end

function C.AddGuild(db, g)
  local k = C.GuildKey(g)
  if not k then return nil end
  local isNew = db.guilds[k] == nil
  if isNew then db.guilds[k] = g:gsub('^[%s"]+', ""):gsub('[%s"]+$', "") end
  return k, isNew
end

-- Removes the guild and forgets its learned members. Returns the display name and member count.
function C.RemoveGuild(db, g)
  local k = C.GuildKey(g)
  local name = k and db.guilds[k]
  if not name then return nil end
  db.guilds[k] = nil
  local n = 0
  for mk, m in pairs(db.members) do
    if m.guild == k then db.members[mk] = nil; n = n + 1 end
  end
  db.memberCount = db.memberCount - n
  return name, n
end

function C.IsGuildBlocked(db, g)
  local k = C.GuildKey(g)
  return k ~= nil and db.guilds[k] ~= nil
end

function C.AddPlayer(db, n)
  local k = C.NameKey(n)
  if not k then return nil end
  db.players[k] = display(n)
  return k
end

function C.RemovePlayer(db, n)
  local k = C.NameKey(n)
  local had = k and (db.players[k] or db.members[k])
  if not had then return nil end
  db.players[k] = nil
  if db.members[k] then db.members[k] = nil; db.memberCount = db.memberCount - 1 end
  return k
end

-- Drop the longest-unseen members once the list outgrows its cap.
local function trim(db)
  if db.memberCount <= MAX_MEMBERS then return end
  local list = {}
  for k, m in pairs(db.members) do list[#list + 1] = { k, m.seen or 0 } end
  table.sort(list, function(a, b) return a[2] < b[2] end)
  for i = 1, db.memberCount - MAX_MEMBERS do db.members[list[i][1]] = nil end
  db.memberCount = MAX_MEMBERS
end

-- A player was seen in `guild` (nil = seen without a guild). Keeps members of blocked guilds and
-- forgets anyone known to have left one. Returns "added", "left" or nil.
function C.Learn(db, name, guild, now)
  local k = C.NameKey(name)
  if not k then return nil end
  local gk = C.GuildKey(guild)
  local m = db.members[k]
  if gk and db.guilds[gk] then
    if m then
      local changed = m.guild ~= gk
      m.guild, m.seen = gk, now
      return changed and "added" or nil
    end
    db.members[k] = { name = display(name), guild = gk, seen = now }
    db.memberCount = db.memberCount + 1
    trim(db)
    return "added"
  elseif m then
    db.members[k] = nil
    db.memberCount = db.memberCount - 1
    return "left"
  end
end

-- Returns the reason a player is blocked ("guild display name" or "player"), else nil.
function C.Blocked(db, name)
  if not db.enabled then return nil end
  local k = C.NameKey(name)
  if not k then return nil end
  if db.players[k] then return "player" end
  local m = db.members[k]
  if m and db.guilds[m.guild] then return db.guilds[m.guild] end
end

function C.Count(db, kind)
  db.stats[kind] = (db.stats[kind] or 0) + 1
end

function C.MembersOf(db, g)
  local k = C.GuildKey(g)
  local out = {}
  for _, m in pairs(db.members) do
    if m.guild == k then out[#out + 1] = m.name end
  end
  table.sort(out)
  return out
end

function C.SortedGuilds(db)
  local out = {}
  for k, name in pairs(db.guilds) do
    local n = 0
    for _, m in pairs(db.members) do if m.guild == k then n = n + 1 end end
    out[#out + 1] = { key = k, name = name, members = n }
  end
  table.sort(out, function(a, b) return a.key < b.key end)
  return out
end

function C.SortedPlayers(db)
  local out = {}
  for _, name in pairs(db.players) do out[#out + 1] = name end
  table.sort(out)
  return out
end

local STAT_ORDER = { "chat", "whisper", "trade", "party", "duel", "guild" }
local STAT_LABEL = { chat = "chat lines", whisper = "whispers", trade = "trades", party = "party invites",
  duel = "duels", guild = "guild invites" }

function C.StatsText(db)
  local out = {}
  for _, k in ipairs(STAT_ORDER) do
    local n = db.stats[k] or 0
    if n > 0 then out[#out + 1] = n .. " " .. STAT_LABEL[k] end
  end
  return #out > 0 and ("Blocked: " .. table.concat(out, ", ")) or "Nothing blocked yet."
end
