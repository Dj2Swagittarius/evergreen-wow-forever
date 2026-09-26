-- Evergreen routes: Skyborne. Horde "The Falling Sky" (skyborne-horde) and Alliance "The Violet Road"
-- (skyborne-alliance). Loaded after Data.lua and Routes_Tauren.lua; appends two routes to ns.ROUTES.
-- Step format is documented at the top of Data.lua. Class steps carry cls=.
--
-- Race file name: UnitRace() for the Skyborne is unknown until the beta client is inspected; the
-- Wowhead race ids are 95 (High Order, Alliance) and 96 (Windshaper, Horde). This file uses "Skyborne"
-- for both. The engine cannot tell Horde Skyborne from Alliance Skyborne by race alone: RouteFits
-- scores a race match 3 and a faction match 2, so BOTH routes score 3 for any Skyborne and the first
-- listed wins. The Horde route is registered first; an Alliance Skyborne must run
-- `/eg route skyborne-alliance` until the integrator adds faction-aware race matching
-- (e.g. score race AND faction = 4).
--
-- Zephras Isle (zone 16593 in the beta client) has no known uiMapID; its brackets use map 0 (verify)
-- and carry no coordinates, so the arrow stays idle there and steps are ticked by hand or by quest
-- name. Only two Zephras quest names are public ("Among the Faithful", "A Firm Response"); everything
-- else on the isle is a hub-by-hub story beat from beta tester reports and is marked (verify).
--
-- Horde: Zephras x4, then the Tauren Barrens / Stonetalon-Ashenvale / Thousand Needles brackets
-- (ns.TAUREN_BRACKETS[3..5]) and the shared Horde brackets ns.BRACKETS[7..12]. Horde rogue chains
-- (Tauren cannot be rogues, so Routes_Tauren.lua never added them) are injected here into t3 and b11;
-- they are class-gated so no other class sees them.
-- Alliance: Zephras x4, a Loch Modan 12-20 leg written here (s5), then ns.ALLIANCE_BRACKETS from
-- Routes_Human.lua (a4..a11). If that file is missing the Alliance route simply ends at 20.
local ADDON, ns = ...

ns.MAP_NAMES[0]    = ns.MAP_NAMES[0]    or "Zephras Isle (map id unknown, verify)"
ns.MAP_NAMES[1432] = ns.MAP_NAMES[1432] or "Loch Modan"
ns.MAP_NAMES[1455] = ns.MAP_NAMES[1455] or "Ironforge"
ns.MAP_NAMES[1426] = ns.MAP_NAMES[1426] or "Dun Morogh"
ns.MAP_NAMES[1437] = ns.MAP_NAMES[1437] or "Wetlands"
ns.MAP_NAMES[1439] = ns.MAP_NAMES[1439] or "Darkshore"
ns.MAP_NAMES[1453] = ns.MAP_NAMES[1453] or "Stormwind City"
ns.MAP_NAMES[1457] = ns.MAP_NAMES[1457] or "Darnassus"
ns.MAP_NAMES[1416] = ns.MAP_NAMES[1416] or "Alterac Mountains"
ns.MAP_NAMES[1436] = ns.MAP_NAMES[1436] or "Westfall"
ns.MAP_NAMES[1433] = ns.MAP_NAMES[1433] or "Redridge Mountains"

local ZEP, BAR, MUL, TB, MG, LOCH, IF, DM, WET, DS, SW, DARN = 0, 1413, 1412, 1456, 1450, 1432, 1455, 1426, 1437, 1439, 1453, 1457
local MG_DENDRITE = {56,30,"Dendrite Starblaze, Nighthaven, Moonglade",MG}
local TB_ELDER    = {76,27,"Turak Runetotem, Elder Rise, Thunder Bluff (verify: the Horde druid quest giver for a Skyborne)",TB}
local DARN_BEAR   = {38,22,"Mathrengyl Bearwalker, Cenarion Enclave, Darnassus (verify: the Alliance druid quest giver for a Skyborne)",DARN}
local IF_MUREN    = {66,89,"Muren Stormpike, Hall of Arms, Military Ward, Ironforge",IF}
local IF_TORMUS   = {49,43,"Tormus Deepforge, the Great Forge, Ironforge (verify)",IF}
local IF_HULFDAN  = {52,15,"Hulfdan Blackbeard, Forlorn Cavern, Ironforge",IF}
local IF_BINK     = {27,8,"Bink, Hall of Mysteries, Mystic Ward, Ironforge (verify)",IF}
local SW_JENNEA   = {39,82,"Jennea Cannon, Wizard's Sanctum, Mage Quarter, Stormwind",SW}
local ORG_THERZOK = {0,0,"Therzok, Cleft of Shadow, Orgrimmar (verify coords)",1454}
local ORG_SHENTHUL = {0,0,"Shenthul, Cleft of Shadow, Orgrimmar (verify coords)",1454}

-- ================================================================== Zephras Isle 1-12 (shared by both factions)
local ZEPHRAS_SHARED = {
  -- ============================================================ 1-5 Thendal Village
  {
    id="s1", lv={1,5}, name="Thendal Village", map=ZEP,
    hub="Thendal Village (north-west corner)", hearth="Bound to Thendal at creation (verify)", fp="None known on the isle (verify)",
    steps={
      {note="Before you move", t="Turn on Auto Loot. Bind a key to Walk on Air (2 min glide, breaks falls). Both factions start in the same village and play the same quests; class trainers stand in the village (verify). Level split between the four hubs is an estimate (verify)."},
      {man="Take every quest in Thendal Village. The opening beats: the wind spirits are gone, the anchor pylons are failing, and Al'Aketh cultists are inside the village. Wildlife and cult kills around Thendal Grove, Thendal Cave and the Thendal Standing Stones (verify names of the quests; no list is public)."},
      {man="Shriekling Den and Nightclaw Cavern are the two named beast lairs near the start; expect a collect quest in each (verify)."},
      {man="Level 4 shaman: every Horde shaman gets Call of Earth at 4 from the starting-camp trainer (Earth Totem, Stoneskin Totem). Ask your Thendal shaman trainer; the Skyborne version is unreported (verify).", cls="SHAMAN"},
      {forever=true, t="Blessing of Zephras (+40% run speed for 5 min, breaks on hostile action) is datamined for this zone; find its source object (verify). Read Ley Line and Skysight get their 15-minute duration at special isle locations."},
      {lv=5},
    },
  },
  -- ============================================================ 5-8 Shen'dar Village
  {
    id="s2", lv={5,8}, name="Shen'dar Village & the Highlands", map=ZEP,
    hub="Shen'dar Village (Shen'dar Highlands)", hearth="Bind here if the village has an inn (verify); otherwise the hearth stays at Thendal", fp="None known (verify)",
    steps={
      {man="Walk south out of Thendal into the Shen'dar Highlands. There is no breadcrumb quest between the two villages; just go (beta testers complained about it)."},
      {note="Among the Faithful", t="A stealth quest: hide behind the wardrobe in the cultists' house and eavesdrop. The protective buff drops if you log out, so finish it in one sitting. It was bugged on Sep 17-18 (wardrobe did not spawn): relog to another layer or restart the client if it happens to you."},
      {q="Among the Faithful", o={0,0,"Eavesdrop on the Al'Aketh cultists from behind the wardrobe (verify)"}, r={0,0,"Constable Aonda, Shen'dar Village (verify)"}},
      {man="Constable Aonda's follow-ups: Aonda's Written Report is a quest item in the beta client, so expect a delivery or two from him (verify)."},
      {man="The farmland loop: bandits at the Bandit Hideout (a camping scroll in the cave gives a temporary fire-damage weapon buff), corrupted wildlife in the Gustberry Lowlands and Windfield Orchard, and Fairweather Stables (verify which hub gives these)."},
      {lv=8},
    },
  },
  -- ============================================================ 8-10 Falaath Village
  {
    id="s3", lv={8,10}, name="Falaath Village & the Overlook", map=ZEP,
    hub="Falaath Village (position unverified)", hearth="As before (verify)", fp="None known (verify)",
    steps={
      {man="Falaath Village is the third, minor hub (verify its position). The Windshaper / High Order rivalry escalates here: you witness a secret meeting between a High Order magister and the Al'Aketh, the cultists murder the magister, and the High Order blame you."},
      {man="Overlook Standing Stones and the Rise of Spirits: expect the spirit-side quests here (verify)."},
      {man="Shrine of Akir is the Al'Aketh (Al'Akir cult) stronghold; the bridge quests at the shrine are the last thing before the capital (verify)."},
      {man="Druid enclave near the end of the zone: quests take you to Friendly with a reputation (Windshapers or High Order, verify), then a repeatable cultist-ear turn-in. Do the quests, skip the grind."},
      {lv=10},
    },
  },
}

-- 10-12 Valanaar: built per faction so the level-10 class quests point at the right capital.
local function Valanaar(faction)
  local steps = {
    {man="Escort the cult defector to Valanaar; he is found dead but leaves intel that the Al'Aketh plan to destroy the anchor pylons hiding the isle (verify)."},
    {man="Valanaar is the capital, neutral to both factions. Train at 10 here (verify which trainers exist). The Valanaar Skydocks have one airship dock per faction; the Windshaper dock flies to Mulgore and the High Order dock (Kirin Tor flag) to Dalaran (verify)."},
  }
  local horde = faction == "Horde"
  -- hunter: the isle has its own taming chain
  table.insert(steps, {man="Level 10 hunter: the isle has a Classic-style pet chain (three Taming the Beast rods for local winged beasts, which show as the Fox family after taming, then Beast Training). Beta bug: if pet training is greyed out, dismiss, abandon and re-tame (verify names).", cls="HUNTER"})
  -- druid: Moonglade chain works for Skyborne
  table.insert(steps, {q="Heeding the Call", cls="DRUID", g={0,0,"Your druid trainer, Valanaar (verify)"}, r=(horde and TB_ELDER or DARN_BEAR)})
  table.insert(steps, {q="Moonglade", cls="DRUID", g=(horde and TB_ELDER or DARN_BEAR), r=MG_DENDRITE})
  table.insert(steps, {q="Great Bear Spirit", cls="DRUID", g=MG_DENDRITE, o={39,27,"Talk to the Great Bear Spirit west along the mountains, finish its dialogue",MG}, r=MG_DENDRITE})
  table.insert(steps, {q=(horde and "Back to Thunder Bluff" or "Back to Darnassus"), cls="DRUID", g=MG_DENDRITE, r=(horde and TB_ELDER or DARN_BEAR)})
  if horde then
    table.insert(steps, {man="Druid: Body and Heart's Moonkin Stone for Horde is in the Barrens west of Camp Taurajo; it is the first step of the Barrens bracket. From Moonglade the druid-only wind rider (Bunthen Plainswind) flies to Thunder Bluff (verify a Skyborne can use it).", cls="DRUID"})
    table.insert(steps, {q="Call of Fire", p=1, cls="SHAMAN", g={0,0,"Your shaman trainer, Valanaar (verify); any Horde shaman trainer gives it"}, r={56,20,"Kranal Fiss, Grol'dom Farm north of the Crossroads (verify)",BAR}})
    table.insert(steps, {q="Veteran Uzzek", cls="WARRIOR", g={0,0,"Your warrior trainer, Valanaar (verify); every Horde warrior trainer gives it"}, r={62,31,"Uzzek, under a tree south-west of Far Watch Post, Barrens (verify)",BAR}})
    table.insert(steps, {q="Therzok", cls="ROGUE", g={0,0,"Your rogue trainer, Valanaar (verify); the Orc/Troll breadcrumb is Kaplak in Razor Hill"}, r=ORG_THERZOK})
    table.insert(steps, {q="The Shattered Hand", cls="ROGUE", g=ORG_THERZOK, o={63,40,"Pickpocket Tazan's key from the troll south of Ratchet, open his satchel (verify coords)",BAR}, r={0,0,"Therzok: Blade of Cunning",1454}})
  else
    table.insert(steps, {man="Druid: Body and Heart's Alliance Moonkin Stone is in the cave east of Auberdine, Darkshore (43,46). From Moonglade the druid-only hippogryph (Leora) flies to Rut'theran; boat to Auberdine, do it, hearth. It is the first druid step of the Loch Modan bracket (verify a Skyborne can use the druid flight).", cls="DRUID"})
    table.insert(steps, {man="Warrior, rogue and mage: the Alliance level-10 chains are race-specific (Stormwind, Ironforge or Darnassus). Which one a Skyborne gets is unreported; this route assumes the Ironforge versions and puts them in the Loch Modan bracket (verify).", cls={WARRIOR=true, ROGUE=true, MAGE=true}})
  end
  table.insert(steps, {note="A Firm Response", t="The finale: Windshapers and High Order agree to a truce, you confront the High Order magister Belathaan Brightwish, High Priestess Lorthuna and two Living Storms spawn. Then the portal to the floating Skywall tower: Rohash appears, the Earthen Ring (Muln Earthfury) and Kirin Tor (Ansirem Runeweaver) arrive, you beat back Rohash's elementals. Was bugged Sep 18 (NPC stops after one line); fixed within a day."})
  table.insert(steps, {q="A Firm Response", o={0,0,"Confront Belathaan Brightwish; kill Lorthuna's Living Storms (verify)"}})
  table.insert(steps, {man="Sanctum of Storms, Rohashi Spires and the Ruins of Ban'aethal (north-east, Shadowgale Forest, a sleeping Altarius parked there) are the end-of-zone areas. Testers finish at 13-14, so leave at 12 with quests still in the log if you like."})
  table.insert(steps, {man=(horde and "Airship from the Windshaper dock at the Valanaar Skydocks to the new plateau on the northern cliffs of Mulgore (verify name, flight master and whether it is gated on the finale)." or "Airship from the High Order dock at the Valanaar Skydocks to Dalaran, Alterac Mountains (inferred from the Kirin Tor flag; nobody has posted the Alliance arrival yet, verify).")})
  table.insert(steps, {forever=true, t="Everything on this isle is beta data. Blizzard calls Zephras a self-contained experience you do not return to; do not expect endgame here."})
  table.insert(steps, {lv=12})
  return {
    id=(horde and "s4" or "s4a"), lv={10,12}, name="Valanaar & the Sanctum of Storms", map=ZEP,
    hub="Valanaar (capital, neutral)", hearth="Valanaar inn if one exists (verify)", fp="Valanaar Skydocks: airship off the isle",
    steps=steps,
  }
end

ns.SKYBORNE_BRACKETS = {}
for _, b in ipairs(ZEPHRAS_SHARED) do table.insert(ns.SKYBORNE_BRACKETS, b) end
table.insert(ns.SKYBORNE_BRACKETS, Valanaar("Horde"))
table.insert(ns.SKYBORNE_BRACKETS, Valanaar("Alliance"))

-- ================================================================== Alliance 12-20: Loch Modan
local LOCH_MODAN = {
  id="s5", lv={12,20}, name="Loch Modan", map=LOCH,
  hub="Thelsamar", hearth="Ironforge (Innkeeper Firebrew, Stonefire Tavern) on arrival, then Thelsamar (Innkeeper Hearthstove)", fp="Ironforge (Gryth Thurden), Thelsamar (Thorgrum Borrelson)",
  steps={
    {tr=true, x=55, y=48, map=IF, any=true, t="From Dalaran ride south through Alterac into Hillsbrad and on to Southshore, staying on the road (mobs are 20-30). Fly Southshore to Ironforge. If Forever gives Dalaran a flight master or a breadcrumb to a 12-20 area, take that instead (verify)."},
    {bind="Ironforge", x=18, y=51, map=IF},
    {fp="Ironforge", x=55, y=48, map=IF},
    {note="Why Loch Modan", t="It is 10-20, one flight from Ironforge, and its north road drops straight into the Wetlands at 20 where the Alliance 20-25 bracket starts. Ironforge holds the likely Skyborne class-quest NPCs and the Deeprun Tram to Stormwind. Darkshore would mean a Menethil boat and a Kalimdor start; Westfall a longer Stormwind detour."},
    -- level 10-12 class quests, Ironforge versions (verify that a Skyborne gets these rather than Stormwind's or Darnassus')
    {q="Muren Stormpike", cls="WARRIOR", g={66,89,"Any warrior trainer (verify); Hall of Arms, Military Ward, Ironforge",IF}, r=IF_MUREN},
    {q="Vejrek", cls="WARRIOR", g=IF_MUREN, o={27,57,"Vejrek, Frostmane troll south of Frostmane Hold, Dun Morogh; loot his head",DM}, r={66,89,"Muren Stormpike: Defensive Stance, Taunt, Sunder Armor",IF}},
    {q="Tormus Deepforge", cls="WARRIOR", g=IF_MUREN, r=IF_TORMUS},
    {q="Ironband's Compound", cls="WARRIOR", g=IF_TORMUS, o={77,61,"Umbral Ore from the chest at Ironband's Compound, east Dun Morogh; Captain Beld (11) and Dark Iron dwarves guard it",DM}, r=IF_TORMUS},
    {q="Grey Iron Weapons", cls="WARRIOR", g=IF_TORMUS, r={49,43,"Tormus: pick a Grey Iron weapon",IF}},
    {q="Road to Salvation", cls="ROGUE", g={52,15,"Any rogue trainer (verify); Forlorn Cavern, Ironforge",IF}, r=IF_HULFDAN},
    {q="Simple Subterfugin'", cls="ROGUE", g=IF_HULFDAN, r={25,44,"Onin MacHammar outside Gnomeregan, west Dun Morogh",DM}},
    {q="Onin's Report", cls="ROGUE", g={25,44,"Onin MacHammar",DM}, r={52,15,"Hulfdan Blackbeard: Blade of Cunning",IF}},
    {q="Speak with Bink", cls="MAGE", g={27,8,"Any mage trainer (verify); Human mages get Speak with Jennea in Stormwind instead",IF}, r=IF_BINK},
    {q="Mage-tastic Gizmonitor", cls="MAGE", g=IF_BINK, o={28,36,"Bink's Gizmonitor in the huts outside Gnomeregan, west Dun Morogh (verify)",DM}, r={27,8,"Bink: Ley Orb or Ley Staff (verify)",IF}},
    {q="Body and Heart", cls="DRUID", g=DARN_BEAR, o={43,46,"Cenarion Lunardust at the Moonkin Stone in the cave east of Auberdine, Darkshore; kill Lunaclaw (12). Reach Auberdine from Moonglade via the druid hippogryph to Rut'theran and the boat (verify)",DS}, r={38,22,"Mathrengyl Bearwalker: Bear Form (verify)",DARN}},
    -- Loch Modan proper
    {tr=true, x=34, y=48, t="Fly Ironforge to Thelsamar (or walk the south-east road out of Dun Morogh through South Gate Pass)."},
    {bind="Thelsamar", x=35, y=48},
    {fp="Thelsamar", x=34, y=51},
    {note="Pickup sweep", t="Mountaineer Kadrell patrols the road by the inn, Vidra Hearthstove at the bar, Brock in the hut east of town, Jern Hornhelm in the south-east house, Magistrate Bluntnose. Learn First Aid in Ironforge if you did not (Ironforge Physician, 55,58). Skip Stout to Kadrell: it starts in Dun Morogh."},
    {q="Rat Catching", g={34,48,"Mountaineer Kadrell"}, o={35,19,"12 Tunnel Rat Ears from the kobolds outside Silver Stream Mine and the camps west of the north road"}},
    {q="Mountaineer Stormpike's Task", g={34,48,"Mountaineer Kadrell"}, r={25,18,"Mountaineer Stormpike, Algaz Station tower, upstairs"}},
    {q="Thelsamar Blood Sausages", g={35,49,"Vidra Hearthstove"}, o={40,40,"3 Bear Meat, 3 Spider Ichor, 3 Boar Intestines from the bears, lurkers and boars north of town"}},
    {q="Honor Students", g={37,48,"Brock, hut east of town"}, r={34,51,"Thorgrum Borrelson"}},
    {q="Ride to Ironforge", opt=true, g={34,51,"Thorgrum Borrelson"}, r={51,26,"Deep Mountain Mining Guild, Ironforge",IF}},
    {q="Gryth Thurden", opt=true, g={51,26,"Deep Mountain Mining Guild",IF}, r={55,48,"Gryth Thurden, the Great Forge",IF}},
    {q="Return to Brock", opt=true, g={55,48,"Gryth Thurden",IF}, r={37,48,"Brock"}},
    {q="Filthy Paws", g={25,18,"Mountaineer Stormpike, Algaz Station"}, o={35,19,"4 Miners' Gear from crates inside Silver Stream Mine; kobolds come in threes, pull to the entrance"}},
    {q="Stormpike's Order", opt=true, g={25,18,"Mountaineer Stormpike"}, r={0,0,"Furen Longbeard, Dwarven District, Stormwind (tram); do it when a mage or rogue trip takes you there (verify coords)",SW}},
    {q="In Defense of the King's Lands", p=1, g={22,73,"Mountaineer Cobbleflint, Valley of Kings bunker"}, o={32,73,"10 Stonesplinter Troggs, 10 Stonesplinter Scouts in Stonesplinter Valley"}},
    {q="The Trogg Threat", g={23,74,"Captain Rugelfuss, top of the bunker tower"}, o={32,73,"8 Trogg Stone Teeth, same troggs"}},
    {lv=14},
    {q="Lessons Anew", cls="DRUID", g=DARN_BEAR, r=MG_DENDRITE},
    {q="The Principal Source", cls="DRUID", g=MG_DENDRITE, o={55,34,"Fill the sampler at Cliffspring Falls, Darkshore (verify)",DS}, r={37,44,"Alanndarian Nightsong, Auberdine",DS}},
    {q="Gathering the Cure", cls="DRUID", g={37,44,"Alanndarian Nightsong",DS}, o={40,50,"12 Lunar Fungus from the Auberdine caves, 5 Earthroot",DS}},
    {q="Curing the Sick", cls="DRUID", g={37,44,"Alanndarian Nightsong",DS}, o={40,40,"Use the salve on 10 Sickly Deer around Auberdine",DS}, r=MG_DENDRITE},
    {q="Power over Poison", cls="DRUID", g=MG_DENDRITE, r={38,22,"Mathrengyl Bearwalker: Cure Poison",DARN}},
    {q="In Defense of the King's Lands", p=2, g={22,73,"Mountaineer Wallbang, inside the bunker"}, o={32,73,"10 Stonesplinter Skullthumpers, 10 Seers in Stonesplinter Valley"}, r={22,73,"Mountaineer Gravelgaw"}},
    {q="In Defense of the King's Lands", p=3, g={22,73,"Mountaineer Wallbang"}, o={54,26,"10 Stonesplinter Shamans, 10 Bonesnappers on the northern loch islands"}},
    {q="Report to Jennea", cls="MAGE", g={27,8,"Any mage trainer (verify)",IF}, r=SW_JENNEA},
    {q="Investigate the Blue Recluse", cls="MAGE", g=SW_JENNEA, o={47,90,"Blue Recluse tavern, Mage Quarter: reveal and capture the Rift Spawn, 3 Filled Containment Coffers (verify coords)",SW}, r=SW_JENNEA},
    {q="Gathering Materials", cls="MAGE", g=SW_JENNEA, o={35,19,"6 Charged Rift Gems from crates in Silver Stream Mine (you are there for Filthy Paws anyway), 10 Linen Cloth"}, r={44,80,"Wynne Larson, Larson Clothiers, Mage Quarter (verify coords)",SW}},
    {q="Manaweave Robe", cls="MAGE", g={44,80,"Wynne Larson",SW}, r={44,80,"Wynne Larson: Manaweave Robe",SW}},
    {lv=16},
    {q="A Lesson to Learn", cls="DRUID", g=DARN_BEAR, r=MG_DENDRITE},
    {q="Trial of the Lake", cls="DRUID", g=MG_DENDRITE, o={52,40,"Shrine Bauble from the bottom of Lake Elune'ara; use it at the Shrine of Remulos (36,41), talk to Tajarri. 30 minutes",MG}, r={36,40,"Tajarri, Shrine of Remulos",MG}},
    {q="Trial of the Sea Lion", cls="DRUID", g={36,40,"Tajarri",MG}, o={49,11,"Alliance halves: between two boulders in the far-north Darkshore sea (49,11) and off the Westfall coast at 18,33, deep. Combine at the shrine (verify a Skyborne gets the Alliance halves)",DS}, r=MG_DENDRITE},
    {q="Aquatic Form", cls="DRUID", g=MG_DENDRITE, r={38,22,"Mathrengyl Bearwalker: Aquatic Form, Aquarius Belt",DARN}},
    {man="Rogue level 16: the trainer breadcrumb (To Hulfdan!) leads to Redridge Rendezvous with Lucius in Lakeshire and Alther's Mill east of town (lockbox practice, Certificate of Thievery). Do it at 20 when the route opens in Redridge.", cls="ROGUE"},
    {q="Ironband's Excavation", g={36,49,"Jern Hornhelm, south-east house, Thelsamar"}, r={65,65,"Magmar Fellhew, Ironband's Excavation: round the south tip of the loch, then east"}},
    {q="Gathering Idols", g={65,65,"Magmar Fellhew"}, o={66,64,"8 Carved Stone Idols from the Stonesplinter troggs at the dig"}},
    {q="Excavation Progress Report", g={65,65,"Prospector Ironband"}, r={36,49,"Jern Hornhelm"}},
    {q="Report to Ironforge", g={36,49,"Jern Hornhelm"}, r={74,10,"Prospector Stormpike, Hall of Explorers, Ironforge (verify coords)",IF}},
    {q="Powder to Ironband", g={74,10,"Prospector Stormpike",IF}, r={36,49,"Jern Hornhelm"}},
    {q="Resupplying the Excavation", g={36,49,"Jern Hornhelm"}, r={50,66,"Huldar on the south shore of the loch (verify); a Dark Iron ambush fires when you arrive"}},
    {q="After the Ambush", g={50,66,"Huldar"}, r={50,66,"Miran, beside him (respawns in about 2 minutes)"}},
    {q="Protecting the Shipment", g={50,66,"Miran"}, o={65,65,"Escort Miran to the dig; two Dark Iron Raiders jump you on the way"}, r={65,65,"Prospector Ironband"}},
    {q="Crocolisk Hunting", g={82,62,"Marek Ironheart, Farstrider Lodge"}, o={55,54,"5 Crocolisk Meat, 6 Crocolisk Skins from Loch Crocolisks on the southern and middle islands"}},
    {q="A Hunter's Boast", g={82,62,"Daryl the Youngling, Farstrider Lodge"}, o={77,74,"6 Mountain Buzzards south-west of the lodge, 15-minute timer"}},
    {q="A Hunter's Challenge", g={82,62,"Daryl the Youngling"}, o={70,50,"Elder Mountain Boars north-west, 12-minute timer (5 or 8, verify)"}},
    {q="Vyrin's Revenge", p=1, g={82,62,"Vyrin Swiftwind, Farstrider Lodge"}, o={42,65,"Ol' Sooty on Grizzlepaw Ridge, 20-minute respawn; group of 2"}, r={82,62,"Daryl the Youngling"}},
    {q="Vyrin's Revenge", p=2, g={82,62,"Daryl the Youngling"}, r={82,62,"Vyrin Swiftwind"}},
    {lv=18},
    {q="Find Bingles", opt=true, g={0,0,"Gnoarn, Tinker Town, Ironforge (verify coords)",IF}, r={64,47,"Bingles Blastenheimer, east shore of the loch"}},
    {q="Bingles' Missing Supplies", opt=true, g={64,47,"Bingles Blastenheimer"}, o={54,26,"Blastencapper (54,26 hut), Hammer (52,24 wreckage), Wrench (49,30 west island), Screwdriver (48,20 north-west camp); 5-minute respawns"}},
    {q="Mercenaries", g={35,49,"Magistrate Bluntnose, Thelsamar"}, o={72,22,"Mo'grosh Enforcers and Brutes at the Mo'grosh Stronghold, north-east corner of the loch (counts verify)"}},
    {q="WANTED: Chok'sul", opt=true, g={35,49,"Magistrate Bluntnose"}, o={72,21,"Chok'sul, level-20 elite ogre in the Mo'grosh cave; group (verify level)"}},
    {q="A Dark Threat Looms", p=1, g={47,13,"Chief Engineer Hinderweir VII, Stonewrought Dam"}, o={56,13,"Suspicious Barrel east of the dam"}, r={47,13,"Chief Engineer Hinderweir VII"}},
    {q="A Dark Threat Looms", p=2, g={47,13,"Chief Engineer Hinderweir VII"}, o={55,15,"2 Dark Iron Sappers (17) around the dam"}},
    {q="A Dark Threat Looms", p=3, opt=true, g={47,13,"Chief Engineer Hinderweir VII"}, o={72,22,"Follow the quest text: the later parts run through the Mo'grosh ogres and Dark Iron dwarves (verify; seven parts, 18-20)"}},
    {man="Grizzlepaw Ridge (south-west of the loch): bears, boars and spiders 11-15 for the Blood Sausage parts and the last bars to 20.", x=42, y=65},
    {forever=true, t="No Forever change is reported for Loch Modan. The Wetlands expansion (new content north of here) is the thing to watch at 20."},
    {lv=20},
    {tr=true, x=11, y=52, map=WET, t="Wetlands road at 20: north past Algaz Station through Dun Algaz, then north and west to Menethil Harbor. Flight point from Shellei Brondir; the Alliance 20-25 bracket starts here."},
  },
}
table.insert(ns.SKYBORNE_BRACKETS, LOCH_MODAN)

-- Shared Horde rogue chains (poisons at 20 in t3, Ravenholdt/Sunken Temple at 50 in b11) are injected once by Routes_Troll.lua.

-- ================================================================== routes
-- Horde: Zephras s1-s4, Tauren t3 (Barrens 12-20), t4, t5, then the shared Horde brackets from 30-35 on.
local HORDE_ROUTE = {}
for _, b in ipairs(ns.SKYBORNE_BRACKETS) do
  if b.id == "s1" or b.id == "s2" or b.id == "s3" or b.id == "s4" then table.insert(HORDE_ROUTE, b) end
end
if ns.TAUREN_BRACKETS then
  for i = 3, 5 do if ns.TAUREN_BRACKETS[i] then table.insert(HORDE_ROUTE, ns.TAUREN_BRACKETS[i]) end end
end
for i = 7, #ns.BRACKETS do table.insert(HORDE_ROUTE, ns.BRACKETS[i]) end

-- Alliance: Zephras s1-s3 + s4a, Loch Modan s5, then ns.ALLIANCE_BRACKETS (Routes_Human.lua, a4..a11).
local ALLIANCE = ns.ALLIANCE_BRACKETS or {}
local ALLIANCE_ROUTE = {}
for _, b in ipairs(ns.SKYBORNE_BRACKETS) do
  if b.id == "s1" or b.id == "s2" or b.id == "s3" or b.id == "s4a" or b.id == "s5" then table.insert(ALLIANCE_ROUTE, b) end
end
for _, b in ipairs(ALLIANCE) do table.insert(ALLIANCE_ROUTE, b) end

-- Horde first: see the header for why order matters until race+faction matching exists.
table.insert(ns.ROUTES, {
  id = "skyborne-horde", name = "The Falling Sky", faction = "Horde",
  races = { Skyborne = true }, raceOnly = 4,
  brackets = HORDE_ROUTE,
})
table.insert(ns.ROUTES, {
  id = "skyborne-alliance", name = "The Violet Road", faction = "Alliance",
  races = { Skyborne = true }, raceOnly = 4,
  brackets = ALLIANCE_ROUTE,
})

ns.RACIAL_SPELLS = ns.RACIAL_SPELLS or {}
-- Walk on Air 1259416, Skysight 1259686 (Horde), Read Ley Line 1259705 (Alliance): beta spell ids (verify).
ns.RACIAL_SPELLS.Skyborne = ns.RACIAL_SPELLS.Skyborne or { { "Walk on Air", 1259416 }, { "Skysight", 1259686 }, { "Read Ley Line", 1259705 } }
