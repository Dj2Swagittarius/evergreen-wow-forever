-- Evertaxi core: which chat lines are people asking for a warlock summon to where you are, or a
-- mage portal to a city you can open one to; place names; the advert text. Pure Lua (no WoW API),
-- so it runs in the LuaJIT tests.
--
-- A "place" is { label, words }: the label is what the checkbox shows, the words what chat says.
local _, ns = ...
local C = {}
ns.Core = C

-- Short names players use for places, by zone. The zone's own name is always a place too.
C.ZONE_ALIASES = {
  ["Blackrock Mountain"] = { "brd", "lbrs", "ubrs", "brs", "mc", "bwl", "blackrock", "molten core" },
  ["Searing Gorge"] = { "brd", "lbrs", "ubrs", "brs", "mc", "bwl", "blackrock", "searing" },
  ["Burning Steppes"] = { "brd", "lbrs", "ubrs", "brs", "mc", "bwl", "blackrock", "steppes" },
  ["Tanaris"] = { "zf", "zul'farrak", "zul farrak", "gadgetzan", "gtz" },
  ["Desolace"] = { "mara", "maraudon" },
  ["Feralas"] = { "dm", "dire maul", "diremaul", "dme", "dmw", "dmn", "tribute" },
  ["Western Plaguelands"] = { "scholo", "scholomance", "wpl" },
  ["Eastern Plaguelands"] = { "strat", "stratholme", "strath", "epl", "naxx" },
  ["Swamp of Sorrows"] = { "st", "sunken temple", "sunken" },
  ["Badlands"] = { "ulda", "uldaman" },
  ["Stranglethorn Vale"] = { "stv", "zg", "zul'gurub", "booty bay", "bb" },
  ["Dustwallow Marsh"] = { "ony", "onyxia", "dwm" },
  ["Silithus"] = { "aq", "aq20", "aq40", "ahn'qiraj" },
  ["Tirisfal Glades"] = { "sm", "scarlet", "monastery" },
  ["The Barrens"] = { "wc", "wailing", "rfk", "rfd", "barrens" },
  ["Stonetalon Mountains"] = { "stonetalon" },
  ["Winterspring"] = { "ws", "everlook", "winterspring" },
  ["Un'Goro Crater"] = { "ungoro", "un'goro", "crater" },
  ["Azshara"] = { "azshara", "azuregos" },
  ["Blasted Lands"] = { "blasted", "kazzak" },
  ["Alterac Mountains"] = { "alterac" },
  ["Hillsbrad Foothills"] = { "hillsbrad", "tarren mill", "tm", "southshore", "ss" },
  ["Arathi Highlands"] = { "arathi", "hammerfall", "refuge" },
  ["Wetlands"] = { "wetlands", "menethil" },
  ["Silverpine Forest"] = { "sfk", "shadowfang", "silverpine" },
  ["Westfall"] = { "dm", "deadmines", "westfall" },
  ["Ashenvale"] = { "bfd", "ashenvale" },
  ["Thousand Needles"] = { "needles", "rfd", "shimmering flats" },
}

local function lower(s) return (s or ""):lower() end

-- Summon places for a zone and subzone: their names plus known short names, one place per word.
function C.PlacesFor(zone, subzone)
  local out, seen = {}, {}
  local function add(p)
    p = lower(p):gsub("^%s+", ""):gsub("%s+$", "")
    if p ~= "" and not seen[p] then seen[p] = true; out[#out + 1] = { label = p, words = { p } } end
  end
  add(zone)
  if subzone and subzone ~= zone then add(subzone) end
  for _, a in ipairs(C.ZONE_ALIASES[zone] or {}) do add(a) end
  return out
end

-- Whole-word (or whole-phrase) match, case-insensitive; apostrophes count as letters.
local function escape(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end
function C.HasWord(text, word)
  text = " " .. lower(text):gsub("[^%w']+", " ") .. " "
  word = lower(word):gsub("[^%w']+", " ")
  return text:find(" " .. escape(word) .. " ") ~= nil
end

-- Mage portals: spell ID, city, what players call it.
C.PORTALS = {
  { spell = 11417, faction = "Horde", label = "Orgrimmar", words = { "orgrimmar", "org", "og", "orgri", "orgrimar" } },
  { spell = 11418, faction = "Horde", label = "Undercity", words = { "undercity", "uc" } },
  { spell = 11420, faction = "Horde", label = "Thunder Bluff", words = { "thunder bluff", "tb", "thunderbluff" } },
  { spell = 10059, faction = "Alliance", label = "Stormwind", words = { "stormwind", "sw", "storm wind" } },
  { spell = 11416, faction = "Alliance", label = "Ironforge", words = { "ironforge", "if", "iron forge" } },
  { spell = 11419, faction = "Alliance", label = "Darnassus", words = { "darnassus", "darn", "darna" } },
}

-- Portal places for a faction; known(spellID) says which the mage has learned.
function C.PortalPlaces(faction, known)
  local out = {}
  for _, p in ipairs(C.PORTALS) do
    if p.faction == faction then
      -- known(spellID, city) may answer with the spell ID the client really uses for that portal
      local k = known == nil or known(p.spell, p.label) or false
      out[#out + 1] = { label = p.label, words = p.words, spell = type(k) == 'number' and k or p.spell, known = k ~= false }
    end
  end
  return out
end

local ASK = {
  summon = { "summon", "summons", "summ", "summs", "sum", "summo", "sumon", "lock", "warlock", "port" },
  portal = { "portal", "portals", "port", "ports", "porty", "mage", "tele", "teleport" },
}
local WEAK = { lock = true, port = true, sum = true, mage = true, tele = true }
local WANT = { "wtb", "lf", "lfs", "need", "needs", "needing", "looking", "any", "anyone", "anybody", "someone",
  "somebody", "can", "could", "pls", "please", "plz", "pay", "paying", "tip", "buy", "buying", "want", "who" }
local SELLING = { "wts", "selling", "sell", "offering", "lfw", "available", "summoning", "portals from" }

local AMBIGUOUS = { ["if"] = true, st = true, dm = true, ss = true, tm = true, bb = true, ws = true, sm = true,
  wc = true, og = true, uc = true }

local function any(text, list)
  for _, w in ipairs(list) do if C.HasWord(text, w) then return w end end
end

-- Is `msg` someone asking for a summon (kind "summon") or a portal (kind "portal")? Returns
-- "here" and the place label when it names one of `places`, "elsewhere" when it asks for one but
-- names no place we serve, or nil for everything else (chatter, others advertising).
function C.Classify(msg, places, kind)
  if type(msg) ~= "string" or msg == "" then return nil end
  local s = any(msg, ASK[kind or "summon"])
  if not s then return nil end
  if any(msg, SELLING) then return nil end
  -- "lock"/"port"/"sum"/"mage" on their own are common words; want a buying word with them
  if WEAK[s] and not any(msg, WANT) then return nil end
  -- plain English words that are also place names ("if" = Ironforge) only count when nothing
  -- clearer matched: "port to darn if possible" is Darnassus
  for pass = 1, 2 do
    for _, p in ipairs(places or {}) do
      for _, w in ipairs(p.words) do
        if (pass == 2) == (AMBIGUOUS[w] == true) and C.HasWord(msg, w) then return "here", p.label end
      end
    end
  end
  return "elsewhere"
end

-- Fill the advert: {zone}, {places}, {price} and {name}.
function C.Fill(text, vars)
  return (text or ""):gsub("{(%w+)}", function(k)
    local v = vars[k:lower()]
    return v ~= nil and tostring(v) or "{" .. k .. "}"
  end)
end

C.DEFAULTS = {
  summon = {
    ad = "Summons to {zone} - {price}. Whisper me \"sum\" and I'll invite you!",
    reply = "Hi! I can summon you to {zone} for {price}. Sending an invite now.",
  },
  portal = {
    ad = "Portals from {zone} to {places} - {price}. Whisper me \"port\" + city!",
    reply = "Hi! I can port you from {zone} for {price}. Sending an invite now.",
  },
}
