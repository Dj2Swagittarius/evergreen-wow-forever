-- Evergreen route: Dwarf ("The Deep Road"). Loaded after Data.lua and Routes_Human.lua; appends to ns.ROUTES.
-- Step format is documented at the top of Data.lua. Class steps carry cls="HUNTER" etc.
-- Three race-only brackets (Coldridge Valley, Kharanos and Dun Morogh, Loch Modan), then the shared
-- Alliance 20-60 brackets that Routes_Human.lua defines once as ns.ALLIANCE_BRACKETS. This file adds
-- nothing to that table. Dwarf Shaman (Forever only) class steps live in Routes_Forever_Combos.lua.
local ADDON, ns = ...

-- Map ids. Routes_Human.lua already registers these; keep them if it loaded, fill them in if not.
ns.MAP_NAMES[1426] = ns.MAP_NAMES[1426] or "Dun Morogh"
ns.MAP_NAMES[1432] = ns.MAP_NAMES[1432] or "Loch Modan"
ns.MAP_NAMES[1455] = ns.MAP_NAMES[1455] or "Ironforge"
ns.MAP_NAMES[1453] = ns.MAP_NAMES[1453] or "Stormwind City"
ns.MAP_NAMES[1436] = ns.MAP_NAMES[1436] or "Westfall"
ns.MAP_NAMES[1433] = ns.MAP_NAMES[1433] or "Redridge Mountains"
ns.MAP_NAMES[1429] = ns.MAP_NAMES[1429] or "Elwynn Forest"

local DM, LM, IF, SW, WF, RR, ELW = 1426, 1432, 1455, 1453, 1436, 1433, 1429

local IF_MUREN = {71,90,"Muren Stormpike, Hall of Arms, Military Ward, Ironforge (verify)",IF}
local IF_TORMUS = {49,43,"Tormus Deepforge, the Great Forge, Ironforge (verify)",IF}
local IF_HULFDAN = {52,15,"Hulfdan Blackbeard, Forlorn Cavern, Ironforge",IF}
local IF_TIZA = {24,5,"Tiza Battleforge, Hall of Mysteries, Mystic Ward, Ironforge (verify)",IF}
local IF_MUIREDON = {24,5,"Muiredon Battleforge, Hall of Mysteries, Ironforge (verify)",IF}
local IF_BELIA = {71,86,"Belia Thundergranite, Hall of Arms, Ironforge (by the cannon)",IF}
local KH_MAXAN = {47,52,"Maxan Anvol, Thunderbrew Distillery, Kharanos"}
local KH_GRIF = {46,53,"Grif Wildheart, Kharanos hunter trainer (verify coords)"}
local SW_RALL = {38,27,"Duthorian Rall, Cathedral of Light, Stormwind (Deeprun Tram)",SW}

-- ================================================================== Dwarf race-only brackets 1-20
ns.DWARF_BRACKETS = {
  -- ============================================================ 1-6 Coldridge Valley
  {
    id="d1", lv={1,6}, name="Coldridge Valley", map=DM,
    hub="Anvilmar", hearth="Already bound to Coldridge Valley (no inn)", fp="None",
    steps={
      {note="Before you move", t="Turn on Auto Loot and Find Treasure. Every class trainer stands inside Anvilmar; the rune Sten Stoutarm hands you is a free turn-in there. Vendor and repair at 30,72."},
      {q="Dwarven Outfitters", g={30,71,"Sten Stoutarm, path below Anvilmar"}, o={29,74,"8 Tough Wolf Meat from the wolves south (verify count)"}},
      {q="Coldridge Valley Mail Delivery", p=1, g={30,71,"Sten Stoutarm"}, r={23,71,"Talin Keeneye, camp west"}},
      {q="A New Threat", g={30,71,"Sten Stoutarm"}, o={31,75,"14 Rockjaw Troggs east of Anvilmar, 6 Burly Rockjaw Troggs west (verify counts)"}},
      {note="Class rune", t="Sten also hands you your class rune (Simple, Consecrated, Etched, Encrypted or Hallowed Rune): a free turn-in at your trainer inside Anvilmar."},
      {q="The Boar Hunter", g={23,71,"Talin Keeneye"}, o={22,69,"12 Small Crag Boars west and north of the camp (verify count)"}},
      {q="Coldridge Valley Mail Delivery", p=2, g={23,71,"Talin Keeneye"}, r={25,76,"Grelin Whitebeard, camp south"}},
      {q="The Troll Cave", g={25,76,"Grelin Whitebeard"}, o={27,80,"14 Frostmane Troll Whelps at the cave mouth (verify count)"}},
      {lv=4},
      {q="Scalding Mornbrew Delivery", g={25,76,"Grelin Whitebeard's camp (verify giver); 5-minute timer, hearth to Anvilmar"}, r={29,66,"Durnan Furcutter, back of Anvilmar"}},
      {q="Bring Back the Mug", g={29,66,"Durnan Furcutter"}, r={25,76,"Grelin Whitebeard's camp (verify)"}},
      {q="A Refugee's Quandary", g={29,68,"Felix Whindlebolt, Anvilmar door"}, o={23,80,"Felix's Box (21,76), Felix's Chest (23,80), Felix's Bucket of Bolts (26,79)"}},
      {q="The Stolen Journal", g={25,76,"Grelin Whitebeard"}, o={30,80,"Grik'nir the Cold at the back of the troll cave; hug the left wall"}},
      {q="Senir's Observations", p=1, g={25,76,"Grelin Whitebeard"}, r={33,72,"Mountaineer at the Coldridge Pass mouth (verify name)"}},
      {q="In Favor of the Light", cls="PRIEST", g={29,66,"Branstock Khalder, back of Anvilmar"}, r=KH_MAXAN},
      {q="Senir's Observations", p=2, g={33,72,"Coldridge Pass (verify giver)"}, r={46,54,"Senir Whitebeard, Kharanos"}},
      {q="Supplies to Tannok", g={34,72,"Hands Springsprocket, Coldridge Pass (verify)"}, r={47,52,"Tannok Frosthammer, inside the Thunderbrew Distillery, Kharanos"}},
      {forever=true, t="Nothing announced touches Coldridge. Dwarf Shamans start here in Forever: trainer Teo Hammerstorm inside Anvilmar (28.8, 66.2)."},
      {lv=6},
    },
  },
  -- ============================================================ 6-12 Kharanos & Dun Morogh
  {
    id="d2", lv={6,12}, name="Kharanos & Dun Morogh", map=DM,
    hub="Kharanos", hearth="Thunderbrew Distillery (Innkeeper Belm)", fp="None here; Ironforge (Gryth Thurden) at 10",
    steps={
      {tr=true, x=46, y=52, t="Through the Coldridge Pass tunnel and down the road into Kharanos; kill boars on the way."},
      {bind="Kharanos", x=47, y=53},
      {note="Pickup sweep", t="Senir Whitebeard by the road, Ragnar Thunderbrew, Tannok inside the inn, Grundel Harkin, Belm for the bind and a Rhapsody Malt. Learn First Aid (the physician inside the inn, verify name), Mining and Skinning. Steelgrill's Depot up the road is the second half."},
      {q="Beer Basted Boar Ribs", g={47,52,"Ragnar Thunderbrew, Kharanos"}, o={45,56,"6 Crag Boar Ribs from boars around the village (verify count) plus a Rhapsody Malt from Belm; do not vendor the ribs"}},
      {q="Tools for Steelgrill", g={46,52,"Grundel Harkin, Kharanos"}, r={50,49,"Beldin Steelgrill, Steelgrill's Depot"}},
      {q="Garments of the Light", cls="PRIEST", g=KH_MAXAN, o={46,55,"Heal Mountaineer Dolf south of the inn with Lesser Heal and Fortitude (verify coords)"}, r={47,52,"Maxan Anvol: Neophyte's Robe"}},
      {q="Stocking Jetsteam", g={49,48,"Pilot Bellowfiz, Steelgrill's Depot"}, o={45,56,"8 Chunk of Boar Meat, 4 Thick Bear Fur from boars and bears around Kharanos (verify counts)"}},
      {q="The Grizzled Den", g={49,48,"Pilot Stonegear, Steelgrill's Depot"}, o={42,54,"6 Wendigo Manes in the Grizzled Den west of Kharanos (verify count)"}},
      {q="Ammo for Rumbleshot", g={50,49,"Ammo crate at Steelgrill's Depot"}, o={44,57,"Pick up the Ammo Crate on the road south"}, r={41,65,"Hegnar Rumbleshot, camp on the road south"}},
      {lv=7},
      {q="Evershine", g={49,48,"Pilot Bellowfiz"}, r={30,46,"Rejold Barleybrew, Brewnall Village"}},
      {q="Frostmane Hold", g={46,54,"Senir Whitebeard"}, o={25,51,"Explore the middle of Frostmane Hold (23,52); 5 Frostmane Headhunters"}},
      {q="Operation Recombobulation", g={46,49,"Razzle Sprysprocket, goblin hut"}, o={25,44,"8 Restabilization Cogs, 8 Gyromechanic Gears from Leper Gnomes outside Gnomeregan (verify counts)"}},
      {q="A Favor for Evershine", g={30,46,"Rejold Barleybrew, Brewnall"}, o={28,40,"8 Ice Claw Bears, 8 Elder Crag Boars, 8 Snow Leopards in western Dun Morogh past Iceflow Lake (verify counts)"}},
      {q="The Perfect Stout", g={30,46,"Rejold Barleybrew (verify giver)"}, o={38,42,"5 Shimmerweed from the baskets among the Frostmane Seers on Shimmer Ridge (verify count)"}},
      {q="Bitter Rivals", g={30,46,"Marleth Barleybrew, Brewnall"}, o={48,53,"Buy a Thunder Ale from Belm, give it to Jarven Thunderbrew in the barrel room, click the Unguarded Thunder Ale Barrel"}},
      {q="Return to Marleth", opt=true, g={48,53,"Unguarded Thunder Ale Barrel"}, r={30,46,"Marleth Barleybrew, Brewnall"}},
      {q="Tundra MacGrann's Stolen Stash", opt=true, g={35,52,"Tundra MacGrann, up the mountain via 36,53"}, o={38,51,"MacGrann's Meat Locker; a level-11 elite yeti patrols the cave"}},
      {lv=8},
      {q="Shimmer Stout", g={30,46,"Rejold Barleybrew"}, r={86,49,"Mountaineer Barleybrew, South Gate Outpost"}},
      {q="Return to Bellowfiz", g={30,46,"Rejold Barleybrew"}, r={49,48,"Pilot Bellowfiz, Steelgrill's Depot"}},
      {q="The Reports", g={46,54,"Senir Whitebeard"}, r={39,58,"Senator Barin Redstone, the High Seat, Ironforge (verify)",IF}},
      {q="Protecting the Herd", opt=true, g={63,50,"Rudra Amberstill, Amberstill Ranch (verify name)"}, o={62,34,"Vagash, level-11 elite yeti up the hidden path; group or skip"}},
      {q="The Public Servant", g={69,56,"Senator Mehr Stonehallow, Gol'Bolar Quarry"}, o={71,56,"10 Rockjaw Bonesnappers in the quarry mine (verify count)"}},
      {q="Those Blasted Troggs!", g={69,56,"Foreman Stonebrow, behind the quarry tent"}, o={68,59,"6 Rockjaw Skullthumpers in the quarry (verify count)"}},
      {lv=10},
      {tr=true, x=55, y=48, map=IF, any=true, t="Level 10: Ironforge through the gate north of Kharanos (53,35). Train: Hall of Mysteries (paladin, priest), Hall of Arms (warrior, hunter), Forlorn Cavern (rogue). Every level-10 class quest below starts or ends here."},
      {fp="Ironforge", x=55, y=48, map=IF},
      {q="Muren Stormpike", cls="WARRIOR", g={47,53,"Kharanos warrior trainer, inside the inn (verify giver)"}, r=IF_MUREN},
      {q="Vejrek", cls="WARRIOR", g=IF_MUREN, o={27,57,"Vejrek, Frostmane troll in the cliff hut south of Frostmane Hold; loot Vejrek's Head"}, r={71,90,"Muren Stormpike: Defensive Stance, Taunt, Sunder Armor",IF}},
      {q="Tormus Deepforge", cls="WARRIOR", g=IF_MUREN, r=IF_TORMUS},
      {q="Ironband's Compound", cls="WARRIOR", g=IF_TORMUS, o={77,61,"Umbral Ore from the strongbox at Ironband's Compound south of Helm's Bed Lake; Captain Beld (11) and Dark Iron dwarves guard it"}, r=IF_TORMUS},
      {q="Grey Iron Weapons", cls="WARRIOR", g=IF_TORMUS, r={49,43,"Tormus Deepforge: pick a Grey Iron weapon",IF}},
      {q="Road to Salvation", cls="ROGUE", g={48,53,"Hogral Bakkan, Kharanos inn (verify giver)"}, r=IF_HULFDAN},
      {q="Simple Subterfugin'", cls="ROGUE", g=IF_HULFDAN, r={25,44,"Onin MacHammar, foot of the Gnomeregan ramp, west Dun Morogh"}},
      {q="Onin's Report", cls="ROGUE", g={25,44,"Onin MacHammar"}, r={52,15,"Hulfdan Blackbeard: Blade of Cunning",IF}},
      {q="Taming the Beast", p=1, cls="HUNTER", g=KH_GRIF, o={48,57,"Use the Taming Rod on a Large Crag Boar on the slopes south of Kharanos"}},
      {q="Taming the Beast", p=2, cls="HUNTER", g=KH_GRIF, o={48,59,"Tame a Snow Leopard in the hills"}},
      {q="Taming the Beast", p=3, cls="HUNTER", g=KH_GRIF, o={50,54,"Tame an Ice Claw Bear near the Grizzled Den (verify mob and coords; the wiki says only 'bear')"}},
      {q="Training the Beast", cls="HUNTER", g=KH_GRIF, r=IF_BELIA},
      {man="Hunter: Belia teaches Tame Beast, Feed Pet, Revive Pet and Beast Training. Keep the bear or tame a Starving Winter Wolf at Iceflow Lake (34,42) for Bite. Buy a gun.", cls="HUNTER", x=34, y=42},
      {q="Desperate Prayer", cls="PRIEST", g=KH_MAXAN, r={47,52,"Maxan Anvol (or High Priest Rohan, Hall of Mysteries): Desperate Prayer"}},
      {note="Paladin", t="Azar Stronghammer on the inn steps has nothing for you at 10; Redemption comes at 12."},
      {q="The Lost Pilot", g={84,39,"Pilot Hammerfoot, North Gate Outpost (verify name)"}, o={80,36,"Click the Dwarven Corpse"}},
      {q="A Pilot's Revenge", g={80,36,"Dwarven Corpse"}, o={78,38,"Mangeclaw"}, r={84,39,"Pilot Hammerfoot, North Gate Outpost"}},
      {q="Tome of Divinity", cls="PALADIN", g={48,52,"Azar Stronghammer, Kharanos inn steps"}, r=IF_TIZA},
      {q="The Tome of Divinity", p=1, cls="PALADIN", g=IF_TIZA, o={24,5,"Read the tome Tiza hands you",IF}, r=IF_TIZA},
      {q="The Tome of Divinity", p=2, cls="PALADIN", g=IF_TIZA, o={31,70,"10 Linen Cloth to John Turner, the Commons (verify coords)",IF}, r=IF_TIZA},
      {q="The Tome of Divinity", p=3, cls="PALADIN", g=IF_TIZA, r=IF_MUIREDON},
      {q="The Symbol of Life", cls="PALADIN", g=IF_MUIREDON, o={77,57,"Resurrect Narm Faulk at the south edge of Helm's Bed Lake, east Dun Morogh (verify coords)"}, r={77,57,"Narm Faulk"}},
      {q="The Tome of Divinity", p=4, cls="PALADIN", g={77,57,"Narm Faulk"}, o={77,57,"A Dark Iron Script from the Dark Iron Spies around him (verify count)"}, r={24,5,"Muiredon Battleforge: Redemption",IF}},
      {tr=true, x=86, y=49, t="South Gate Outpost: Shimmer Stout to Mountaineer Barleybrew, then through South Gate Pass into Loch Modan."},
      {q="Stout to Kadrell", g={86,49,"Mountaineer Barleybrew, South Gate Outpost"}, r={34,48,"Mountaineer Kadrell, on the road in Thelsamar",LM}},
      {forever=true, t="No source reports Dun Morogh changes beyond the Dwarf Shaman trainer. Wetlands is the announced Alliance expansion and it is next door to Loch Modan at 20."},
      {lv=12},
    },
  },
  -- ============================================================ 12-20 Loch Modan
  {
    id="d3", lv={12,20}, name="Loch Modan", map=LM,
    hub="Thelsamar", hearth="Stoutlager Inn (Innkeeper Hearthstove)", fp="Thelsamar (Thorgrum Borrelson); Stormwind (Dungar Longdrink) by Tram at 14",
    steps={
      {tr=true, x=22, y=73, t="Out of South Gate Pass (17,59); the Valley of Kings bunker is the first stop."},
      {q="In Defense of the King's Lands", p=1, g={22,73,"Mountaineer Cobbleflint, Valley of Kings"}, o={32,73,"10 Stonesplinter Troggs, 10 Stonesplinter Scouts in Stonesplinter Valley"}},
      {q="The Trogg Threat", g={23,74,"Captain Rugelfuss, top of the Valley of Kings tower"}, o={32,73,"8 Trogg Stone Teeth, Stonesplinter Valley"}},
      {q="In Defense of the King's Lands", p=2, g={23,74,"Mountaineer Wallbang, inside the bunker"}, o={32,73,"10 Stonesplinter Skullthumpers, 10 Stonesplinter Seers, Stonesplinter Valley"}, r={23,74,"Mountaineer Gravelgaw, inside the bunker"}},
      {tr=true, x=35, y=48, t="North up the road to Thelsamar."},
      {bind="Thelsamar", x=35, y=49},
      {fp="Thelsamar", x=34, y=51},
      {note="Thelsamar sweep", t="Kadrell patrols the road across from the inn, Vidra at the bar, Brock in the hut east of town, Jern Hornhelm in the south-east house, Magistrate Bluntnose. Six-slot bags from General Supplies."},
      {q="Rat Catching", g={34,48,"Mountaineer Kadrell"}, o={26,42,"12 Tunnel Rat Ears at the kobold camps west of the north road (26,42; 24,31) and outside Silver Stream Mine"}},
      {q="Mountaineer Stormpike's Task", g={34,48,"Mountaineer Kadrell"}, r={25,18,"Mountaineer Stormpike, upstairs at Algaz Station"}},
      {q="Thelsamar Blood Sausages", g={35,49,"Vidra Hearthstove, the inn bar"}, o={42,65,"3 Bear Meat, 3 Spider Ichor, 3 Boar Intestines from Grizzlepaw Ridge and north of town"}},
      {q="Honor Students", g={37,48,"Brock, hut east of town (verify surname)"}, r={34,51,"Thorgrum Borrelson, gryphon master"}},
      {q="Ironband's Excavation", g={37,49,"Jern Hornhelm, south-east house (verify coords)"}, r={65,65,"Magmar Fellhew, Ironband's Excavation"}},
      {q="Mercenaries", g={35,48,"Magistrate Bluntnose, Thelsamar (verify coords)"}, o={72,22,"Mo'grosh Enforcers and Brutes at Mo'grosh Stronghold, north-east corner of the loch (verify counts and coords)"}},
      {q="WANTED: Chok'sul", opt=true, g={35,48,"Wanted poster, Thelsamar (verify giver)"}, o={72,22,"Chok'sul (20 elite, verify) at Mo'grosh Stronghold; group of 2"}, r={35,48,"Magistrate Bluntnose"}},
      {q="Ride to Ironforge", g={34,51,"Thorgrum Borrelson"}, r={52,26,"Deep Mountain Mining Guild, Ironforge (verify coords)",IF}},
      {q="Gryth Thurden", g={52,26,"Deep Mountain Mining Guild, Ironforge (verify)",IF}, r={55,48,"Gryth Thurden, the Great Forge, Ironforge",IF}},
      {q="Return to Brock", opt=true, g={55,48,"Gryth Thurden, Ironforge",IF}, r={37,48,"Brock, Thelsamar"}},
      {fp="Ironforge", x=55, y=48, map=IF},
      {q="Find Bingles", g={72,50,"Gnoarn, Tinker Town, Ironforge (verify coords)",IF}, r={64,48,"Bingles Blastenheimer, east shore of the loch"}},
      {q="Stormpike's Order", g={25,18,"Mountaineer Stormpike, Algaz Station"}, r={62,36,"Furen Longbeard, Dwarven District, Stormwind (Tram; verify coords)",SW}},
      {q="Filthy Paws", g={25,18,"Mountaineer Stormpike, Algaz Station"}, o={35,19,"4 Miners' Gear from the Miners' League crates inside Silver Stream Mine; careful pulls or a partner"}},
      {lv=14},
      {tr=true, x=62, y=36, map=SW, any=true, t="Level 14: fly to Ironforge, train, Tram to Stormwind: Furen Longbeard (Stormpike's Order), Dungar Longdrink's flight point in the Trade District, Baros Alexston's Humble Beginnings in Cathedral Square. Tram back, fly Thelsamar."},
      {fp="Stormwind", x=66, y=62, map=SW},
      {q="Humble Beginnings", opt=true, g={49,30,"Baros Alexston, Cathedral Square, Stormwind",SW}, o={49,30,"Follow the quest text (verify)",SW}},
      {q="Gathering Idols", g={65,65,"Magmar Fellhew, Ironband's Excavation"}, o={65,65,"8 Carved Stone Idols from the Stonesplinter troggs at the dig"}},
      {q="Excavation Progress Report", g={65,65,"Prospector Ironband, Ironband's Excavation"}, r={37,49,"Jern Hornhelm, Thelsamar"}},
      {q="Report to Ironforge", g={37,49,"Jern Hornhelm"}, r={75,10,"Prospector Stormpike, Hall of Explorers, Ironforge",IF}},
      {q="Powder to Ironband", g={75,10,"Prospector Stormpike, Hall of Explorers, Ironforge",IF}, r={37,49,"Jern Hornhelm, Thelsamar (verify turn-in)"}},
      {q="Resupplying the Excavation", g={37,49,"Jern Hornhelm"}, r={42,55,"Huldar, on the south shore of the loch (verify coords); Dark Iron ambush"}},
      {q="After the Ambush", g={42,55,"Huldar (verify)"}, r={42,55,"Miran, beside him; respawns in about two minutes"}},
      {q="Protecting the Shipment", g={42,55,"Miran"}, o={65,65,"Escort Miran to the dig past two Dark Iron Raiders"}, r={65,65,"Prospector Ironband"}},
      {q="Bingles' Missing Supplies", g={64,48,"Bingles Blastenheimer"}, o={54,26,"Blastencapper in the south-east hut on the north island (54,26); Hammer in the wreckage (52,24); Wrench at the west island camp (49,30); Screwdriver at the north-west camp (48,20)"}},
      {q="In Defense of the King's Lands", p=3, g={23,74,"Mountaineer Wallbang, Valley of Kings"}, o={54,26,"10 Stonesplinter Shamans, 10 Stonesplinter Bonesnappers on the northern loch islands"}, r={23,74,"Mountaineer Gravelgaw"}},
      {lv=16},
      {q="To Hulfdan!", cls="ROGUE", g={52,15,"Any rogue trainer (verify breadcrumb name)",IF}, r=IF_HULFDAN},
      {q="Redridge Rendezvous", cls="ROGUE", g=IF_HULFDAN, r={30,45,"Lucius, Lakeshire, Redridge (Tram to Stormwind, ride east through Elwynn; or hold it for the Redridge pass at 25)",RR}},
      {q="Alther's Mill", cls="ROGUE", opt=true, g={30,45,"Lucius, Lakeshire",RR}, o={44,44,"Pick the practice lockboxes at Alther's Mill east of Lakeshire until Lucius's Lockbox opens; take the Token of Thievery (verify coords)",RR}, r={30,45,"Lucius: Certificate of Thievery",RR}},
      {tr=true, x=82, y=62, t="Farstrider Lodge, south-east corner of the zone."},
      {q="Crocolisk Hunting", g={82,62,"Marek Ironheart, Farstrider Lodge"}, o={55,54,"5 Crocolisk Meat, 6 Crocolisk Skins from Loch Crocolisks on the loch islands"}},
      {q="A Hunter's Boast", g={82,62,"Daryl the Youngling, Farstrider Lodge"}, o={77,74,"6 Mountain Buzzards south-west of the lodge; 15-minute timer"}},
      {q="A Hunter's Challenge", g={82,62,"Daryl the Youngling"}, o={70,50,"Elder Mountain Boars north-west of the lodge; 12-minute timer (5 or 8, verify)"}},
      {q="Vyrin's Revenge", p=1, g={82,62,"Vyrin Swiftwind, Farstrider Lodge"}, o={42,65,"Ol' Sooty on Grizzlepaw Ridge; 20-minute respawn, group of 2"}, r={82,62,"Daryl the Youngling"}},
      {q="Vyrin's Revenge", p=2, g={82,62,"Daryl the Youngling"}, r={82,62,"Vyrin Swiftwind"}},
      {note="Hunters", t="Dargh Trueaim trains hunters at Farstrider Lodge and Cliff Hadin sells bows; Kat Sampson vendors."},
      {lv=17},
      {q="A Dark Threat Looms", p=1, g={47,13,"Chief Engineer Hinderweir VII, Stonewrought Dam"}, o={56,13,"The Suspicious Barrel east of the dam"}, r={47,13,"Chief Engineer Hinderweir VII"}},
      {q="A Dark Threat Looms", p=2, g={47,13,"Chief Engineer Hinderweir VII"}, o={56,13,"2 Dark Iron Sappers around the dam (verify)"}, r={47,13,"Chief Engineer Hinderweir VII"}},
      {man="A Dark Threat Looms continues 18-20 through the Mo'grosh ogres and a Dark Iron chain; follow the quest text (verify later objectives). Nillen Andemar at the dam sells the Heavy Spiked Mace.", x=47, y=13},
      {lv=18},
      {q="In Defense of the King's Lands", p=4, opt=true, g={23,74,"Captain Rugelfuss, Valley of Kings"}, o={30,73,"Grawmug, Gnasher and Brawler in the west cave of Stonesplinter Valley; group of 2"}, r={23,74,"Captain Rugelfuss"}},
      {man="Grind Mo'grosh Stronghold (72,22, verify) for Mercenaries and Chok'sul, Grizzlepaw Ridge for sausage meats, the northern islands for troggs. Ding 20 here. Optional Deadmines trip: Tram to Stormwind for the Dwarven District quests and Scout Riell's Red Silk Bandanas at Sentinel Hill.", x=72, y=22},
      {lv=20},
      {q="The Tome of Valor", p=1, cls="PALADIN", g={48,52,"Any paladin trainer (Azar Stronghammer, Kharanos; Hall of Mysteries, Ironforge)",DM}, r=SW_RALL},
      {q="The Tome of Valor", p=2, cls="PALADIN", g=SW_RALL, r={42,88,"Daphne Stilwell, farm in the Dagger Hills above Longshore, far south Westfall (ride west from the Stormwind gate)",WF}},
      {q="The Tome of Valor", p=3, cls="PALADIN", g={42,88,"Daphne Stilwell",WF}, o={42,88,"Defend Daphne against three waves of Defias; keep her alive",WF}, r={38,27,"Duthorian Rall: Sense Undead, Bastion of Stormwind",SW}},
      {q="A Lack of Fear", cls="PRIEST", g={26,9,"Toldren Deepiron, Hall of Mysteries, Ironforge (verify giver; or High Priestess Laurena, Stormwind)",IF}, r={26,9,"Toldren Deepiron: Fear Ward",IF}},
      {forever=true, t="Loch Modan is unchanged as far as anyone has reported. The Wetlands expansion is next door; if it is dense at 20-25 it replaces the Duskwood ride that opens the next bracket (verify)."},
    },
  },
}

-- Dwarf route = the three brackets above, then the shared Alliance brackets from Routes_Human.lua.
local ALLIANCE = ns.ALLIANCE_BRACKETS or {}
local ROUTE_BRACKETS = {}
for _, b in ipairs(ns.DWARF_BRACKETS) do table.insert(ROUTE_BRACKETS, b) end
for _, b in ipairs(ALLIANCE) do table.insert(ROUTE_BRACKETS, b) end

table.insert(ns.ROUTES, {
  id = "dwarf", name = "The Deep Road", faction = "Alliance",
  races = { Dwarf = true }, raceOnly = 3,
  brackets = ROUTE_BRACKETS,
})
