-- Evergreen route: Night Elf ("The Moon Road"). Loaded after Data.lua and Routes_Human.lua; appends to ns.ROUTES.
-- Step format is documented at the top of Data.lua. Class steps carry cls="DRUID" etc.
-- Three race-only brackets (Shadowglen, Dolanaar and Teldrassil, Darkshore), then every shared
-- Alliance bracket from ns.ALLIANCE_BRACKETS (defined once in Routes_Human.lua, ids a4..a11). That
-- table already carries the faction-wide class chains, including the druid Torwa chain at 50 and the
-- warrior Whirlwind chain; nothing is added to it here. If Routes_Human.lua is missing the route
-- simply ends at 20.
local ADDON, ns = ...

ns.MAP_NAMES[1438] = ns.MAP_NAMES[1438] or "Teldrassil"
ns.MAP_NAMES[1439] = ns.MAP_NAMES[1439] or "Darkshore"
ns.MAP_NAMES[1457] = ns.MAP_NAMES[1457] or "Darnassus"
ns.MAP_NAMES[1450] = ns.MAP_NAMES[1450] or "Moonglade"
ns.MAP_NAMES[1440] = ns.MAP_NAMES[1440] or "Ashenvale"
ns.MAP_NAMES[1433] = ns.MAP_NAMES[1433] or "Redridge Mountains"

local TEL, DS, DAR, MG, ASH, RR = 1438, 1439, 1457, 1450, 1440, 1433
local DAR_BEAR     = {35,10,"Mathrengyl Bearwalker, Cenarion Enclave upper level, Darnassus (verify)",DAR}
local MG_DENDRITE  = {56,30,"Dendrite Starblaze, Nighthaven, Moonglade",MG}
local DAR_ELANARIA = {57,35,"Elanaria, Warrior's Terrace, Darnassus",DAR}
local DAR_SYURNA   = {32,16,"Syurna, spiral ramp, Cenarion Enclave, Darnassus (verify)",DAR}
local DAR_ERION    = {32,16,"Erion Shadewhisper, Cenarion Enclave, Darnassus (verify)",DAR}
local AUB_ALANN    = {37,44,"Alanndarian Nightsong, Auberdine (verify)",DS}
local AUB_THUNDRIS = {37,42,"Thundris Windweaver, building north-east of the Auberdine inn (verify)"}
local AUB_TERENTHIS = {37,42,"Terenthis, Auberdine (verify)"}
local DAZALAR      = {55,60,"Dazalar, Dolanaar (verify)"}

-- ================================================================== Night Elf race-only brackets 1-20
ns.NIGHTELF_BRACKETS = {
  -- ============================================================ 1-6 Shadowglen
  {
    id="n1", lv={1,6}, name="Shadowglen", map=TEL,
    hub="Aldrassil", hearth="Already bound to Shadowglen", fp="None",
    steps={
      {note="Before you move", t="Turn on Auto Loot. Bind a key to Shadowmeld. Every class trainer stands inside Aldrassil; the scroll you spawn with is a free turn-in there. Wisp Spirit makes dying a shortcut back to the tree."},
      {q="The Balance of Nature", p=1, g={59,44,"Conservator Ilthalaine, Aldrassil"}, o={59,42,"7 Young Nightsabers, 4 Young Thistle Boars around the tree (verify counts)"}},
      {q="The Woodland Protector", p=1, g={60,42,"Melithar Staghelm, Aldrassil entrance (verify)"}, r={58,45,"Tarindrella, the dryad"}},
      {q="The Woodland Protector", p=2, g={58,45,"Tarindrella"}, o={56,46,"8 Grellkin at the camps south-west (verify count)"}, r={58,45,"Tarindrella"}},
      {q="The Balance of Nature", p=2, g={59,44,"Conservator Ilthalaine"}, o={57,40,"7 Mangy Nightsabers, 7 Thistle Boars (verify counts)"}},
      {q="In Favor of Elune", cls="PRIEST", g={59,40,"Shanda, Aldrassil"}, r={56,57,"Laurna Morninglight, Dolanaar (verify)"}},
      {q="A Good Friend", g={61,42,"Dirania Silvershine, by the cauldron (verify)"}, r={55,33,"Iverron, by Shadowthread Cave"}},
      {q="Webwood Venom", g={58,42,"Gilshalan Windwalker, west ramp (verify)"}, o={57,32,"10 Webwood Venom Sacs from the spiders around Shadowthread Cave (verify count)"}},
      {q="A Friend in Need", g={55,33,"Iverron"}, r={61,42,"Dirania Silvershine"}},
      {lv=4},
      {q="Iverron's Antidote", p=1, g={61,42,"Dirania Silvershine"}, o={58,38,"7 Hyacinth Mushrooms from Grell and Grellkin (55,39), 4 Moonpetal Lilies at the ponds, 1 Webwood Ichor from any Webwood Spider (verify counts)"}},
      {q="Webwood Egg", g={58,42,"Gilshalan Windwalker"}, o={57,32,"The egg at the back of Shadowthread Cave"}},
      {q="Iverron's Antidote", p=2, g={61,42,"Dirania Silvershine"}, r={55,33,"Iverron; 5-minute timer, go straight there"}},
      {q="Tenaron's Summons", g={58,42,"Gilshalan Windwalker"}, r={59,39,"Tenaron Stormgrip, top of Aldrassil"}},
      {q="Crown of the Earth", p=1, g={59,39,"Tenaron Stormgrip"}, o={60,33,"Fill the Crystal Phial at the moonwell north of the tree"}, r={59,39,"Tenaron Stormgrip"}},
      {q="Crown of the Earth", p=2, g={59,39,"Tenaron Stormgrip"}, r={56,62,"Corithras Moonrage, Dolanaar moonwell"}},
      {q="Dolanaar Delivery", g={61,48,"Porthannius, the road out of Shadowglen (verify)"}, r={56,60,"Innkeeper Keldamyr, Dolanaar"}},
      {q="Zenn's Bidding", g={60,56,"Zenn Foulhoof, by the road to Dolanaar"}, o={60,62,"3 Nightsaber Fangs, 3 Strigid Owl Feathers, 3 Webwood Spider Silk from the fields around Dolanaar (verify counts)"}, r={60,56,"Zenn Foulhoof; keep the Severed Voodoo Claw"}},
      {forever=true, t="Nothing announced touches Shadowglen. Elune's Light should be active from level 1. A Night Elf mage would start here in Forever; nothing is published."},
      {lv=6},
    },
  },
  -- ============================================================ 6-12 Dolanaar & Teldrassil
  {
    id="n2", lv={6,12}, name="Dolanaar & Teldrassil", map=TEL,
    hub="Dolanaar", hearth="Dolanaar inn (Innkeeper Keldamyr)", fp="None here; Rut'theran Village (Vesprystus) on the level-12 Auberdine errand",
    steps={
      {tr=true, x=56, y=59, t="South on the road into Dolanaar."},
      {bind="Dolanaar", x=56, y=60},
      {note="Pickup sweep", t="Keldamyr for the bind, Syral Bladeleaf, Athridas Bearmantle, Tallonkai Swiftroot at the top of the tower, Corithras Moonrage at the moonwell, Zarrin the cook. Learn First Aid, Skinning and Herbalism."},
      {q="Denalan's Earth", g={56,58,"Syral Bladeleaf, Dolanaar"}, r={61,68,"Denalan, Lake Al'Ameth"}},
      {q="A Troubling Breeze", g={56,57,"Athridas Bearmantle, Dolanaar"}, r={66,59,"Gaerolas Talvethren, Starbreeze Village (verify)"}},
      {q="Twisted Hatred", g={55,57,"Tallonkai Swiftroot, top of the tower"}, o={52,50,"Lord Melenas at the back of Fel Rock (entrance 55,52); use the Severed Voodoo Claw"}},
      {q="The Emerald Dreamcatcher", g={55,57,"Tallonkai Swiftroot"}, o={68,60,"Tallonkai's Dresser upstairs in Starbreeze Village"}},
      {q="Crown of the Earth", p=3, g={56,62,"Corithras Moonrage"}, o={63,58,"Jade Phial at the Starbreeze moonwell"}, r={56,62,"Corithras Moonrage"}},
      {q="Recipe of the Kaldorei", g={57,61,"Zarrin, the cook"}, o={60,64,"Small Spider Legs from the Webwood spiders"}},
      {q="Timberling Seeds", g={61,68,"Denalan"}, o={62,70,"8 Timberling Seeds from the timberlings around Lake Al'Ameth (verify count)"}},
      {q="Timberling Sprouts", g={61,68,"Denalan"}, o={62,70,"5 Timberling Sprouts around the lake (verify count)"}},
      {q="Seek Redemption!", g={56,58,"Syral Bladeleaf"}, o={60,55,"3 Fel Cones from the trees around Zenn Foulhoof"}, r={60,56,"Zenn Foulhoof"}},
      {q="Gnarlpine Corruption", g={66,59,"Gaerolas Talvethren, Starbreeze Village (verify)"}, r={56,57,"Athridas Bearmantle"}},
      {q="Rellian Greenspyre", g={61,68,"Denalan"}, r={38,22,"Rellian Greenspyre, Cenarion Enclave, Darnassus",DAR}},
      {lv=8},
      {q="Ferocitas the Dream Eater", g={55,57,"Tallonkai Swiftroot"}, o={69,53,"7 Gnarlpine Mystics north-east of Starbreeze, then Ferocitas for the Gnarlpine Necklace"}},
      {q="The Relics of Wakening", g={56,57,"Athridas Bearmantle"}, o={44,60,"Four chests in Ban'ethil Barrow Den (entrance 44,58): Black Feather Quill and Rune of Nesting 44,61, Chest of the Sky 45,62, Chest of the Raven Claw 46,57"}},
      {q="The Sleeping Druid", g={45,59,"Oben Rageclaw, Ban'ethil Barrow Den"}, o={45,60,"Shaman Voodoo Charm from a Gnarlpine Shaman in the den"}, r={45,59,"Oben Rageclaw"}},
      {q="Druid of the Claw", g={45,59,"Oben Rageclaw"}, o={45,59,"Use the charm on Rageclaw's body and kill the Druid of the Claw"}, r={45,59,"Oben Rageclaw"}},
      {q="The Road to Darnassus", g={50,54,"Moon Priestess Amara, on the road west"}, o={47,53,"6 Gnarlpine Ambushers in Ban'ethil Hollow"}, r={50,54,"Moon Priestess Amara"}},
      {q="Crown of the Earth", p=4, g={56,62,"Corithras Moonrage"}, o={42,64,"Tourmaline Phial at the Pools of Arlithrien moonwell (verify)"}, r={56,62,"Corithras Moonrage"}},
      {q="The Glowing Fruit", g={43,76,"Strange Fruited Plant, Gnarlpine Hold"}, r={61,68,"Denalan, Lake Al'Ameth"}},
      {q="Ursal the Mauler", g={56,57,"Athridas Bearmantle"}, o={39,80,"Ursal the Mauler (12) in Gnarlpine Hold"}, r={56,57,"Athridas Bearmantle"}},
      {lv=10},
      {tr=true, x=40, y=45, map=DAR, any=true, t="Level 10: Darnassus. Walk the road west over the bridge, or die past it (43,52) and wisp to the city. Train, then every level-10 class quest below ends here; do them all on one trip."},
      {q="Tumors", g={38,22,"Rellian Greenspyre, Cenarion Enclave",DAR}, o={43,28,"5 Mossy Tumors from the timberlings at Wellspring River (verify count)"}, r={38,22,"Rellian Greenspyre",DAR}},
      {q="The Temple of the Moon", g={29,46,"Sister Aquinne, Darnassus (verify)",DAR}, r={37,86,"Priestess A'moora, Temple of the Moon",DAR}},
      {q="Tears of the Moon", g={37,86,"Priestess A'moora",DAR}, o={39,25,"Lady Sathrah, the spider at the Oracle Glade (verify)"}, r={37,86,"Priestess A'moora",DAR}},
      {q="Elanaria", cls="WARRIOR", g={56,59,"Kyra Windblade, Dolanaar warrior trainer (verify giver)"}, r=DAR_ELANARIA},
      {q="Vorlus Vilehoof", cls="WARRIOR", g=DAR_ELANARIA, o={49,59,"Vorlus Vilehoof (10) at the hidden moonwell south-east of Ban'ethil Barrow Den; torch-lined path from 49,59 (verify); loot the Horn of Vorlus"}, r={57,35,"Elanaria: Defensive Stance, Taunt, Sunder Armor",DAR}},
      {q="The Shade of Elura", cls="WARRIOR", g=DAR_ELANARIA, o={31,44,"8 Elunite Ore from the crates around the shipwreck south of the Auberdine dock and under it; Elura's Medallion from the Shade of Elura (do it at 12)",DS}, r=DAR_ELANARIA},
      {q="Smith Mathiel", cls="WARRIOR", g=DAR_ELANARIA, r={60,60,"Smith Mathiel, Tradesmen's Terrace, Darnassus (verify)",DAR}},
      {q="Weapons of Elunite", cls="WARRIOR", g={60,60,"Smith Mathiel (verify)",DAR}, r={60,60,"Smith Mathiel: Elunite Axe, Sword, Hammer or Dagger",DAR}},
      {q="The Hunter's Path", cls="HUNTER", g={57,59,"Dolanaar hunter trainer"}, r=DAZALAR},
      {q="Taming the Beast", p=1, cls="HUNTER", g=DAZALAR, o={57,34,"Use the Taming Rod on a Webwood Lurker around Shadowthread Cave, north (verify spot)"}},
      {q="Taming the Beast", p=2, cls="HUNTER", g=DAZALAR, o={63,73,"Tame a Nightsaber Stalker south of Dolanaar (verify spot)"}},
      {q="Taming the Beast", p=3, cls="HUNTER", g=DAZALAR, o={50,60,"Tame a Strigid Screecher west of Dolanaar (verify spot). Reward: Tame Beast, Call Pet, Dismiss Pet"}},
      {q="Training the Beast", cls="HUNTER", g=DAZALAR, r={40,9,"Jocaste, Cenarion Enclave, Darnassus (verify)",DAR}},
      {q="The Apple Falls", cls="ROGUE", g={56,60,"Frahun Shadewhisper, Dolanaar"}, r=DAR_SYURNA},
      {q="Destiny Calls", cls="ROGUE", g=DAR_SYURNA, o={37,24,"Sethir's Journal from Sethir the Ancient on a branch at the edge of the Oracle Glade (verify)"}, r={32,16,"Syurna: Blade of Cunning",DAR}},
      {q="Returning Home", cls="PRIEST", g={56,57,"Laurna Morninglight, Dolanaar"}, r={40,81,"Lariia, Temple of the Moon, Darnassus (verify)",DAR}},
      {q="Stars of Elune", cls="PRIEST", g={40,81,"Lariia",DAR}, r={40,81,"Lariia: Starshards",DAR}},
      {q="Heeding the Call", cls="DRUID", g={56,62,"Kal, Dolanaar druid trainer (verify giver)"}, r=DAR_BEAR},
      {q="Moonglade", cls="DRUID", g=DAR_BEAR, r=MG_DENDRITE},
      {q="Great Bear Spirit", cls="DRUID", g=MG_DENDRITE, o={39,27,"Talk to the Great Bear Spirit west along the mountains, finish its dialogue (verify)",MG}, r=MG_DENDRITE},
      {q="Back to Darnassus", cls="DRUID", g=MG_DENDRITE, r=DAR_BEAR},
      {q="Body and Heart", cls="DRUID", g=DAR_BEAR, o={43,46,"Use the Cenarion Lunardust at the Moonkin Stone in the cave east of Auberdine; kill Lunaclaw (12). First act of the next bracket",DS}, r={35,10,"Mathrengyl Bearwalker: Bear Form",DAR}},
      {q="The Enchanted Glade", g={38,34,"Sentinel Arynia Cloudsbreak, Oracle Glade moonwell (verify)"}, o={36,30,"Bloodfeather harpies around the glade"}},
      {q="Crown of the Earth", p=5, g={56,62,"Corithras Moonrage"}, o={38,34,"Amethyst Phial at the Oracle Glade moonwell"}, r={56,62,"Corithras Moonrage"}},
      {q="Mist", g={32,32,"Mist, the black panther"}, o={38,34,"Lead her to the Oracle Glade moonwell"}, r={38,34,"Sentinel Arynia Cloudsbreak"}},
      {q="Teldrassil", g={38,34,"Sentinel Arynia Cloudsbreak"}, r={35,9,"Arch Druid Fandral Staghelm, top of the Cenarion Enclave tree",DAR}},
      {q="The Shimmering Frond", g={35,29,"Shimmering Frond, Oracle Glade"}, r={61,68,"Denalan, Lake Al'Ameth"}},
      {q="The Moss-twined Heart", g={44,30,"Dropped by Blackmoss the Fetid, rare timberling at Wellspring River"}, r={61,68,"Denalan"}},
      {q="Return to Denalan", g={38,22,"Rellian Greenspyre",DAR}, r={61,68,"Denalan"}},
      {q="Grove of the Ancients", g={35,9,"Arch Druid Fandral Staghelm",DAR}, r={43,77,"Onu, Grove of the Ancients, Darkshore (verify)",DS}},
      {q="Sathrah's Sacrifice", g={37,86,"Priestess A'moora",DAR}, o={37,86,"The fountain in the Temple of the Moon",DAR}, r={37,86,"Priestess A'moora",DAR}},
      {q="Planting the Heart", g={61,68,"Denalan"}, o={61,69,"The planter beside him"}, r={61,68,"Denalan"}},
      {q="Oakenscowl", g={61,68,"Denalan"}, o={54,75,"Oakenscowl (9 elite) in the cave; use the Sprouted Frond and the Voodoo Claw"}, r={61,68,"Denalan"}},
      {lv=12},
      {q="Crown of the Earth", p=6, g={56,62,"Corithras Moonrage"}, r={35,9,"Arch Druid Fandral Staghelm, Darnassus",DAR}},
      {tr=true, x=56, y=92, t="Portal on the west edge of the Temple Gardens (29,41 Darnassus) down to Rut'theran Village."},
      {q="The Bounty of Teldrassil", g={56,92,"Nessa Shadowsong, Rut'theran Village"}, r={58,94,"Vesprystus, Rut'theran"}},
      {fp="Rut'theran", x=58, y=94},
      {q="Flight to Auberdine", g={58,94,"Vesprystus"}, r={37,44,"Innkeeper Shaussiy, Auberdine (verify)",DS}},
      {q="Return to Nessa", opt=true, g={37,44,"Auberdine inn",DS}, r={56,92,"Nessa Shadowsong, Rut'theran; turn in when you next pass"}},
      {forever=true, t="No source reports Teldrassil or Darnassus changes. Alliance Skyborne arrive at Dalaran by airship, not here."},
    },
  },
  -- ============================================================ 12-20 Darkshore
  {
    id="n3", lv={12,20}, name="Darkshore", map=DS,
    hub="Auberdine", hearth="Auberdine inn (Innkeeper Shaussiy)", fp="Auberdine (Caylais Moonfeather)",
    steps={
      {tr=true, x=37, y=44, t="Fly Rut'theran to Auberdine. Bind, flight point, one lap of the quest givers."},
      {bind="Auberdine", x=37, y=44},
      {fp="Auberdine", x=36, y=46},
      {q="Body and Heart", cls="DRUID", g=DAR_BEAR, o={43,46,"Moonkin Stone in the cave east of Auberdine: Lunardust, Lunaclaw"}, r={35,10,"Mathrengyl Bearwalker: Bear Form",DAR}},
      {note="Auberdine sweep", t="Cerellean Whiteclaw, Wizbang Cranktoggle upstairs, Thundris Windweaver and Terenthis north-east of the inn, Gwennyth Bly'Leggonde, Tharnariun Treetender across the bridge, Sentinels Tysha Moonblade and Glynda Nal'Shea, Barithras Moonshade, Gubber Blump on the docks, Sentinel Elissa Starbreeze upstairs across the bridge, the WANTED poster. No trainers in Darkshore: Darnassus is a free hippogryph and the portal."},
      {q="For Love Eternal", g={36,44,"Cerellean Whiteclaw, Auberdine"}, o={43,58,"Anaya Dawnrunner, the ghost patrolling Ameth'Aran (verify)"}},
      {q="Buzzbox 827", g={37,44,"Wizbang Cranktoggle, inn upstairs"}, o={36,40,"6 Crawler Legs from Pygmy Tide Crawlers on the beach north of town"}, r={37,44,"Wizbang Cranktoggle"}},
      {q="Bashal'Aran", p=1, g=AUB_THUNDRIS, r={44,36,"Asterion, Bashal'Aran"}},
      {q="Tools of the Highborne", g=AUB_THUNDRIS, o={43,58,"4 Highborne Relics from the ghosts of Ameth'Aran (verify count)"}},
      {q="Washed Ashore", p=1, g={37,44,"Gwennyth Bly'Leggonde"}, o={41,31,"Sea Creature Bones from the Beached Sea Creature north (verify)"}},
      {q="How Big a Threat?", p=1, g=AUB_TERENTHIS, o={42,56,"Walk the Blackwood furbolg camps south of Auberdine (verify)"}},
      {q="Plagued Lands", g={38,42,"Tharnariun Treetender, across the bridge"}, o={44,54,"Trap a Rabid Thistle Bear and lead it back to him"}},
      {q="The Fall of Ameth'Aran", g={37,44,"Sentinel Tysha Moonblade"}, o={43,58,"Read the two tablets in Ameth'Aran (verify)"}},
      {q="The Red Crystal", g={37,44,"Sentinel Glynda Nal'Shea"}, o={47,49,"The red crystal on the hill south-east of town"}},
      {q="Cave Mushrooms", g={37,44,"Barithras Moonshade"}, o={44,48,"Death Cap and Ashwood mushrooms in the two bear caves south-east (verify names, counts)"}},
      {q="The Shade of Elura", cls="WARRIOR", g=DAR_ELANARIA, o={31,44,"8 Elunite Ore from the crates around the wreck south of the dock and under it; Elura's Medallion from the Shade"}, r=DAR_ELANARIA},
      {q="Bashal'Aran", p=2, g={44,36,"Asterion"}, o={45,34,"8 Grell Earrings from Vile Sprites and Wild Grells around the ruins (verify count)"}},
      {q="Bashal'Aran", p=3, g={44,36,"Asterion"}, o={46,33,"Ancient Moonstone Seal from the Deth'ryll Satyrs"}},
      {q="Bashal'Aran", p=4, g={44,36,"Asterion"}, r={44,36,"Asterion"}},
      {q="Buzzbox 411", g={51,24,"Buzzbox 411, north on the coast road (verify)"}, o={50,20,"Thresher Eyes from the threshers in the shallows (verify count)"}},
      {q="Washed Ashore", p=2, g={37,44,"Gwennyth Bly'Leggonde"}, o={31,46,"Sea Turtle Remains from Skeletal Sea Turtles on the shore (verify)"}},
      {lv=14},
      {tr=true, x=40, y=45, map=DAR, any=true, t="Darnassus at 14: fly Rut'theran, walk the portal, train. Warriors: Elanaria, then Smith Mathiel."},
      {q="Buzzbox 323", g={51,24,"Buzzbox 411 (verify)"}, o={45,30,"Moonstalker Fangs (verify count)"}},
      {q="Lessons Anew", cls="DRUID", g=DAR_BEAR, r=MG_DENDRITE},
      {q="The Principal Source", cls="DRUID", g=MG_DENDRITE, o={55,34,"Fill the sampler at Cliffspring Falls, north-east of Auberdine (verify)"}, r=AUB_ALANN},
      {q="Gathering the Cure", cls="DRUID", g=AUB_ALANN, o={43,46,"12 Lunar Fungus from the cave by the Moonkin Stone, 5 Earthroot"}, r=AUB_ALANN},
      {q="Curing the Sick", cls="DRUID", g=AUB_ALANN, o={40,50,"Use the salve on 10 Sickly Deer along the road"}, r=MG_DENDRITE},
      {q="Power over Poison", cls="DRUID", g=MG_DENDRITE, r={35,10,"Mathrengyl Bearwalker: Cure Poison",DAR}},
      {q="How Big a Threat?", p=2, g=AUB_TERENTHIS, o={42,56,"Blackwood Ursas, Pathfinders and Windtalkers at the camps (verify counts)"}},
      {q="Thundris Windweaver", g=AUB_TERENTHIS, r=AUB_THUNDRIS},
      {q="The Cliffspring River", g=AUB_THUNDRIS, o={56,34,"Fill the glass at Cliffspring Falls (verify)"}},
      {q="Cleansing of the Infected", g={38,42,"Tharnariun Treetender"}, o={44,54,"20 Rabid Thistle Bears south of town"}},
      {q="As Water Cascades", g={47,49,"The Red Crystal"}, o={47,49,"Follow the quest text"}, r={37,44,"Sentinel Glynda Nal'Shea"}},
      {q="The Fragments Within", g={37,44,"Sentinel Glynda Nal'Shea"}, r={37,44,"Sentinel Glynda Nal'Shea"}},
      {q="Onu", g={37,44,"Barithras Moonshade"}, r={43,77,"Onu, Grove of the Ancients (verify)"}},
      {lv=16},
      {q="A Lesson to Learn", cls="DRUID", g=DAR_BEAR, r=MG_DENDRITE},
      {q="Trial of the Lake", cls="DRUID", g=MG_DENDRITE, o={52,40,"Shrine Bauble from the bottom of Lake Elune'ara; use it at the Shrine of Remulos (36,41), talk to Tajarri. 30 minutes",MG}, r={36,40,"Tajarri, Shrine of Remulos",MG}},
      {q="Trial of the Sea Lion", cls="DRUID", g={36,40,"Tajarri",MG}, o={49,11,"Pendant half between two boulders in the far-north Darkshore sea; the other is on the sea floor west of Westfall (18,33 Westfall), deep. Combine at the shrine"}, r=MG_DENDRITE},
      {q="Aquatic Form", cls="DRUID", g=MG_DENDRITE, r={35,10,"Mathrengyl Bearwalker: Aquatic Form",DAR}},
      {q="Erion's Behest", cls="ROGUE", g=DAR_ERION, r=DAR_ERION},
      {q="Redridge Rendezvous", cls="ROGUE", opt=true, g=DAR_ERION, r={30,45,"Lucius, Lakeshire, Redridge (from Menethil at 22-25, or skip)",RR}},
      {q="Alther's Mill", cls="ROGUE", opt=true, g={30,45,"Lucius, Lakeshire",RR}, o={44,44,"Pick the practice lockboxes at Alther's Mill east of Lakeshire until Lucius's Lockbox opens; Token of Thievery (verify coords)",RR}, r={30,45,"Lucius: Certificate of Thievery",RR}},
      {q="Buzzbox 525", g={51,24,"Buzzbox (verify)"}, o={38,50,"Reef Crawler parts on the beach (verify)"}},
      {q="Fruit of the Sea", g={36,45,"Gubber Blump, the docks"}, o={38,50,"6 Fine Crab Chunks from Reef Crawlers on the beach"}},
      {q="The Tower of Althalaxx", p=1, g={38,42,"Sentinel Elissa Starbreeze, upstairs across the bridge"}, r={55,26,"Balthule Shadowstrike, south of the tower (verify)"}},
      {q="The Tower of Althalaxx", p=2, g={55,26,"Balthule Shadowstrike (verify)"}, o={55,25,"Parchment scraps from Dark Strand Fanatics and Cultists at the tower (verify count)"}},
      {q="The Tower of Althalaxx", p=3, g={55,26,"Balthule Shadowstrike"}, r={55,26,"Balthule Shadowstrike"}},
      {q="The Tower of Althalaxx", p=4, g={55,26,"Balthule Shadowstrike"}, r={26,38,"Delgren the Purifier, Maestra's Post, Ashenvale",ASH}},
      {lv=18},
      {tr=true, x=40, y=45, map=DAR, any=true, t="Darnassus at 18: train."},
      {q="The Blackwood Corrupted", g=AUB_THUNDRIS, o={44,56,"Grain, nut and fruit samples from the Blackwood camps; summon and kill Xabraxxis at the Blackwood Den"}},
      {q="Tharnariun's Hope", g={38,42,"Tharnariun Treetender"}, o={52,36,"The Den Mother"}},
      {q="The Master's Glaive", g={43,77,"Onu, Grove of the Ancients (verify)"}, o={39,87,"Scrying Bowl at the Master's Glaive (verify)"}},
      {q="The Twilight Camp", g={39,87,"Scrying Bowl"}, o={39,87,"The Twilight Tome in the cultist camp at the Glaive"}, r={43,77,"Onu"}},
      {q="Return to Onu", g={39,87,"Twilight Tome"}, r={43,77,"Onu"}},
      {q="Therylune's Escape", g={38,87,"Therylune, the Master's Glaive"}, o={40,84,"Short escort out of the Glaive"}},
      {q="The Absent Minded Prospector", g={36,80,"Prospector Remtravel, the Master's Glaive (verify)"}, o={36,80,"Escort him around the dig"}},
      {q="WANTED: Murkdeep!", opt=true, g={37,44,"WANTED poster, Auberdine"}, o={36,76,"Murkdeep at the murloc camp; group"}, r={37,44,"Sentinel Glynda Nal'Shea"}},
      {q="Gyromast's Retrieval", opt=true, g={44,57,"Gelkak Gyromast, Mist's Edge (verify)"}, o={44,60,"Follow the quest text"}},
      {lv=20},
      {q="Elune's Grace", cls="PRIEST", g={40,81,"Astarii Starseeker, Temple of the Moon, Darnassus (or Laurna, Dolanaar)",DAR}, r={40,81,"Astarii Starseeker: Elune's Grace",DAR}},
      {q="Onward to Ashenvale", g=AUB_THUNDRIS, r={26,38,"Sentinel Onaeya, Maestra's Post, Ashenvale (verify)",ASH}},
      {q="The Sleeper Has Awakened", g={37,44,"Kerlonian Evanson, Auberdine"}, o={26,38,"Escort him down the road to Maestra's Post, Ashenvale",ASH}, r={26,38,"Maestra's Post",ASH}},
      {forever=true, t="Nothing announced touches Darkshore. Wetlands is the announced Alliance expansion and the Auberdine boat reaches it at 23."},
    },
  },
}

-- Night Elf route = the three brackets above, then the shared Alliance brackets (Routes_Human.lua).
local ALLIANCE = ns.ALLIANCE_BRACKETS or {}
local ROUTE_BRACKETS = {}
for _, b in ipairs(ns.NIGHTELF_BRACKETS) do table.insert(ROUTE_BRACKETS, b) end
for _, b in ipairs(ALLIANCE) do table.insert(ROUTE_BRACKETS, b) end

table.insert(ns.ROUTES, {
  id = "nightelf", name = "The Moon Road", faction = "Alliance",
  races = { NightElf = true }, raceOnly = 3,
  brackets = ROUTE_BRACKETS,
})
