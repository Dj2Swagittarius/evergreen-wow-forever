-- Evergreen route: Orc ("The Blood Road"). Loaded after Data.lua and Routes_Tauren.lua; appends to ns.ROUTES.
-- Step format is documented at the top of Data.lua. Class steps carry cls="WARLOCK" etc.
-- Two race-only brackets (Valley of Trials, Durotar), then the Tauren Barrens / Stonetalon / Needles
-- brackets (t3, t4, t5) and the shared Horde brackets from 30 on (b7..b12). Shared Horde class chains
-- (poisons, Succubus, Orb of Soran'ruk, Felhunter, Felsteed, the level-50 Sunken Temple chains,
-- Dreadsteed) are injected by Routes_Tauren.lua and Routes_Troll.lua, not here.
local ADDON, ns = ...

local DUR, ORG, BAR = 1411, 1454, 1413
ns.MAP_NAMES[ORG] = ns.MAP_NAMES[ORG] or "Orgrimmar"

local RH_GARTHOK = {52,44,"Gar'Thok, Razor Hill"}
local RH_ORGNIL = {52,43,"Orgnil Soulscar, Razor Hill"}
local RH_THOTAR = {52,43,"Thotar, Razor Hill hunter trainer"}
local SJ_GADRIN = {56,75,"Master Gadrin, Sen'jin Village"}
local ORG_GANRUL = {47,50,"Gan'rul Bloodeye, Darkfire Enclave, Cleft of Shadow",ORG}
local ORG_THERZOK = {44,53,"Therzok, Cleft of Shadow (verify)",ORG}
local ORG_NEERU = {50,51,"Neeru Fireblade, Cleft of Shadow (verify)",ORG}
local ORG_THRALL = {32,38,"Thrall, Grommash Hold, Valley of Wisdom (verify)",ORG}
local FW_UZZEK = {62,31,"Uzzek, under the tree south-west of Far Watch Post (verify)",BAR}

ns.ORC_BRACKETS = {
  -- ============================================================ 1-6 Valley of Trials
  {
    id="o1", lv={1,6}, name="Valley of Trials", map=DUR,
    hub="The Den", hearth="Already bound to the Valley of Trials", fp="None",
    steps={
      {note="Before you move", t="Turn on Auto Loot. Bind a key to Blood Fury. All the class trainers stand in or beside the Den; the scroll you spawn with is a free turn-in there."},
      {q="Your Place In The World", id=4641, g={43,68,"Kaltunk, where you spawn"}, r={42,68,"Gornek, inside the Den"}},
      {q="Cutting Teeth", id=788, g={42,68,"Gornek"}, o={44,64,"10 Mottled Boars at the farms north and north-east of the Den"}},
      {q="Vile Familiars", id=1485, cls="WARLOCK", g={42,69,"Ruzan, west of the Den entrance"}, o={45,58,"6 Vile Familiar Heads from the imps outside the Burning Blade cave"}, r={42,69,"Ruzan: Summon Imp"}},
      {q="Sting of the Scorpid", id=789, g={42,68,"Gornek"}, o={41,62,"10 Scorpid Worker Tails, the scorpid field north-west of the Den"}},
      {q="Galgar's Cactus Apple Surprise", id=4402, g={43,63,"Galgar, north of the Den"}, o={44,60,"10 Cactus Apples off the ground beside cacti all over the valley"}},
      {q="Lazy Peons", id=5441, g={45,69,"Foreman Thazz'ril, east of the Den"}, o={47,70,"Blackjack 5 sleeping Lazy Peons in the logging area south and east of the Den"}},
      {q="Vile Familiars", p=1, g={42,68,"Gornek"}, r={46,63,"Zureetha Fargaze, by the wagon north of the Den (verify)"}},
      {q="Sarkoth", p=1, id=804, g={41,63,"Hana'zua, dying under a tree in the scorpid field"}, o={40,66,"Sarkoth (4) on the plateau south of Hana'zua, up the ramp; loot his Mangled Claw"}, r={41,63,"Hana'zua"}},
      {q="Sarkoth", p=2, g={41,63,"Hana'zua"}, r={42,68,"Gornek"}},
      {q="Call of Earth", p=1, id=1516, cls="SHAMAN", g={42,69,"Canaga Earthcaller, west of the Den entrance"}, o={45,57,"2 Felstalker Hooves from Felstalkers around and inside the Burning Blade cave"}},
      {q="Call of Earth", p=2, id=1517, cls="SHAMAN", g={42,69,"Canaga Earthcaller"}, o={44,76,"Hidden Path south of the Den (41,73) to Spirit Rock: drink the Earth Sapta, talk to the Minor Manifestation of Earth"}, r={44,76,"Minor Manifestation of Earth, Spirit Rock"}},
      {q="Call of Earth", p=3, id=1518, cls="SHAMAN", g={44,76,"Minor Manifestation of Earth"}, r={42,69,"Canaga Earthcaller: Earth Totem, Stoneskin Totem"}},
      {q="Vile Familiars", p=2, id=792, g={46,63,"Zureetha Fargaze"}, o={45,56,"12 Vile Familiars outside and in the mouth of the Burning Blade cave"}},
      {q="Thazz'ril's Pick", g={45,69,"Foreman Thazz'ril"}, o={43,53,"The pick glows in the back of the cave before a rock pillar near the waterfalls, west from the big chamber"}},
      {q="Burning Blade Medallion", id=794, g={46,63,"Zureetha Fargaze"}, o={42,52,"Yarrog Baneshadow (5) deep in the cave: keep right, follow the path to the end; loot the medallion"}},
      {q="Report to Sen'jin Village", g={46,63,"Zureetha Fargaze"}, r=SJ_GADRIN},
      {q="A Peon's Burden", id=2161, g={52,68,"Ukor, on the east exit path"}, r={51,41,"Innkeeper Grosk, Razor Hill"}},
      {forever=true, t="Nothing announced touches the valley. Orc mages start here with Mai'ah in the Den; no Orc mage quest has been published."},
      {lv=6},
    },
  },
  -- ============================================================ 6-12 Sen'jin, Razor Hill, Durotar
  {
    id="o2", lv={6,12}, name="Sen'jin Village, Razor Hill & Durotar", map=DUR,
    hub="Sen'jin Village, Razor Hill", hearth="Razor Hill inn (Innkeeper Grosk)", fp="None here; Orgrimmar (Doras) at 10",
    steps={
      {tr=true, x=56, y=75, t="East out of the valley; take the south-east fork to Sen'jin Village."},
      {note="Pickup sweep", t="Sen'jin: Gadrin, Vornal, Vel'rin Fang, Lar Prowltusk. Razor Hill: Gar'Thok, Cook Torka, Orgnil, Furl Scornbrow on the watchtower. Learn First Aid (Rawrk, verify), Skinning and Herbalism."},
      {q="Report to Orgnil", id=823, g=SJ_GADRIN, r=RH_ORGNIL},
      {q="A Solvent Spirit", id=818, g={56,74,"Master Vornal, Sen'jin Village"}, o={62,50,"4 Intact Makrura Eyes, 8 Crawler Mucus from makrura and surf crawlers on the coast east of Tiragarde and around the Echo Isles"}},
      {q="Practical Prey", id=817, g={56,74,"Vel'rin Fang, Sen'jin Village"}, o={64,82,"4 Durotar Tiger Furs from Durotar Tigers on the Echo Isles"}},
      {q="Thwarting Kolkar Aggression", id=786, g={55,75,"Lar Prowltusk, south-west of the huts"}, o={48,78,"Destroy the 3 Attack Plans in Kolkar Crag: 50,81 · 48,77 · 46,79 (verify)"}},
      {q="Minshina's Skull", g=SJ_GADRIN, o={67,88,"Click any skull at the candle-lit shrine on the southernmost Echo Isle"}},
      {q="Zalazane", id=826, g=SJ_GADRIN, o={67,86,"8 Voodoo Trolls, 8 Hexed Trolls, then Zalazane (10) at the camp on the big isle; loot his head. Do it at 9"}},
      {tr=true, x=52, y=43, t="North on the road to Razor Hill."},
      {bind="Razor Hill", x=51, y=41},
      {q="Vanquish the Betrayers", g=RH_GARTHOK, o={57,55,"10 Kul Tiras Sailors, 8 Marines at Tiragarde Keep; Lieutenant Benedict (8) upstairs at 59,58, loot his key, open his chest"}},
      {q="Carry Your Weight", g={49,40,"Furl Scornbrow, watchtower north-west of Razor Hill (verify)"}, o={57,55,"8 Canvas Scraps from the Kul Tiras humans at Tiragarde and the Kolkar at Kolkar Crag"}},
      {q="Break a Few Eggs", id=815, g={51,42,"Cook Torka, Razor Hill"}, o={63,80,"3 Taillasher Eggs from Bloodtalon Taillashers on the Echo Isles"}},
      {q="Encroachment", id=837, g=RH_GARTHOK, o={49,49,"4 Razormane Quilboar, 4 Scouts at the Razormane Grounds south of town; 4 Dustrunners, 4 Battleguards at the northern camp (55,27)"}},
      {q="The Admiral's Orders", p=1, g={59,58,"Admiral Proudmoore's Orders, Benedict's chest at Tiragarde Keep"}, r=RH_GARTHOK},
      {q="From The Wreckage....", g=RH_GARTHOK, o={61,52,"3 Gnomish Tools from crates on and under the half-sunken ships at the Scuttle Coast"}},
      {lv=10},
      {tr=true, x=45, y=64, map=ORG, any=true, t="Level 10: walk the road north to Orgrimmar. Flight point from Doras in the Valley of Strength. Train, learn professions, then the class quests. Keep the Razor Hill bind."},
      {fp="Orgrimmar", x=45, y=64, map=ORG},
      {q="The Admiral's Orders", p=2, g=RH_GARTHOK, r={32,38,"Nazgrel, Grommash Hold, Valley of Wisdom (verify)",ORG}},
      {q="Hidden Enemies", p=1, g=ORG_THRALL, o={55,10,"Lieutenant's Insignia from any Burning Blade cultist in Skull Rock (with the Margoz loop at 11)"}, r=ORG_THRALL},
      {q="Veteran Uzzek", id=1505, cls="WARRIOR", g={54,43,"Tarshaw Jaggedscar, Razor Hill barracks"}, r=FW_UZZEK},
      {q="Path of Defense", id=1498, cls="WARRIOR", g=FW_UZZEK, o={41,29,"5 Singed Scales from thunder lizards at Thunder Ridge (entrance 39,31); talk to Uzzek first, then do it with Dark Storms at 11"}, r={62,31,"Uzzek: Defensive Stance, Sunder Armor, Taunt (verify)",BAR}},
      {q="The Hunter's Path", id=6070, cls="HUNTER", g={42,68,"Jen'shan, the Den (or Thotar, Razor Hill)"}, r=RH_THOTAR},
      {q="Taming the Beast", p=1, id=6062, cls="HUNTER", g=RH_THOTAR, o={52,46,"Use the Taming Rod on a Dire Mottled Boar right outside Razor Hill"}},
      {q="Taming the Beast", p=2, id=6083, cls="HUNTER", g=RH_THOTAR, o={60,72,"Tame a Surf Crawler on the beach across from Sen'jin toward the Echo Isles (verify)"}},
      {q="Taming the Beast", p=3, id=6082, cls="HUNTER", g=RH_THOTAR, o={48,36,"Tame an Armored Scorpid, the yellow scorpids in central Durotar north of Razor Hill (verify). Reward: Tame Beast, Call Pet, Dismiss Pet"}},
      {q="Training the Beast", id=6081, cls="HUNTER", g=RH_THOTAR, r={66,18,"Ormak Grimshot, Hunter's Hall, Valley of Honor: Beast Training, Feed Pet, Revive Pet",ORG}},
      {q="Call of Fire", p=1, id=1522, cls="SHAMAN", g={38,37,"Searn Firewarder, Grommash Hold, Valley of Wisdom (verify; or Swart in Razor Hill)",ORG}, r={56,20,"Kranal Fiss, Grol'dom Farm north of the Crossroads (verify)",BAR}},
      {q="Gan'rul's Summons", id=1506, cls="WARLOCK", g={54,41,"Ophek, Razor Hill"}, r=ORG_GANRUL},
      {q="Creature of the Void", id=1501, cls="WARLOCK", g=ORG_GANRUL, o={55,10,"Tablet of Verga from the Burning Blade Stash chest inside Skull Rock (with the Margoz loop at 11)"}, r=ORG_GANRUL},
      {q="The Binding", id=1504, cls="WARLOCK", g=ORG_GANRUL, o={50,51,"Use the Glyphs of Summoning at the circle in Neeru Fireblade's tent, Cleft of Shadow; kill the Voidwalker",ORG}, r={47,50,"Gan'rul Bloodeye: Summon Voidwalker",ORG}},
      {q="Therzok", cls="ROGUE", g={52,43,"Kaplak, Razor Hill rogue trainer (verify)"}, r=ORG_THERZOK},
      {q="The Shattered Hand", id=1858, cls="ROGUE", g=ORG_THERZOK, o={62,42,"Pickpocket Tazan's key from Tazan, a troll on the coast south of Ratchet; open his satchel (verify). Do it at 13-14",BAR}, r={44,53,"Therzok: Blade of Cunning",ORG}},
      {q="Winds in the Desert", id=834, g={46,23,"Rezlak, by the Orgrimmar road"}, o={49,22,"5 Sacks of Supplies from Dustwind harpies in Razorwind Canyon"}},
      {q="Securing the Lines", id=835, g={46,23,"Rezlak"}, o={52,25,"12 Dustwind Savages, 8 Dustwind Storm Witches in Drygulch Ravine"}},
      {q="Dark Storms", g=RH_ORGNIL, o={42,27,"Fizzle Darkstorm (12) at Thunder Ridge, north-west Durotar (entrance 39,31); loot his claw"}},
      {q="Lost But Not Forgotten", id=816, opt=true, g={43,30,"Misha Tor'kren, Tor'kren Farm"}, o={38,38,"Kron's Amulet, random drop from Dreadmaw Crocolisks along the Southfury River (verify)"}},
      {q="Need for a Cure", id=812, opt=true, g={41,18,"Rhinag, Rocktusk Farm (verify)"}, r={47,53,"Kor'ghan, Cleft of Shadow",ORG}},
      {q="Finding the Antidote", id=813, opt=true, g={47,53,"Kor'ghan, Cleft of Shadow",ORG}, o={44,15,"4 Venomtail Poison Sacs from Venomtail Scorpids south-west of the Orgrimmar gate (verify)"}, r={47,53,"Kor'ghan",ORG}},
      {q="Margoz", id=828, g=RH_ORGNIL, r={56,20,"Margoz, tent south of Bladefist Bay"}},
      {q="Skull Rock", id=827, g={56,20,"Margoz"}, o={55,10,"6 Searing Collars from Burning Blade cultists in Skull Rock, the cave in the north-east cliffs; Gazz'uz (14) at the back drops the Eye of Burning Shadow"}},
      {q="Burning Shadows", id=832, g={55,10,"Eye of Burning Shadow, from Gazz'uz in Skull Rock"}, r=ORG_NEERU},
      {q="Neeru Fireblade", g={56,20,"Margoz"}, r=ORG_NEERU},
      {q="Hidden Enemies", p=2, g=ORG_THRALL, r=ORG_NEERU},
      {q="Hidden Enemies", p=3, opt=true, g=ORG_NEERU, o={50,51,"Ragefire Chasm: kill Bazzalan and Jergosh the Invoker (group)",ORG}, r=ORG_THRALL},
      {q="Ak'Zeloth", g=ORG_NEERU, r={62,35,"Ak'Zeloth, Far Watch Post (verify)",BAR}},
      {q="Conscript of the Horde", id=840, g={51,44,"Takrin Pathseeker, Razor Hill"}, r={62,35,"Kargal Battlescar, Far Watch Post (verify)",BAR}},
      {q="Crossroads Conscription", g={62,35,"Kargal Battlescar, Far Watch Post (verify)",BAR}, r={52,31,"Sergra Darkthorn, the Crossroads",BAR}},
      {q="The Demon Seed", id=924, g={62,35,"Ak'Zeloth, Far Watch Post (verify)",BAR}, o={48,18,"Use the Flawed Power Stone at the Altar of Fire in the cavern just below the summit of Dreadmist Peak, within 30 minutes",BAR}, r={62,35,"Ak'Zeloth: Banshee Armor",BAR}},
      {forever=true, t="No source reports Durotar or Orgrimmar changes. The Undercity-surface zone (15-25) is one zeppelin from the gate."},
      {lv=12},
    },
  },
}

-- Orc route = the two brackets above, then the Tauren Barrens / Stonetalon / Needles brackets
-- (12-30, ids t3-t5), then the shared Horde brackets from 30-35 on (b7-b12).
local ROUTE_BRACKETS = {}
for _, b in ipairs(ns.ORC_BRACKETS) do table.insert(ROUTE_BRACKETS, b) end
for i = 3, 5 do table.insert(ROUTE_BRACKETS, ns.TAUREN_BRACKETS[i]) end
for i = 7, #ns.BRACKETS do table.insert(ROUTE_BRACKETS, ns.BRACKETS[i]) end

table.insert(ns.ROUTES, {
  id = "orc", name = "The Blood Road", faction = "Horde",
  races = { Orc = true }, raceOnly = 2,
  brackets = ROUTE_BRACKETS,
})
