-- Unit + smoke tests for Everblock. Run from addon/tools: luajit test_everblock.lua
local fails, passes = 0, 0
local function check(ok, what)
  if ok then passes = passes + 1 else fails = fails + 1; print("FAIL " .. what) end
end

local ns = {}
assert(loadfile("../Everblock/Core.lua"))("Everblock", ns)
local C = ns.Core

-- keys
check(C.GuildKey('  "Olympus" ') == "olympus", "guild key trims quotes/space, lowercases")
check(C.GuildKey("") == nil and C.GuildKey(nil) == nil, "empty guild key")
check(C.NameKey("Macman-War") == "macman" and C.NameKey("macman") == "macman", "name key drops realm suffix")

-- guilds + learning
local db = C.Init({})
check(db.enabled and db.dim and db.memberCount == 0, "defaults")
local k, isNew = C.AddGuild(db, "Olympus")
check(k == "olympus" and isNew and db.guilds.olympus == "Olympus", "guild added")
check(select(2, C.AddGuild(db, "OLYMPUS")) == false, "re-adding is not new")
check(C.Learn(db, "Zeus-War", "Olympus", 10) == "added" and db.memberCount == 1, "member learned")
check(C.Learn(db, "Zeus", "Olympus", 11) == nil and db.members.zeus.seen == 11, "seen again, no change")
check(C.Learn(db, "Bob", "Friends", 12) == nil and db.memberCount == 1, "other guild ignored")
check(C.Blocked(db, "zeus-otherrealm") == "Olympus", "blocked by name any suffix")
check(C.Blocked(db, "Bob") == nil, "stranger not blocked")
check(C.Learn(db, "Zeus", "Friends", 13) == "left" and C.Blocked(db, "Zeus") == nil and db.memberCount == 0, "left guild forgets")
check(C.Learn(db, "Zeus", nil, 14) == nil, "guildless unknown is nothing")
C.Learn(db, "Zeus", "Olympus", 15)
check(C.Learn(db, "Zeus", nil, 16) == "left", "guildless (from /who) forgets")

-- players
C.AddPlayer(db, "Griefer-War")
check(C.Blocked(db, "griefer") == "player", "manual player blocked")
check(C.RemovePlayer(db, "Griefer") == "griefer" and C.Blocked(db, "Griefer") == nil, "manual player removed")
check(C.RemovePlayer(db, "Nobody") == nil, "removing unknown")

-- pause
C.Learn(db, "Hera", "Olympus", 20)
db.enabled = false
check(C.Blocked(db, "Hera") == nil, "paused blocks nothing")
db.enabled = true

-- remove guild forgets its members
C.AddGuild(db, "Titans"); C.Learn(db, "Kronos", "Titans", 21)
local name, n = C.RemoveGuild(db, "olympus")
check(name == "Olympus" and n == 1 and C.Blocked(db, "Hera") == nil and db.memberCount == 1, "guild removed with members")
check(C.Blocked(db, "Kronos") == "Titans", "other guild kept")

-- lists + stats
C.AddGuild(db, "Aardvarks")
local gl = C.SortedGuilds(db)
check(#gl == 2 and gl[1].name == "Aardvarks" and gl[2].members == 1, "sorted guild list with counts")
check(C.MembersOf(db, "titans")[1] == "Kronos", "members of")
check(C.StatsText(db) == "Nothing blocked yet.", "empty stats")
C.Count(db, "whisper"); C.Count(db, "whisper"); C.Count(db, "trade")
check(C.StatsText(db) == "Blocked: 2 whispers, 1 trades", "stats text: " .. C.StatsText(db))

-- member cap drops the longest unseen
local big = C.Init({})
C.AddGuild(big, "G")
for i = 1, 5003 do C.Learn(big, "P" .. i, "G", i) end
check(big.memberCount == 5000 and big.members.p1 == nil and big.members.p5003 ~= nil, "member cap")
check(C.Init(big).memberCount == 5000, "count rebuilt on load")

---------------------------------------------------------------------------
-- Smoke: load the addon against a fake WoW API and drive events, chat filters and /block.
---------------------------------------------------------------------------
do
  local function fake(extra)
    return setmetatable(extra or {}, { __index = function(t, key)
      if type(key) ~= "string" or not key:match("^%u") then return nil end
      local f = function() end
      rawset(t, key, f)
      return f
    end })
  end
  local handlers, shown = {}, {}
  local function newFrame(_, name)
    local f = fake()
    f.CreateFontString = function() local fs = fake(); fs.SetText = function(s, t) s.text = t end; return fs end
    f.CreateTexture = function() return fake() end
    f.SetScript = function(self, key, fn) self["_" .. key] = fn end
    f.IsShown = function(self) return shown[self] end
    f.Show = function(self) shown[self] = true; if self._OnShow then self._OnShow(self) end end
    f.Hide = function(self) shown[self] = false end
    f.SetShown = function(self, v) shown[self] = v; if v and self._OnShow then self._OnShow(self) end end
    f.SetText = function(self, t) self.text = t end
    f.GetText = function(self) return self.text or "" end
    f.SetAlpha = function(self, a) self.alpha = a end
    f.SetChecked = function(self, v) self.checked = v end
    f.GetChecked = function(self) return self.checked end
    f.RegisterEvent = function(self, e) self.events = self.events or {}; self.events[e] = true end
    if name then _G[name] = f end
    handlers[#handlers + 1] = f
    return f
  end
  local said = {}
  _G.print = function(s) said[#said + 1] = s end
  _G.CreateFrame = newFrame
  _G.UIParent = newFrame()
  _G.UISpecialFrames = {}
  _G.tinsert = table.insert
  _G.time = os.time
  _G.C_Timer = { NewTicker = function() return { Cancel = function() end } end }
  _G.GameTooltip = fake({ HookScript = function(self, k, fn) self.hook = fn end })

  -- units
  local units = {
    target = { name = "Zeus", guild = "Olympus" },
    mouseover = { name = "Hermes", guild = "Olympus" },
    nameplate1 = { name = "Ares", guild = "Olympus" },
    nameplate2 = { name = "Bob", guild = "Friends" },
    NPC = { name = "Apollo", guild = "Olympus" },
    player = { name = "Me" },
  }
  local secretGuild = false
  _G.issecretvalue = function(v) return v == "SECRET" end
  _G.UnitIsPlayer = function(u) return units[u] ~= nil end
  _G.UnitIsUnit = function(a, b) return a == b end
  _G.UnitExists = function(u) return units[u] ~= nil end
  _G.UnitName = function(u) return units[u] and units[u].name end
  _G.GetGuildInfo = function(u) if secretGuild then return "SECRET" end return units[u] and units[u].guild end
  local plates = {}
  for _, u in ipairs({ "nameplate1", "nameplate2" }) do plates[u] = { namePlateUnitToken = u, UnitFrame = newFrame() } end
  _G.C_NamePlate = {
    GetNamePlateForUnit = function(u) return plates[u] end,
    GetNamePlates = function() return { plates.nameplate1, plates.nameplate2 } end,
  }
  local who = {}
  local sentWho
  _G.C_FriendList = {
    GetNumWhoResults = function() return #who end,
    GetWhoInfo = function(i) return who[i] end,
    SendWho = function(q) sentWho = q end,
  }
  local filters = {}
  _G.ChatFrame_AddMessageEventFilter = function(e, fn) filters[e] = fn end
  local calls = {}
  for _, fn in ipairs({ "CancelTrade", "DeclineGroup", "CancelDuel", "DeclineGuild", "StaticPopup_Hide" }) do
    _G[fn] = function() calls[fn] = (calls[fn] or 0) + 1 end
  end
  _G.IsInRaid = function() return false end
  _G.GetNumGroupMembers = function() return 0 end
  _G.SlashCmdList = {}

  local sns = {}
  for _, file in ipairs({ "ForeverSkin.lua", "Core.lua", "Block.lua", "UI.lua" }) do assert(loadfile("../Everblock/" .. file))("Everblock", sns) end
  local function fire(...) for _, fr in ipairs(handlers) do if fr._OnEvent then fr._OnEvent(fr, ...) end end end

  fire("ADDON_LOADED", "Everblock")
  check(sns.db and EverblockDB == sns.db and sns.db.enabled, "saved vars created")
  local db = sns.db
  SlashCmdList.EVERBLOCK("guild Olympus")
  check(C.IsGuildBlocked(db, "olympus"), "/block guild")

  fire("PLAYER_TARGET_CHANGED")
  fire("UPDATE_MOUSEOVER_UNIT")
  fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
  fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
  check(db.members.zeus and db.members.hermes and db.members.ares and not db.members.bob, "learned from target/mouseover/nameplates")
  check(plates.nameplate1.UnitFrame.alpha == 0.25 and plates.nameplate2.UnitFrame.alpha == nil, "blocked nameplate dimmed only")
  fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
  check(plates.nameplate1.UnitFrame.alpha == 1, "dim reset when plate goes away")

  -- nil / secret guild never forgets
  units.target.guild = nil
  fire("PLAYER_TARGET_CHANGED")
  secretGuild = true
  fire("UPDATE_MOUSEOVER_UNIT")
  secretGuild = false
  check(db.members.zeus and db.members.hermes, "nil/secret guild keeps members")

  -- chat: blocked, counted once across chat frames
  local w = filters.CHAT_MSG_WHISPER
  local function line(fn, event, author, id) return fn({}, event, "hi", author, "", "", "", "", 0, 0, "", 0, id) end
  check(line(w, "CHAT_MSG_WHISPER", "Zeus-War", 5) == true, "whisper from member filtered")
  check(line(w, "CHAT_MSG_WHISPER", "Zeus-War", 5) == true and db.stats.whisper == 1, "second chat frame, counted once")
  check(line(w, "CHAT_MSG_WHISPER", "Bob", 6) == false, "whisper from stranger shown")
  check(line(filters.CHAT_MSG_CHANNEL, "CHAT_MSG_CHANNEL", "Hermes", 7) == true and db.stats.chat == 1, "trade/general channel filtered")
  check(line(w, "CHAT_MSG_WHISPER", "SECRET", 8) == false, "secret author passes through")

  -- trade, party, duel, guild invite
  fire("TRADE_SHOW")
  check(calls.CancelTrade == 1 and db.members.apollo and db.stats.trade == 1, "trade from member (learned on the spot) cancelled")
  fire("PARTY_INVITE_REQUEST", "Zeus")
  check(calls.DeclineGroup == 1 and db.stats.party == 1, "party invite declined")
  fire("PARTY_INVITE_REQUEST", "Bob")
  check(calls.DeclineGroup == 1, "stranger's invite left alone")
  fire("DUEL_REQUESTED", "Ares")
  check(calls.CancelDuel == 1, "duel cancelled")
  fire("GUILD_INVITE_REQUEST", "Newbie", "Olympus")
  check(calls.DeclineGuild == 1 and db.members.newbie, "guild invite declined by guild name, inviter learned")
  fire("GUILD_INVITE_REQUEST", "Bob", "Friends")
  check(calls.DeclineGuild == 1, "other guild invite left alone")

  -- /who
  who = { { fullName = "Athena-War", fullGuildName = "Olympus" }, { fullName = "Zeus-War", fullGuildName = "" } }
  fire("WHO_LIST_UPDATE")
  check(db.members.athena and not db.members.zeus, "/who learns members and forgets the guildless")
  SlashCmdList.EVERBLOCK("scan")
  check(sentWho == 'g-"Olympus"', "/block scan sends /who: " .. tostring(sentWho))

  -- tooltip
  local lines = {}
  local tip = { GetUnit = function() return "Hermes", "mouseover" end, AddLine = function(_, t) lines[#lines + 1] = t end }
  GameTooltip.hook(tip)
  check(lines[1] and lines[1]:find("Olympus", 1, true), "tooltip marks blocked guild")

  -- /block target on a guildless player, pause, window
  units.target = { name = "Loner" }
  SlashCmdList.EVERBLOCK("target")
  check(db.players.loner == "Loner", "/block target guildless -> player")
  SlashCmdList.EVERBLOCK("pause")
  check(not db.enabled and line(w, "CHAT_MSG_WHISPER", "Hermes", 9) == false, "paused lets chat through")
  SlashCmdList.EVERBLOCK("pause")
  SlashCmdList.EVERBLOCK("")
  check(shown[_G.EverblockFrame] == true, "/block opens window")
  SlashCmdList.EVERBLOCK("unguild olympus")
  check(not C.IsGuildBlocked(db, "Olympus") and not db.members.hermes, "/block unguild")
  SlashCmdList.EVERBLOCK("help")
  check(#said > 5, "help printed")
end

for _, f in ipairs({ "Core.lua", "Block.lua", "UI.lua" }) do
  local src = io.open("../Everblock/" .. f):read("*a"):gsub("%-%-[^\n]*", "")
  local bad = src:match("[^%w_]os%.%w+") or src:match("[^%w_]io%.%w+")
  check(not bad, f .. " uses " .. tostring(bad) .. ", which WoW doesn't have")
end

io.write(("Everblock tests: %d passed, %d failed\n"):format(passes, fails))
os.exit(fails == 0 and 0 or 1)
