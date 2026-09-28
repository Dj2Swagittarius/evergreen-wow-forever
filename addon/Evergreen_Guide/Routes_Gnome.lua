-- Evergreen route: Gnome ("The Long Tinker"). Loaded after Data.lua and Routes_Human.lua; appends to ns.ROUTES.
-- Step format is documented at the top of Data.lua. Class steps carry cls="WARRIOR" etc.
-- Three race-only brackets (Coldridge Valley, Kharanos and Dun Morogh, Loch Modan), then the shared
-- Alliance 20-60 brackets that Routes_Human.lua defines in ns.ALLIANCE_BRACKETS. Nothing is added there:
-- the faction-wide chains (rogue Poisons, warlock Succubus/Felhunter/Felsteed/Dreadsteed, warrior
-- Fire Hardened/Islander/Whirlwind/Fallen Hero, mage Tabetha/Xylem, priest Cenarion Aid) already live in it.
-- Gnome Priest is Forever-only: a note at 10, and the shared level-50 chain from ns.ALLIANCE_BRACKETS.
local ADDON, ns = ...

-- Map ids this file uses. Routes_Human.lua normally registers them first; guard anyway.
ns.MAP_NAMES[1426] = ns.MAP_NAMES[1426] or "Dun Morogh"
ns.MAP_NAMES[1432] = ns.MAP_NAMES[1432] or "Loch Modan"
ns.MAP_NAMES[1455] = ns.MAP_NAMES[1455] or "Ironforge"
ns.MAP_NAMES[1453] = ns.MAP_NAMES[1453] or "Stormwind City"
ns.MAP_NAMES[1429] = ns.MAP_NAMES[1429] or "Elwynn Forest"
ns.MAP_NAMES[1433] = ns.MAP_NAMES[1433] or "Redridge Mountains"
ns.MAP_NAMES[1431] = ns.MAP_NAMES[1431] or "Duskwood"
ns.MAP_NAMES[1436] = ns.MAP_NAMES[1436] or "Westfall"

local DM, LM, IF, SW, ELW, RR, DW, WF = 1426, 1432, 1455, 1453, 1429, 1433, 1431, 1436

local IF_MUREN   = {71,90,"Muren Stormpike, Hall of Arms, Military Ward, Ironforge",IF}
local IF_TORMUS  = {49,43,"Tormus Deepforge, the Great Forge, Ironforge",IF}
local IF_HULFDAN = {52,15,"Hulfdan Blackbeard, Forlorn Cavern, Ironforge",IF}
local IF_BINK    = {27,8,"Bink, Hall of Mysteries, Mystic Ward, Ironforge",IF}
local IF_STORMPIKE = {74,11,"Prospector Stormpike, Hall of Explorers, Ironforge (verify)",IF}
local SW_GAKIN   = {27,77,"Gakin the Darkbinder, Slaughtered Lamb cellar, Mage Quarter, Stormwind (Tram from Tinker Town)",SW}
local SW_JENNEA  = {39,82,"Jennea Cannon, Wizard's Sanctum, Mage Quarter, Stormwind (Tram from Tinker Town)",SW}

-- ================================================================== Gnome race-only brackets 1-20
ns.GNOME_BRACKETS = {
  -- ============================================================ 1-6 Coldridge Valley
  {
    id="g1", lv={1,6}, name="Coldridge Valley", map=DM,
    hub="Anvilmar", hearth="Already bound to Coldridge Valley (no inn)", fp="None",
    steps={
      {note="Before you move", t="Turn on Auto Loot. Every Gnome class trainer stands inside Anvilmar; the rune you spawn with is a free turn-in there. Felix Whindlebolt inside the hall is the first Gnome quest. Vendor and repair by the door (30,72)."},
      {q="Dwarven Outfitters", g={30,71,"Sten Stoutarm, outside Anvilmar"}, o={29,74,"8 Tough Wolf Meat from the wolves south of the hall (verify count)"}},
      {q="Coldridge Valley Mail Delivery", p=1, g={30,71,"Sten Stoutarm"}, r={23,71,"Talin Keeneye, camp west of the road"}},
      {q="A New Threat", g={30,71,"Sten Stoutarm"}, o={31,75,"14 Rockjaw Troggs east of the hall, 6 Burly Rockjaw Troggs west (verify counts)"}},
      {man="Turn in your class rune (Simple Rune, Encrypted Rune, Glyphic Memorandum or Tainted Memorandum) at your trainer inside Anvilmar.", x=29, y=68},
      {q="Beginnings", cls="WARLOCK", g={29,66,"Alamar Grimm, back of Anvilmar (verify giver)"}, o={27,80,"Frostmane Novices in the troll cave to the south; take a partner at 2-3 or wait for The Troll Cave at 4"}, r={29,66,"Alamar Grimm: Summon Imp"}},
      {q="The Boar Hunter", g={23,71,"Talin Keeneye"}, o={22,69,"12 Small Crag Boars around the camp (verify count)"}},
      {q="Coldridge Valley Mail Delivery", p=2, g={23,71,"Talin Keeneye"}, r={25,76,"Grelin Whitebeard, camp to the south"}},
      {q="The Troll Cave", g={25,76,"Grelin Whitebeard"}, o={27,80,"14 Frostmane Troll Whelps at the cave mouth (verify count)"}},
      {lv=4},
      {q="Scalding Mornbrew Delivery", g={25,76,"Grelin Whitebeard (five-minute timer; hearth to the valley floor)"}, r={29,66,"Durnan Furcutter, Anvilmar"}},
      {q="A Refugee's Quandary", g={29,68,"Felix Whindlebolt, Anvilmar"}, o={23,80,"Felix's Box (21,76), Felix's Chest (23,80), Felix's Bucket of Bolts (26,79) along the southern edge"}},
      {q="Bring Back the Mug", g={29,66,"Durnan Furcutter"}, r={25,76,"Grelin Whitebeard"}},
      {q="The Stolen Journal", g={25,76,"Grelin Whitebeard"}, o={30,80,"Grik'nir the Cold at the back of the troll cave; hug the left wall"}},
      {lv=5},
      {q="Senir's Observations", p=1, g={25,76,"Grelin Whitebeard"}, r={33,72,"Senir Whitebeard, Coldridge Pass entrance"}},
      {q="Senir's Observations", p=2, g={33,72,"Senir Whitebeard, pass entrance"}, r={46,54,"Senir Whitebeard, Kharanos"}},
      {q="Supplies to Tannok", g={34,72,"Hands Springsprocket, pass entrance (verify)"}, r={47,52,"Tannok Frosthammer, inside the Thunderbrew Distillery, Kharanos"}},
      {forever=true, t="Nothing announced touches Coldridge. A Gnome Priest starts here in Forever; expect a trainer at the back of Anvilmar and an In Favor of the Light breadcrumb to Kharanos at 4. Unpublished."},
      {lv=6},
    },
  },
  -- ============================================================ 6-12 Kharanos & Dun Morogh
  {
    id="g2", lv={6,12}, name="Kharanos & Dun Morogh, with the level-10 Ironforge trip", map=DM,
    hub="Kharanos", hearth="Thunderbrew Distillery (Innkeeper Belm)", fp="None here; Ironforge (Gryth Thurden) on the level-10 trip",
    steps={
      {tr=true, x=46, y=52, t="Through Coldridge Pass and down the road into Kharanos; kill the troggs in the pass on the way."},
      {bind="Kharanos", x=47, y=53},
      {note="Pickup sweep", t="Senir Whitebeard by the road, Ragnar Thunderbrew, Tannok inside the inn, Grundel Harkin, Belm for the bind. Learn First Aid (the physician in the inn). Mining from Yarr Hammerstone at Steelgrill's Depot (verify); Engineering waits for Tinker Town at 10."},
      {q="Beer Basted Boar Ribs", g={47,52,"Ragnar Thunderbrew"}, o={48,47,"6 Crag Boar Ribs from the boars in the fields (verify count) plus a Rhapsody Malt bought from Innkeeper Belm"}},
      {q="Tools for Steelgrill", g={46,52,"Grundel Harkin"}, r={50,49,"Beldin Steelgrill, Steelgrill's Depot"}},
      {q="Stocking Jetsteam", g={49,48,"Pilot Bellowfiz, Steelgrill's Depot"}, o={48,45,"8 Chunk of Boar Meat, 4 Thick Bear Fur from the fields around the depot (verify counts)"}},
      {q="The Grizzled Den", g={49,48,"Pilot Stonegear, Steelgrill's Depot"}, o={42,54,"6 Wendigo Manes in the cave south-west of Kharanos (verify count)"}},
      {q="Ammo for Rumbleshot", g={50,49,"Ammo crate at Steelgrill's Depot"}, r={41,65,"Hegnar Rumbleshot, camp on the road south"}},
      {lv=7},
      {q="Frostmane Hold", g={46,54,"Senir Whitebeard"}, o={23,52,"Explore the middle of the Frostmane Hold cave (25,51) and kill 5 Frostmane Headhunters"}},
      {q="Operation Recombobulation", g={46,49,"Razzle Sprysprocket, goblin hut"}, o={25,44,"8 Restabilization Cogs, 8 Gyromechanic Gears from the Leper Gnomes outside Gnomeregan (verify counts)"}},
      {q="Evershine", g={49,48,"Pilot Bellowfiz"}, r={30,46,"Rejold Barleybrew, Brewnall Village"}},
      {q="A Favor for Evershine", g={30,46,"Rejold Barleybrew"}, o={26,40,"8 Ice Claw Bears, 8 Elder Crag Boars, 8 Snow Leopards in the western snow past Iceflow Lake (verify counts)"}},
      {q="The Perfect Stout", g={30,46,"Marleth Barleybrew"}, o={38,42,"5 Shimmerweed from the baskets and Frostmane Seers at Shimmer Ridge (verify count)"}},
      {q="Bitter Rivals", g={30,46,"Marleth Barleybrew"}, o={48,53,"Buy Thunder Ale from Belm, give it to Jarven Thunderbrew in the barrel room, click the Unguarded Thunder Ale Barrel"}},
      {q="Tundra MacGrann's Stolen Stash", opt=true, g={35,52,"Tundra MacGrann, up the mountain path from 36,53"}, o={38,51,"MacGrann's Meat Locker; a level-11 elite yeti patrols the cave"}},
      {lv=8},
      {q="Shimmer Stout", g={30,46,"Marleth Barleybrew"}, r={86,49,"Mountaineer Barleybrew, South Gate Outpost"}},
      {q="Return to Marleth", g={48,53,"Jarven Thunderbrew"}, r={30,46,"Marleth Barleybrew"}},
      {q="Return to Bellowfiz", g={30,46,"Rejold Barleybrew"}, r={49,48,"Pilot Bellowfiz, Steelgrill's Depot"}},
      {q="The Reports", g={46,54,"Senir Whitebeard"}, r={39,58,"The High Seat, Ironforge (verify)",IF}},
      {q="The Public Servant", g={69,56,"Senator Mehr Stonehallow, Gol'Bolar Quarry"}, o={71,56,"10 Rockjaw Bonesnappers in the quarry mine (verify count)"}},
      {q="Those Blasted Troggs!", g={69,56,"Foreman Stonebrow, behind the tent"}, o={68,59,"6 Rockjaw Skullthumpers in the quarry (verify count)"}},
      {lv=10},
      {tr=true, x=55, y=48, map=IF, any=true, t="Level 10: Ironforge by the road north (gate 53,35). The Reports to the High Seat, train, Tinker Town for Engineering (Springspindle Fizzlegear, verify) and Gnoarn. Every level-10 class quest but the warlock's ends here or in Dun Morogh."},
      {fp="Ironforge", x=55, y=48, map=IF},
      {q="Find Bingles", g={72,48,"Gnoarn, Tinker Town, Ironforge (verify)",IF}, r={63,47,"Bingles Blastenheimer, east shore of the loch",LM}},
      {q="Muren Stormpike", cls="WARRIOR", g={47,53,"Kharanos warrior trainer, in the inn (verify giver)"}, r=IF_MUREN},
      {q="Vejrek", cls="WARRIOR", g=IF_MUREN, o={28,58,"Vejrek, the Frostmane troll in the cliff hut south of Frostmane Hold; bring his head (verify)"}, r={71,90,"Muren Stormpike: Defensive Stance, Taunt, Sunder Armor",IF}},
      {q="Tormus Deepforge", cls="WARRIOR", g=IF_MUREN, r=IF_TORMUS},
      {q="Ironband's Compound", cls="WARRIOR", g=IF_TORMUS, o={78,62,"Umbral Ore from the strongbox at Ironband's Compound, south of Helm's Bed Lake; Captain Beld (11) and Dark Iron dwarves guard it (verify)"}, r=IF_TORMUS},
      {q="Grey Iron Weapons", cls="WARRIOR", g=IF_TORMUS, r={49,43,"Tormus Deepforge: your Grey Iron weapon",IF}},
      {q="Road to Salvation", cls="ROGUE", g={48,53,"Hogral Bakkan, Kharanos inn kitchen (verify giver)"}, r=IF_HULFDAN},
      {q="Simple Subterfugin'", cls="ROGUE", g=IF_HULFDAN, r={25,44,"Onin MacHammar on the ramp outside Gnomeregan"}},
      {q="Onin's Report", cls="ROGUE", g={25,44,"Onin MacHammar"}, r={52,15,"Hulfdan Blackbeard: Blade of Cunning",IF}},
      {q="Speak with Bink", cls="MAGE", g={47,52,"Kharanos mage trainer, inn entrance"}, r=IF_BINK},
      {q="Mage-tastic Gizmonitor", cls="MAGE", g=IF_BINK, o={28,36,"Bink's Toolbox in the huts outside Gnomeregan (verify)"}, r={27,8,"Bink: staff or orb (verify)",IF}},
      {q="The Slaughtered Lamb", cls="WARLOCK", g={47,54,"Gimrizz Shadowcog, south of the Kharanos inn (verify giver)"}, r=SW_GAKIN},
      {fp="Stormwind", cls="WARLOCK", x=66, y=62, map=SW},
      {q="Surena Caledon", cls="WARLOCK", g=SW_GAKIN, o={70,78,"Kill Surena Caledon (9) at the Brackwell Pumpkin Patch, south-east Elwynn; loot her choker (verify)",ELW}, r=SW_GAKIN},
      {q="The Binding", p=1, cls="WARLOCK", g=SW_GAKIN, o={27,77,"Summon and defeat a Voidwalker at Gakin's circle",SW}, r={27,77,"Gakin the Darkbinder: Summon Voidwalker",SW}},
      {q="Protecting the Herd", opt=true, g={63,50,"Rudra Amberstill, Amberstill Ranch (verify)"}, o={62,34,"Vagash, a level-11 elite yeti up the hidden path; group, or a warlock with Fear"}},
      {q="The Lost Pilot", g={84,39,"Pilot Hammerfoot, North Gate Outpost (verify)"}, o={80,36,"The Dwarven corpse north-west of the outpost"}},
      {q="A Pilot's Revenge", g={80,36,"A Dwarven Corpse"}, o={78,38,"Mangeclaw"}, r={84,39,"Pilot Hammerfoot"}},
      {q="Stout to Kadrell", g={86,49,"Mountaineer Barleybrew, South Gate Outpost"}, r={34,48,"Mountaineer Kadrell, Thelsamar",LM}},
      {forever=true, t="No source reports Dun Morogh or Ironforge changes beyond the Gnome Priest and Dwarf Shaman trainers. Wetlands is the announced Alliance expansion and it comes at 22."},
      {lv=11},
    },
  },
  -- ============================================================ 12-20 Loch Modan
  {
    id="g3", lv={12,20}, name="Loch Modan", map=LM,
    hub="Thelsamar", hearth="Stoutlager Inn (Innkeeper Hearthstove)", fp="Thelsamar (Thorgrum Borrelson)",
    steps={
      {tr=true, x=17, y=59, t="Through South Gate Pass; it comes out at 17,59. The Valley of Kings bunker is before Thelsamar and holds two quests for the trogg valley east of it."},
      {q="In Defense of the King's Lands", p=1, g={22,73,"Mountaineer Cobbleflint, Valley of Kings bunker"}, o={32,73,"10 Stonesplinter Troggs, 10 Stonesplinter Scouts in Stonesplinter Valley"}},
      {q="The Trogg Threat", g={23,74,"Captain Rugelfuss, top of the bunker tower"}, o={32,73,"8 Trogg Stone Teeth from the same troggs"}},
      {tr=true, x=35, y=48, t="Thelsamar. Kadrell patrols the road across from the inn; Vidra is at the bar; Brock is in the hut east of town; Jern Hornhelm in the south-east house; Magistrate Bluntnose."},
      {q="Rat Catching", g={34,48,"Mountaineer Kadrell"}, o={26,42,"12 Tunnel Rat Ears from the kobold camps west of the north road and outside Silver Stream Mine (35,19)"}},
      {q="Mountaineer Stormpike's Task", g={34,48,"Mountaineer Kadrell"}, r={25,18,"Mountaineer Stormpike, Algaz Station tower, upstairs"}},
      {bind="Thelsamar", x=35, y=49},
      {fp="Thelsamar", x=34, y=51},
      {q="Thelsamar Blood Sausages", g={35,49,"Vidra Hearthstove, at the bar"}, o={38,40,"3 Bear Meat, 3 Spider Ichor, 3 Boar Intestines from the bears, lurkers and boars north of town"}},
      {q="Honor Students", g={37,48,"Brock, hut east of town (verify surname)"}, r={34,51,"Thorgrum Borrelson, gryphon master"}},
      {q="Ride to Ironforge", g={34,51,"Thorgrum Borrelson"}, r={51,26,"Deep Mountain Mining Guild, Ironforge",IF}},
      {q="Gryth Thurden", g={51,26,"Deep Mountain Mining Guild",IF}, r={55,48,"Gryth Thurden, the Great Forge",IF}},
      {q="Return to Brock", opt=true, g={55,48,"Gryth Thurden",IF}, r={37,48,"Brock, Thelsamar"}},
      {q="Ironband's Excavation", g={36,49,"Jern Hornhelm, south-east house (verify)"}, r={65,65,"Magmar Fellhew, Ironband's Excavation: round the south tip of the loch, then east"}},
      {q="Mercenaries", opt=true, g={35,48,"Magistrate Bluntnose (verify)"}, o={72,22,"Mo'grosh Enforcers and Brutes at Mo'grosh Stronghold, north-east corner of the loch; group (verify counts)"}},
      {q="WANTED: Chok'sul", opt=true, g={35,48,"Magistrate Bluntnose"}, o={72,22,"Chok'sul's Head at Mo'grosh Stronghold; a level-20 elite, group"}},
      {q="Stormpike's Order", g={25,18,"Mountaineer Stormpike"}, r={62,36,"Furen Longbeard, Dwarven District, Stormwind, by Tram (verify)",SW}},
      {q="Filthy Paws", g={25,18,"Mountaineer Stormpike"}, o={35,19,"4 Miners' Gear from the Miners' League crates inside Silver Stream Mine; group or Voidwalker"}},
      {lv=12},
      {tr=true, x=55, y=48, map=IF, any=true, t="Level 12: fly to Ironforge. Train, Ride to Ironforge to the Deep Mountain Mining Guild, Gryth Thurden. Fly back."},
      {lv=14},
      {q="In Defense of the King's Lands", p=2, g={22,73,"Mountaineer Wallbang, inside the bunker"}, o={32,73,"10 Stonesplinter Skullthumpers, 10 Seers in Stonesplinter Valley"}, r={22,73,"Mountaineer Gravelgaw, inside the bunker"}},
      {q="In Defense of the King's Lands", p=3, g={22,73,"Mountaineer Wallbang"}, o={54,26,"10 Stonesplinter Shamans, 10 Bonesnappers on the north loch islands"}},
      {q="In Defense of the King's Lands", p=4, g={23,74,"Captain Rugelfuss"}, o={30,74,"Grawmug, Gnasher and Brawler in the west cave of Stonesplinter Valley; two players"}},
      {q="Report to Jennea", cls="MAGE", g=IF_BINK, r=SW_JENNEA},
      {q="Investigate the Blue Recluse", cls="MAGE", g=SW_JENNEA, o={45,90,"Blue Recluse tavern, Mage Quarter: reveal and capture three Rift Spawn with the cantation and coffers",SW}, r=SW_JENNEA},
      {q="Gathering Materials", cls="MAGE", g=SW_JENNEA, o={35,19,"10 Linen Cloth; 6 Charged Rift Gems from the crates in Silver Stream Mine, the same mine as Filthy Paws"}, r={44,79,"Wynne Larson, Larson Clothiers, Mage Quarter, Stormwind",SW}},
      {q="Manaweave Robe", cls="MAGE", g={44,79,"Wynne Larson",SW}, r={44,79,"Wynne Larson: Manaweave Robe",SW}},
      {lv=16},
      {q="Gathering Idols", g={65,65,"Magmar Fellhew, Ironband's Excavation"}, o={65,65,"8 Carved Stone Idols from the Stonesplinter troggs at the dig"}},
      {q="Excavation Progress Report", g={65,65,"Prospector Ironband"}, r={36,49,"Jern Hornhelm, Thelsamar"}},
      {q="Report to Ironforge", g={36,49,"Jern Hornhelm"}, r=IF_STORMPIKE},
      {q="Powder to Ironband", g=IF_STORMPIKE, r={36,49,"Jern Hornhelm, Thelsamar"}},
      {q="Resupplying the Excavation", g={36,49,"Jern Hornhelm"}, r={47,60,"Huldar on the south shore road; a Dark Iron ambush (verify)"}},
      {q="After the Ambush", g={47,60,"Huldar"}, r={47,60,"Miran; he respawns in about two minutes"}},
      {q="Protecting the Shipment", g={47,60,"Miran"}, o={65,65,"Escort Miran to the dig; two Dark Iron Raiders on the way"}, r={65,65,"Prospector Ironband"}},
      {q="To Hulfdan!", cls="ROGUE", g={51,15,"Rogue trainer, Forlorn Cavern, Ironforge (verify quest name and giver)",IF}, r=IF_HULFDAN},
      {q="Redridge Rendezvous", cls="ROGUE", g=IF_HULFDAN, r={30,45,"Lucius, Lakeshire, Redridge; do it on the level-20 ride to Darkshire (verify)",RR}},
      {q="Alther's Mill", cls="ROGUE", g={30,45,"Lucius",RR}, o={44,44,"Pick the practice lockboxes at Alther's Mill east of Lakeshire until Lucius's Lockbox opens; take the Token of Thievery (verify coords)",RR}, r={30,45,"Lucius: Certificate of Thievery",RR}},
      {q="Crocolisk Hunting", g={81,61,"Marek Ironheart, Farstrider Lodge"}, o={55,54,"5 Crocolisk Meat, 6 Crocolisk Skin from the loch islands"}},
      {q="A Hunter's Boast", g={81,61,"Daryl the Youngling, Farstrider Lodge"}, o={77,74,"6 Mountain Buzzards south-west of the lodge; 15-minute timer"}},
      {q="A Hunter's Challenge", g={81,61,"Daryl the Youngling"}, o={70,50,"Elder Mountain Boars north-west of the lodge; 12-minute timer (5 or 8, verify)"}},
      {q="Vyrin's Revenge", g={81,61,"Vyrin Swiftwind, Farstrider Lodge"}, o={42,65,"Ol' Sooty on Grizzlepaw Ridge; 20-minute respawn, group"}, r={81,61,"Daryl the Youngling, then Vyrin Swiftwind"}},
      {q="Bingles' Missing Supplies", g={63,47,"Bingles Blastenheimer, east shore"}, o={52,24,"Blastencapper (54,26), Hammer (52,24), Wrench (49,30), Screwdriver (48,20) on the north islands and camps; five-minute respawns"}},
      {lv=18},
      {q="A Dark Threat Looms", p=1, g={47,13,"Chief Engineer Hinderweir VII, Stonewrought Dam"}, o={56,13,"The Suspicious Barrel east of the dam"}},
      {q="A Dark Threat Looms", p=2, g={47,13,"Chief Engineer Hinderweir VII"}, o={50,12,"2 Dark Iron Sappers around the dam (verify)"}},
      {man="The later A Dark Threat Looms parts run through the Mo'grosh ogres and the Dark Iron chain (verify). Grizzlepaw Ridge bears, boars and spiders fill the gaps to 20.", x=42, y=65},
      {forever=true, t="Nothing announced touches Loch Modan. Wetlands, one tunnel north, is the announced Alliance expansion; the shared route reaches it at 22."},
      {lv=20},
      {tr=true, x=66, y=62, map=SW, any=true, t="Level 20: fly Thelsamar to Ironforge, Tram to Stormwind. Rogues: Shaw at SI:7 for Mathias and the Defias. Warlocks: Gakin for Devourer of Souls. Collect Dungar Longdrink's flight point."},
      {fp="Stormwind", x=66, y=62, map=SW},
      {tr=true, x=31, y=59, map=RR, t="Ride out of Stormwind's east gate through Elwynn to Three Corners and Lakeshire for the flight point. Rogues: Lucius and Alther's Mill."},
      {fp="Lakeshire", x=31, y=59, map=RR},
      {tr=true, x=74, y=45, map=DW, t="South over the Lakeshire bridge into Duskwood and along the road to Darkshire for the flight point; the shared Alliance route starts there."},
      {fp="Darkshire", x=74, y=45, map=DW},
    },
  },
}

-- Gnome route = the three brackets above, then the shared Alliance brackets defined in Routes_Human.lua.
local ALLIANCE = ns.ALLIANCE_BRACKETS or {}
local ROUTE_BRACKETS = {}
for _, b in ipairs(ns.GNOME_BRACKETS) do table.insert(ROUTE_BRACKETS, b) end
for _, b in ipairs(ALLIANCE) do table.insert(ROUTE_BRACKETS, b) end

table.insert(ns.ROUTES, {
  id = "gnome", name = "The Long Tinker", faction = "Alliance",
  races = { Gnome = true }, raceOnly = 3,
  brackets = ROUTE_BRACKETS,
})
