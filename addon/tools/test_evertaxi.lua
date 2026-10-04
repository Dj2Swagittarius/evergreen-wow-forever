-- Unit + smoke tests for Evertaxi. Run from addon/tools: luajit test_evertaxi.lua
local fails, passes = 0, 0
local function check(ok, what)
  if ok then passes = passes + 1 else fails = fails + 1; print("FAIL " .. what) end
end

local ns = {}
assert(loadfile("../Evertaxi/Core.lua"))("Evertaxi", ns)
local C = ns.Core

-- words
check(C.HasWord("WTB summon to BRD!", "brd"), "word match ignores case/punctuation")
check(not C.HasWord("lfm brdx", "brd"), "no partial word")
check(C.HasWord("anyone summon to dire maul?", "dire maul"), "phrase match")
check(C.HasWord("port to zul'farrak", "zul'farrak"), "apostrophe kept")

-- summon places
local brd = C.PlacesFor("Blackrock Mountain", "Blackrock Depths")
local labels = {}
for _, p in ipairs(brd) do labels[p.label] = true end
check(labels["blackrock mountain"] and labels["blackrock depths"] and labels.brd and labels.ubrs, "places for Blackrock Mountain")
check(#C.PlacesFor("Nowhere") == 1, "unknown zone is just its name")

-- summon classify
local S = function(msg, places) return C.Classify(msg, places or brd, "summon") end
check(S("WTB summon to BRD") == "here", "wtb summon brd")
check(select(2, S("any lock around for a summ to ubrs? will tip")) == "ubrs", "lock + ubrs, place returned")
check(S("LF warlock summon to Stratholme") == "elsewhere", "other place")
check(S("WTS summons to BRD, pst") == nil, "another warlock advertising")
check(S("LFM BRD need tank") == nil, "no summon word")
check(S("lock and key") == nil, "weak word without buying word")
check(S("need a lock for a summon") == "elsewhere", "no place named")
check(S("the sum of it all is brd") == nil, "'sum' without buying word")

-- portals
local horde = C.PortalPlaces("Horde", function(id) return id ~= 11420 end)
check(#horde == 3 and horde[1].label == "Orgrimmar" and horde[3].known == false, "horde portals, TB not learned")
local ally = C.PortalPlaces("Alliance")
local P = function(msg) return C.Classify(msg, ally, "portal") end
check(select(2, P("WTB port to IF")) == "Ironforge", "wtb port if")
check(select(2, P("anyone port to darn if possible?")) == "Darnassus", "'if' as a word loses to a real city")
check(select(2, P("LF mage portal to stormwind pls")) == "Stormwind", "mage portal stormwind")
check(P("WTB port to Orgrimmar") == "elsewhere", "other faction's city")
check(P("selling portals from tanaris") == nil, "other mage advertising")
check(P("the port is nice") == nil, "port without buying word")

-- fill
check(C.Fill("to {zone} for {price} {nope}", { zone = "BRD", price = "5g" }) == "to BRD for 5g {nope}", "fill")

---------------------------------------------------------------------------
-- Smoke: fake WoW API, both modes
---------------------------------------------------------------------------
local function run(class, faction)
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
    f.Hide = function(self) shown[self] = false; if self._OnHide then self._OnHide(self) end end
    f.SetShown = function(self, v) if v then self:Show() else self:Hide() end end
    f.SetText = function(self, t) self.text = t end
    f.GetText = function(self) return self.text or "" end
    f.SetChecked = function(self, v) self.checked = v end
    f.GetChecked = function(self) return self.checked end
    f.SetAttribute = function(self, k, v) self.attr = self.attr or {}; self.attr[k] = v end
    f.GetFrameLevel = function() return 1 end
    f.RegisterEvent = function() end
    if name then _G[name] = f end
    handlers[#handlers + 1] = f
    return f
  end
  local said, sent, invited = {}, {}, {}
  _G.print = function(s) said[#said + 1] = s end
  _G.CreateFrame = newFrame
  _G.UIParent = newFrame()
  _G.UISpecialFrames = {}
  _G.tinsert = table.insert
  _G.time = os.time
  _G.GameTooltip = fake()
  _G.ChatFontNormal = {}
  _G.UnitClass = function() return class, class end
  _G.UnitName = function() return "Me" end
  _G.UnitFactionGroup = function() return faction end
  _G.GetRealZoneText = function() return "Blackrock Mountain" end
  _G.GetSubZoneText = function() return "" end
  _G.IsInGuild = function() return true end
  _G.GetChannelList = function() return 1, "General", false, 2, "Trade", false end
  _G.GetChannelName = function(n) return n == "General" and 1 or n == "Trade" and 2 or 0 end
  _G.SendChatMessage = function(msg, kind, _, target) sent[#sent + 1] = { msg = msg, kind = kind, target = target } end
  _G.C_PartyInfo = { InviteUnit = function(n) invited[#invited + 1] = n end }
  _G.InCombatLockdown = function() return false end
  _G.IsPlayerSpell = function(id) return id == 698 or id == 11416 or id == 10059 end
  _G.GetSpellInfo = function(id) return "Spell" .. id, nil, "icon" .. id end
  _G.SetPortraitTexture = function() end
  _G.PlaySound = function() end
  _G.SlashCmdList = {}
  EvertaxiDB = nil

  local sns = {}
  for _, file in ipairs({ "ForeverSkin.lua", "Core.lua", "Taxi.lua" }) do assert(loadfile("../Evertaxi/" .. file))("Evertaxi", sns) end
  local function fire(...) for _, fr in ipairs(handlers) do if fr._OnEvent then fr._OnEvent(fr, ...) end end end
  fire("ADDON_LOADED", "Evertaxi")
  return sns, fire, said, sent, invited, shown
end

do -- warlock
  local sns, fire, said, sent, invited, shown = run("WARLOCK", "Horde")
  check(sns.Mode() == "summon", "warlock mode")
  local db = sns.db
  check(db and not db.open and db.chats["CHANNEL:Trade"], "defaults: closed, trade ticked")
  fire("CHAT_MSG_CHANNEL", "WTB summon to BRD", "Buyer-War", "", "", "", "", 0, 2, "Trade")
  check(#said == 0, "closed: chat ignored")
  SlashCmdList.EVERTAXI("")
  check(shown[_G.EvertaxiFrame], "/taxi opens window")
  check(_G.EvertaxiCast1 and _G.EvertaxiCast1.attr.spell == "Spell698" and shown[_G.EvertaxiCast1], "ritual button set up and shown")
  _G.EvertaxiFrame.Open:GetScript("OnClick")
end

do -- warlock requests, posting
  local sns, fire, said, sent, invited, shown = run("WARLOCK", "Horde")
  local db = sns.db
  SlashCmdList.EVERTAXI("open")
  SlashCmdList.EVERTAXI("")
  fire("CHAT_MSG_CHANNEL", "WTB summon to BRD", "Buyer-War", "", "", "", "", 0, 2, "Trade")
  check(said[#said]:find("Buyer", 1, true) and said[#said]:find("brd", 1, true), "request announced with place")
  check(_G.EvertaxiFrame.NoRequests and not shown[_G.EvertaxiFrame.NoRequests], "request listed")
  fire("CHAT_MSG_CHANNEL", "LF summon to Strat", "Other", "", "", "", "", 0, 2, "Trade")
  local n = #said
  check(n == #said, "elsewhere not announced")
  fire("CHAT_MSG_WHISPER", "sum pls", "Whisperer")
  check(said[#said]:find("Whisperer", 1, true), "whisper answering the advert")
  fire("CHAT_MSG_CHANNEL", "WTB summon to BRD", "Me-War", "", "", "", "", 0, 2, "Trade")
  check(not said[#said]:find("Me%-War"), "own messages ignored")
  db.price = "5g"
  SlashCmdList.EVERTAXI("post")
  local chans = {}
  for _, m in ipairs(sent) do chans[m.target or m.kind] = m.msg end
  check(chans[1] and chans[2] and chans[1]:find("Blackrock Mountain", 1, true) and chans[1]:find("5g", 1, true), "advert posted to General and Trade")
  local before = #sent
  SlashCmdList.EVERTAXI("post")
  check(#sent == before, "post cooldown")
  db.autoReply = true
  fire("CHAT_MSG_WHISPER", "summon?", "Asker")
  check(sent[#sent].kind == "WHISPER" and sent[#sent].target == "Asker", "auto-reply whispered")
  sns.Invite({ name = "Asker" })
  check(invited[1] == "Asker", "invite")
end

do -- mage
  local sns, fire, said, sent = run("MAGE", "Alliance")
  check(sns.Mode() == "portal", "mage mode")
  SlashCmdList.EVERTAXI("open")
  SlashCmdList.EVERTAXI("")
  check(_G.EvertaxiCast1.attr.spell == "Spell10059" and _G.EvertaxiCast2.attr.spell == "Spell11416", "portal buttons for learned portals")
  fire("CHAT_MSG_CHANNEL", "WTB port to IF", "Dwarf", "", "", "", "", 0, 2, "Trade")
  check(said[#said]:find("Ironforge", 1, true), "portal request to a learned city")
  local n = #said
  fire("CHAT_MSG_CHANNEL", "WTB port to Darnassus", "Elf", "", "", "", "", 0, 2, "Trade")
  check(#said == n, "unlearned portal not announced")
  sns.db.chats = { SAY = true }
  SlashCmdList.EVERTAXI("post")
  check(sent[#sent].kind == "SAY" and sent[#sent].msg:find("Stormwind, Ironforge", 1, true), "portal advert lists learned cities")
  sns.Reply({ name = "Dwarf", place = "Ironforge" })
  check(sent[#sent].msg:find("port you to Ironforge", 1, true), "reply names the city")
end

for _, f in ipairs({ "Core.lua", "Taxi.lua" }) do
  local src = io.open("../Evertaxi/" .. f):read("*a"):gsub("%-%-[^\n]*", "")
  local bad = src:match("[^%w_]os%.%w+") or src:match("[^%w_]io%.%w+")
  check(not bad, f .. " uses " .. tostring(bad) .. ", which WoW doesn't have")
end

io.write(("Evertaxi tests: %d passed, %d failed\n"):format(passes, fails))
os.exit(fails == 0 and 0 or 1)
