-- Evergreen route: Troll ("The Loa's Path"). Loaded after Data.lua and Routes_Tauren.lua; appends to ns.ROUTES.
-- Step format is documented at the top of Data.lua. Class steps carry cls="PRIEST" etc.
-- Two race-only brackets (Valley of Trials, then Sen'jin / Razor Hill / Durotar with the level-10
-- Orgrimmar trip), then the Tauren file's Barrens / Stonetalon / Needles brackets (t3-t5) and the
-- shared Horde brackets from 30 on. Also injects the shared Horde caster and rogue class chains
-- (rogue, priest, mage, warlock) into t3, t4, t5, b8, b11 and b12 once, guarded so Routes_Orc.lua
-- can carry the same block without duplicating steps.
local ADDON, ns = ...

local DUR, ORG, BAR, STM, ASH, TN, UC, HILLS = 1411, 1454, 1413, 1442, 1440, 1441, 1458, 1424
local DUSTW, TIRIS, ARATHI, AZSH, FELW, SWAMP, STEPPES, WETL = 1445, 1420, 1417, 1447, 1448, 1435, 1428, 1437
ns.MAP_NAMES[WETL] = "Wetlands"

local GORNEK   = {42,68,"Gornek, inside the Den"}
local ZUREETHA = {46,64,"Zureetha Fargaze, by the wagon outside the Den (verify)"}
local CANAGA   = {42,69,"Canaga Earthcaller, west of the Den entrance"}
local GADRIN   = {56,75,"Master Gadrin, Sen'jin Village"}
local GARTHOK  = {52,44,"Gar'Thok, Razor Hill"}
local ORGNIL   = {52,43,"Orgnil Soulscar, Razor Hill"}
local THOTAR   = {52,43,"Thotar, Razor Hill hunter trainer"}
local MARGOZ   = {56,20,"Margoz, tent south of Bladefist Bay"}
local THRALL   = {32,38,"Thrall, Grommash Hold, Valley of Wisdom (verify)",ORG}
local NEERU    = {50,51,"Neeru Fireblade, Cleft of Shadow (verify)",ORG}
local GANRUL   = {47,50,"Gan'rul Bloodeye, Darkfire Enclave, Cleft of Shadow",ORG}
local SEARN    = {39,37,"Searn Firewarder, Grommash Hold, Valley of Wisdom (or Swart, Sen'jin Village)",ORG}
local URKYO    = {36,88,"Ur'kyo, Spirit Lodge, Valley of Spirits",ORG}
local SHENTHUL = {43,54,"Shenthul, Shadowswift Brotherhood, Cleft of Shadow",ORG}
local THERZOK  = {43,54,"Therzok, Shadowswift Brotherhood, Cleft of Shadow (verify)",ORG}
local DEINO    = {39,86,"Deino, Darkbriar Lodge, Valley of Spirits",ORG}
local STRAHAD  = {63,37,"Strahad Farsan, tower above Ratchet",BAR}
local FARWATCH = {62,35,"Far Watch Post, west of the Southfury bridge (verify)",BAR}

ns.TROLL_BRACKETS = {
  -- ============================================================ 1-6 Valley of Trials
  {
    id="tr1", lv={1,6}, name="Valley of Trials", map=DUR,
    hub="The Den", hearth="Already bound to the Valley of Trials", fp="None",
    steps={
      {note="Before you move", t="Turn on Auto Loot. Bind a key to Berserking. All seven class trainers stand in or beside the Den; the scroll you spawn with is a free turn-in there."},
      {q="Your Place In The World", id=4641, g={43,68,"Kaltunk, where you spawn"}, r=GORNEK},
      {q="Cutting Teeth", id=788, g=GORNEK, o={45,64,"10 Mottled Boars at the farms north and north-east of the Den"}},
      {q="Vile Familiars", id=1485, cls="WARLOCK", g={42,69,"Ruzan, west of the Den entrance"}, o={45,58,"6 Vile Familiar Heads from the imps outside the Burning Blade cave"}, r={42,69,"Ruzan: Summon Imp"}},
      {q="Sarkoth", p=1, id=804, g={41,63,"Hana'zua, dying under a tree in the scorpid field north-west"}, o={41,61,"Sarkoth (4) on the plateau south of Hana'zua, up the ramp; loot the Mangled Claw"}, r={41,63,"Hana'zua"}},
      {q="Sarkoth", p=2, g={41,63,"Hana'zua"}, r=GORNEK},
      {q="Sting of the Scorpid", id=789, g=GORNEK, o={41,62,"10 Scorpid Worker Tails from the scorpids around Hana'zua"}},
      {q="Galgar's Cactus Apple Surprise", id=4402, g={43,63,"Galgar, the cook north of the Den"}, o={44,62,"10 Cactus Apples off the ground beside cacti all over the valley"}},
      {q="Lazy Peons", id=5441, g={45,69,"Foreman Thazz'ril, east of the Den"}, o={46,71,"Blackjack 5 sleeping Lazy Peons in the logging area south and east of the Den"}},
      {q="Vile Familiars", id=792, g=ZUREETHA, o={45,57,"12 Vile Familiars, the imps outside and inside the Burning Blade cave (entrance 45,56)"}},
      {q="Thazz'ril's Pick", g={45,69,"Foreman Thazz'ril"}, o={43,53,"The pick glows at the back of the cave by the waterfalls, west from the big chamber"}},
      {q="Call of Earth", p=1, id=1516, cls="SHAMAN", g=CANAGA, o={45,58,"2 Felstalker Hooves from Felstalkers around and inside the Burning Blade cave"}},
      {q="Call of Earth", p=2, id=1517, cls="SHAMAN", g=CANAGA, o={44,76,"Walk the Hidden Path (entrance 41,73) to Spirit Rock; drink the Earth Sapta, talk to the Minor Manifestation of Earth"}, r={44,76,"Minor Manifestation of Earth, Spirit Rock"}},
      {q="Call of Earth", p=3, id=1518, cls="SHAMAN", g={44,76,"Minor Manifestation of Earth"}, r={42,69,"Canaga Earthcaller: Earth Totem, Stoneskin Totem"}},
      {q="Burning Blade Medallion", id=794, g=ZUREETHA, o={42,52,"Yarrog Baneshadow (5) at the end of the cave: keep right from the entrance; loot the medallion"}},
      {q="Report to Sen'jin Village", g=ZUREETHA, r=GADRIN},
      {q="A Peon's Burden", id=2161, g={52,68,"Ukor, on the east exit path"}, r={51,41,"Innkeeper Grosk, Razor Hill"}},
      {forever=true, t="Nothing announced touches the Valley of Trials. Troll warlocks are new in Forever; the Orc starter chain is assumed until the beta says otherwise."},
      {lv=6},
    },
  },
  -- ============================================================ 6-12 Sen'jin, Razor Hill, Durotar
  {
    id="tr2", lv={6,12}, name="Sen'jin Village, Razor Hill & Durotar", map=DUR,
    hub="Sen'jin Village, then Razor Hill", hearth="Razor Hill inn (Innkeeper Grosk); Sen'jin has no inn", fp="None in Durotar; Orgrimmar (Doras) at 10",
    steps={
      {tr=true, x=56, y=75, t="East out of the valley, then south along the coast road to Sen'jin Village."},
      {note="Sen'jin sweep", t="Master Gadrin, Master Vornal, Vel'rin Fang, Lar Prowltusk at the south-west edge. Mages: Un'thuwa. Shamans train with Swart. Do not bind here; Razor Hill at 7."},
      {q="Report to Orgnil", id=823, g=GADRIN, r=ORGNIL},
      {q="A Solvent Spirit", id=818, g={56,74,"Master Vornal, Sen'jin Village"}, o={62,52,"4 Intact Makrura Eyes, 8 Crawler Mucus from makrura and surf crawlers on the coast east of Tiragarde and around the Echo Isles"}},
      {q="Practical Prey", id=817, g={56,74,"Vel'rin Fang, Sen'jin Village"}, o={65,84,"4 Durotar Tiger Furs on the Echo Isles"}},
      {q="Thwarting Kolkar Aggression", id=786, g={55,75,"Lar Prowltusk, south-west edge of Sen'jin"}, o={48,79,"Destroy the three Attack Plans in Kolkar Crag: 50,81, 48,77, 46,79 (verify)"}},
      {q="Minshina's Skull", g=GADRIN, o={67,88,"Click a skull at the shrine on the southernmost Echo Isle"}},
      {q="Zalazane", id=826, g=GADRIN, o={67,86,"8 Voodoo Trolls, 8 Hexed Trolls, then Zalazane (10) at the main camp on the big isle; loot his head"}},
      {q="Ju-Ju Heaps", id=1884, cls="MAGE", g={56,74,"Un'thuwa, Sen'jin mage trainer"}, o={67,86,"Destroy 4 Ju-Ju Heaps among the huts on the main Echo Isle"}, r={56,74,"Un'thuwa: Ley Orb or Ley Staff"}},
      {tr=true, x=52, y=43, t="North up the road to Razor Hill."},
      {bind="Razor Hill", x=51, y=41},
      {note="Razor Hill sweep", t="Orgnil Soulscar, Gar'Thok, Takrin Pathseeker, Cook Torka, Furl Scornbrow at the watchtower north-west of town. Learn First Aid from Rawrk, pick up Skinning and a gathering profession. Hunters: Thotar. Warriors: Tarshaw Jaggedscar and priests: Tai'jin in the barracks. Warlocks: Ophek."},
      {q="Vanquish the Betrayers", g=GARTHOK, o={58,56,"10 Kul Tiras Sailors, 8 Marines, then Lieutenant Benedict (8) upstairs in Tiragarde Keep; loot Benedict's Key, open his chest"}},
      {q="The Admiral's Orders", p=1, id=830, g={59,58,"Aged Envelope from Benedict's chest, Tiragarde Keep"}, r=GARTHOK},
      {q="Carry Your Weight", g={49,40,"Furl Scornbrow, watchtower north-west of Razor Hill (verify)"}, o={57,55,"8 Canvas Scraps from Kul Tiras humans at Tiragarde and Kolkar centaur at Kolkar Crag"}},
      {q="From The Wreckage....", g=GARTHOK, o={61,52,"3 Gnomish Tools from crates on and under the wrecks at Scuttle Coast"}},
      {q="Break a Few Eggs", id=815, g={51,42,"Cook Torka, Razor Hill"}, o={65,85,"3 Taillasher Eggs from Bloodtalon Taillashers on the Echo Isles"}},
      {q="Encroachment", id=837, g=GARTHOK, o={49,49,"4 Razormane Quilboar, 4 Scouts at the Razormane Grounds south of town; 4 Dustrunners, 4 Battleguards at the northern camp by Dustwind Cave (55,27)"}},
      {q="Dark Storms", g=ORGNIL, o={42,27,"Fizzle Darkstorm (12) at Thunder Ridge, north-west Durotar (ridge entrance 39,31); loot Fizzle's Claw"}},
      {q="Winds in the Desert", id=834, g={46,23,"Rezlak, by the road in Drygulch Ravine"}, o={49,22,"5 Sacks of Supplies from Dustwind harpies in Razorwind Canyon"}},
      {q="Securing the Lines", id=835, g={46,23,"Rezlak"}, o={52,25,"12 Dustwind Savages, 8 Dustwind Storm Witches in Drygulch Ravine"}},
      {q="Lost But Not Forgotten", id=816, g={43,30,"Misha Tor'kren, Tor'kren Farm"}, o={38,38,"Kron's Amulet, a random drop from Dreadmaw Crocolisks along the Southfury River (verify)"}},
      {q="Need for a Cure", id=812, opt=true, g={41,18,"Rhinag, Rocktusk Farm (verify)"}, r={47,53,"Kor'ghan, Cleft of Shadow, Orgrimmar",ORG}},
      {q="Finding the Antidote", id=813, opt=true, g={47,53,"Kor'ghan, Cleft of Shadow",ORG}, o={45,60,"4 Venomtail Poison Sacs from Venomtail Scorpids south-west of the Orgrimmar gate (verify)"}, r={47,53,"Kor'ghan",ORG}},
      {lv=10},
      {tr=true, x=47, y=50, map=ORG, any=true, t="Level 10: Orgrimmar. Walk the road north from Razor Hill. Train, learn professions, get the flight point from Doras in the Valley of Strength. Keep the Razor Hill bind."},
      {fp="Orgrimmar", x=45, y=64, map=ORG},
      {q="The Admiral's Orders", p=2, id=831, g=GARTHOK, r={32,38,"Nazgrel, Thrall's chamber, Grommash Hold, Valley of Wisdom (verify)",ORG}},
      {q="Hidden Enemies", p=1, id=5726, opt=true, g=THRALL, o={55,10,"Lieutenant's Insignia from a Burning Blade cultist in Skull Rock"}, r=THRALL},
      {q="Veteran Uzzek", id=1505, cls="WARRIOR", g={54,43,"Tarshaw Jaggedscar, Razor Hill Barracks"}, r={62,31,"Uzzek, under a tree south-west of Far Watch Post (verify)",BAR}},
      {q="The Hunter's Path", id=6070, cls="HUNTER", g={52,43,"Thotar, Razor Hill (or Jen'shan in the valley)"}, r=THOTAR},
      {q="Taming the Beast", p=1, id=6062, cls="HUNTER", g=THOTAR, o={53,46,"Use the Taming Rod on a Dire Mottled Boar right outside Razor Hill"}},
      {q="Taming the Beast", p=2, id=6083, cls="HUNTER", g=THOTAR, o={60,72,"Tame a Surf Crawler on the beach across from Sen'jin Village"}},
      {q="Taming the Beast", p=3, id=6082, cls="HUNTER", g=THOTAR, o={48,35,"Tame an Armored Scorpid, central Durotar north of Razor Hill (verify). Reward: Tame Beast"}},
      {q="Training the Beast", id=6081, cls="HUNTER", g=THOTAR, r={66,18,"Ormak Grimshot, Hunter's Hall, Valley of Honor, Orgrimmar",ORG}},
      {q="Call of Fire", p=1, cls="SHAMAN", g=SEARN, r={56,20,"Kranal Fiss, Grol'dom Farm north of the Crossroads (verify)",BAR}},
      {q="Hex of Weakness", id=5656, cls="PRIEST", g={54,43,"Tai'jin, Razor Hill Barracks (or Ken'jai in the valley)"}, r={36,88,"Ur'kyo, Spirit Lodge, Valley of Spirits: learn Hex of Weakness",ORG}},
      {q="Therzok", cls="ROGUE", g={52,43,"Kaplak, Razor Hill (verify)"}, r=THERZOK},
      {q="The Shattered Hand", id=1858, cls="ROGUE", g=THERZOK, o={64,44,"Pickpocket Tazan's Satchel Key from Tazan on the coast south of Ratchet; open his satchel (verify)",BAR}, r={43,54,"Therzok: Blade of Cunning",ORG}},
      {q="Gan'rul's Summons", id=1506, cls="WARLOCK", g={54,41,"Ophek, Razor Hill"}, r=GANRUL},
      {q="Creature of the Void", id=1501, cls="WARLOCK", g=GANRUL, o={55,10,"Tablet of Verga from the Burning Blade Stash chest inside Skull Rock"}, r=GANRUL},
      {q="The Binding", p=1, id=1504, cls="WARLOCK", g=GANRUL, o={50,51,"Use the Glyphs of Summoning at the circle in Neeru Fireblade's tent, Cleft of Shadow; defeat the Voidwalker",ORG}, r={47,50,"Gan'rul Bloodeye: Summon Voidwalker",ORG}},
      {q="Margoz", id=828, g=ORGNIL, r=MARGOZ},
      {q="Skull Rock", id=827, g=MARGOZ, o={55,10,"6 Searing Collars from Burning Blade cultists in Skull Rock, north-east cliffs; Gazz'uz (14) at the back drops the Eye of Burning Shadow"}},
      {q="Burning Shadows", id=832, g={55,10,"Eye of Burning Shadow, dropped by Gazz'uz in Skull Rock"}, r=NEERU},
      {q="Neeru Fireblade", g=MARGOZ, r=NEERU},
      {q="Ak'Zeloth", g=NEERU, r={62,35,"Ak'Zeloth, Far Watch Post (verify)",BAR}},
      {q="Conscript of the Horde", id=840, g={51,44,"Takrin Pathseeker, Razor Hill"}, r={62,35,"Kargal Battlescar, Far Watch Post (verify)",BAR}},
      {q="Crossroads Conscription", g={62,35,"Kargal Battlescar, Far Watch Post (verify)",BAR}, r={52,31,"Sergra Darkthorn, the Crossroads",BAR}},
      {q="The Demon Seed", id=924, g={62,35,"Ak'Zeloth, Far Watch Post (verify)",BAR}, o={48,18,"Flawed Power Stone on the Altar of Fire in the small cavern below the summit of Dreadmist Peak, 30 minutes; do it at 13-14",BAR}, r={62,35,"Ak'Zeloth: Banshee Armor",BAR}},
      {forever=true, t="No source reports Durotar or Orgrimmar changes. The Undercity surface zone (15-25) is one zeppelin away if the Barrens are crowded."},
      {lv=12},
    },
  },
}

-- ------------------------------------------------------------------ shared Horde caster / rogue class chains
-- Rogue, priest, mage and warlock chains that belong in the shared Horde brackets. Routes_Tauren.lua
-- already injects the warrior, hunter, shaman and druid ones; these are added once, guarded so the
-- Orc route file can carry the same block. Each list is inserted before the bracket's closing {lv=} gate.
if not ns.HORDE_CASTER_CLASS_STEPS_DONE then
  ns.HORDE_CASTER_CLASS_STEPS_DONE = true
  local CASTER_CLASS_STEPS = {
    -- 12-20 The Barrens (Tauren t3)
    t3 = {
      {q="Zando'zan", cls="ROGUE", g={43,54,"Any Orgrimmar rogue trainer, Cleft of Shadow (verify)",ORG}, r={43,52,"Zando'zan, Cleft of Shadow (verify)",ORG}},
      {q="Wrenix of Ratchet", cls="ROGUE", g={43,52,"Zando'zan, Cleft of Shadow (verify)",ORG}, r={63,37,"Wrenix the Wretched, Ratchet"}},
      {q="Plundering the Plunderers", cls="ROGUE", g={63,37,"Wrenix the Wretched, Ratchet"}, o={68,51,"Take the E.C.A.C. and Thieves' Tools from Wrenix's Gizmotronic Apparatus, board the Tide Razor south of Ratchet, pick the boxes on deck two, take the Southsea Treasure (verify)"}, r={63,37,"Wrenix the Wretched: 10 Thistle Tea"}},
      {q="Investigate the Alchemist Shop", opt=true, cls="MAGE", g={84,18,"Anastasia Hartwell, Magic Quarter, Undercity",UC}, o={84,18,"Reveal and capture the Rift Spawn with the containment coffers in the alchemist shop (verify)",UC}, r={84,18,"Anastasia Hartwell",UC}},
      {q="Gathering Materials", opt=true, cls="MAGE", g={84,18,"Anastasia Hartwell, Undercity",UC}, o={84,18,"10 Linen Cloth, 6 Charged Rift Gems (verify source); turn in to the Undercity tailor named in the quest (verify)",UC}},
      {q="Spellfire Robes", opt=true, cls="MAGE", g={84,18,"Undercity tailor (verify)",UC}, r={84,18,"Spellfire Robes",UC}},
      {q="Rogues of the Shattered Hand", cls="ROGUE", g={43,54,"Any rogue trainer (verify whether this gates the chain in 1.15)",ORG}, r=SHENTHUL},
      {q="The Shattered Salute", id=2460, cls="ROGUE", g=SHENTHUL, o={43,54,"Watch Shenthul's salute, then /salute him (75 Lockpicking)",ORG}, r=SHENTHUL},
      {q="Deep Cover", cls="ROGUE", g=SHENTHUL, o={57,8,"Venture Co. tower above the Sludge Fen: fire the Flare Gun twice, /salute Taskmaster Fizzule"}, r={57,8,"Taskmaster Fizzule, Sludge Fen"}},
      {q="Mission: Possible But Not Probable", id=2478, cls="ROGUE", g={57,8,"Taskmaster Fizzule, Sludge Fen"}, o={57,8,"2 each Mutated Venture Co. Drone, Lookout, Patroller; pickpocket Silixiz's Tower Key; Gallywix's Head from Grand Foreman Puzik Gallywix (23 elite); lockpick Gallywix's Lockbox for the Cache of Zanzil's Altered Mixture"}, r={43,54,"Shenthul: Poisons, Recipe: Thistle Tea (verify which turn-in grants Poisons)",ORG}},
      {q="Hinott's Assistance", p=1, opt=true, cls="ROGUE", g=SHENTHUL, r={62,20,"Serge Hinott, Tarren Mill, Hillsbrad",HILLS}},
      {q="Hinott's Assistance", p=2, opt=true, cls="ROGUE", g={62,20,"Serge Hinott, Tarren Mill",HILLS}, r=SHENTHUL},
      {q="Shadowguard", cls="PRIEST", g={36,88,"Zayus or Ur'kyo, Spirit Lodge, Valley of Spirits",ORG}, r={36,88,"Zayus: learn Shadowguard",ORG}},
      {q="Devourer of Souls", id=1716, cls="WARLOCK", g=GANRUL, r={44,54,"Cazul, the blind warlock, Cleft of Shadow (verify)",ORG}},
      {q="Blind Cazul", cls="WARLOCK", g={44,54,"Cazul, Cleft of Shadow (verify)",ORG}, r={37,60,"Zankaja, between the Valley of Wisdom and the Valley of Strength",ORG}},
      {q="News of Dogran", p=1, cls="WARLOCK", g={37,60,"Zankaja, Orgrimmar",ORG}, r={73,95,"Ken'zigla, Malaka'jin, Stonetalon",STM}},
      {q="News of Dogran", p=2, cls="WARLOCK", g={73,95,"Ken'zigla, Malaka'jin",STM}, r={44,59,"Grunt Logmar, Camp Taurajo"}},
      {q="Ken'zigla's Draught", cls="WARLOCK", g={44,59,"Grunt Logmar, Camp Taurajo"}, r={73,95,"Ken'zigla, Malaka'jin (verify)",STM}},
      {q="Dogran's Captivity", cls="WARLOCK", g={73,95,"Ken'zigla, Malaka'jin (verify)",STM}, o={43,49,"Deliver the draught to Grunt Dogran, held in the two-hut quilboar camp north of Camp Taurajo; heavily guarded"}, r={43,49,"Grunt Dogran"}},
      {q="Love's Gift", cls="WARLOCK", g={43,49,"Grunt Dogran (verify)"}, r={37,60,"Zankaja, Orgrimmar",ORG}},
      {q="The Binding", p=2, cls="WARLOCK", g={44,54,"Cazul, Cleft of Shadow (verify)",ORG}, o={44,54,"Summon and defeat the Succubus at the circle",ORG}, r={44,54,"Cazul: Summon Succubus",ORG}},
    },
    -- 20-25 Stonetalon, Ashenvale (Tauren t4)
    t4 = {
      {q="The Orb of Soran'ruk", id=1740, opt=true, cls="WARLOCK", g={49,57,"Doan Karhan, southern Barrens south of Camp Taurajo (verify)",BAR}, o={14,14,"3 Soran'ruk Fragments from Twilight Acolytes in Blackfathom Deeps; 1 Large Soran'ruk Fragment from a Shadowfang Keep wizard",ASH}, r={49,57,"Doan Karhan: Orb or Staff of Soran'ruk",BAR}},
    },
    -- 25-30 Thousand Needles (Tauren t5). The Felhunter chain lives in shared b7 (Routes_Forsaken_Class.lua).
    t5 = {
      {q="Speak with Deino", cls="MAGE", g={39,86,"Any Orgrimmar mage trainer, Darkbriar Lodge",ORG}, r=DEINO},
      {q="Waters of Xavian", id=1944, cls="MAGE", g=DEINO, o={76,41,"Xavian Water Sample from the waterfall at Xavian, east Ashenvale, north of Splintertree",ASH}, r=DEINO},
      {q="Laughing Sisters", cls="MAGE", g=DEINO, o={58,55,"The dryads at the Laughing Sisters, Ashenvale (verify)",ASH}, r=DEINO},
      {q="Nether-lace Garment", cls="MAGE", g=DEINO, r={39,86,"Deino: Nether-lace Garment",ORG}},
    },
    -- 35-40 Arathi, Stranglethorn, Dustwallow (shared b8)
    b8 = {
      {q="Journey to the Marsh", cls="MAGE", g={39,86,"Any Orgrimmar mage trainer, Darkbriar Lodge",ORG}, r={43,57,"Tabetha, farmhouse in the middle of Dustwallow Marsh",DUSTW}},
      {q="Hidden Secrets", cls="MAGE", g={43,57,"Tabetha, Dustwallow",DUSTW}, r={77,76,"Magus Tirth, Shimmering Flats raceway, Thousand Needles",TN}},
      {q="Get the Scoop", cls="MAGE", g={77,76,"Magus Tirth, Shimmering Flats",TN}, o={77,76,"/beckon Plucky Johnson, the chicken by the raceway",TN}, r={77,76,"Magus Tirth",TN}},
      {q="Rituals of Power", cls="MAGE", g={77,76,"Magus Tirth, Shimmering Flats",TN}, o={84,31,"The book on the Athenaeum shelf in the Scarlet Monastery Library (verify)",TIRIS}, r={43,57,"Tabetha, Dustwallow",DUSTW}},
      {q="Items of Power", cls="MAGE", g={43,57,"Tabetha, Dustwallow",DUSTW}, o={51,48,"1 Jade (auction house) and 1 Bolt Charged Bramble: use 10 Witherbark Totem Sticks (Witherbark trolls, 65,65) at the Circle of Outer Binding in a thunderstorm",ARATHI}, r={43,57,"Tabetha",DUSTW}},
      {q="Mage's Wand", cls="MAGE", g={43,57,"Tabetha, Dustwallow",DUSTW}, r={43,57,"Tabetha: Icefury, Ragefire or Nether Force Wand",DUSTW}},
      {q="Summon Felsteed", p=1, cls="WARLOCK", g=GANRUL, r=STRAHAD},
      {q="Summon Felsteed", p=2, cls="WARLOCK", g=STRAHAD, o={63,37,"Take part in the ritual with Strahad's acolytes",BAR}, r={63,37,"Strahad Farsan: Summon Felsteed",BAR}},
    },
    -- 50-55 Un'Goro, Felwood, Steppes, Azshara (shared b11)
    b11 = {
      {q="A Simple Request", cls="ROGUE", g={43,54,"Any rogue trainer, Cleft of Shadow",ORG}, r={76,43,"Lord Jorach Ravenholdt, Ravenholdt Manor, north of Durnholde, Hillsbrad (verify)",HILLS}},
      {q="Sealed Azure Bag", cls="ROGUE", g={76,43,"Lord Jorach Ravenholdt",HILLS}, o={45,21,"Pickpocket Timbermaw Shamans in northern Azshara for the bag; the elf at 28,50 teleports you up to Archmage Xylem",AZSH}, r={29,40,"Archmage Xylem, his tower above Azshara (teleporter at 29,40)",AZSH}},
      {q="Encoded Fragments", cls="ROGUE", g={29,40,"Archmage Xylem, Azshara",AZSH}, o={64,25,"10 Encoded Fragments from Forest Oozes",AZSH}, r={29,40,"Archmage Xylem",AZSH}},
      {q="The Azure Key", cls="ROGUE", g={29,40,"Archmage Xylem, Azshara",AZSH}, o={70,54,"Azure Key from Morphaz in the Temple of Atal'Hakkar",SWAMP}, r={76,43,"Lord Jorach Ravenholdt: Whisperwalk Boots, Duskbat Drape or Ebon Mask",HILLS}},
      {q="Cenarion Aid", cls="PRIEST", g=URKYO, r={42,43,"Ogtinc, cliffs above the Shattered Strand, Azshara",AZSH}},
      {q="Of Coursers We Know", cls="PRIEST", g={42,43,"Ogtinc, Azshara",AZSH}, o={52,27,"4 Healthy Courser Glands from Mosshoof Coursers, away from the naga",AZSH}, r={42,43,"Ogtinc",AZSH}},
      {q="The Ichor of Undeath", cls="PRIEST", g={42,43,"Ogtinc, Azshara",AZSH}, o={50,50,"1 Ichor of Undeath, a rare drop from any undead at level (Western Plaguelands or Scholomance)",1422}, r={42,43,"Ogtinc",AZSH}},
      {q="Blood of Morphaz", cls="PRIEST", g={42,43,"Ogtinc, Azshara",AZSH}, o={70,54,"Kill Morphaz in the Temple of Atal'Hakkar; loot the Blood of Morphaz",SWAMP}, r={42,43,"Ogtinc: Blessed Prayer Beads, Woestave or Circle of Hope",AZSH}},
      {q="Magecraft", cls="MAGE", g={39,86,"Any Orgrimmar mage trainer, Darkbriar Lodge",ORG}, r={29,40,"Archmage Xylem, his tower above Azshara (teleporter elf at 29,40)",AZSH}},
      {q="Magic Dust", cls="MAGE", g={29,40,"Archmage Xylem, Azshara",AZSH}, o={57,28,"Blood Elf mobs around the ruins for the dust",AZSH}, r={29,40,"Archmage Xylem",AZSH}},
      {q="The Siren's Coral", cls="MAGE", g={29,40,"Archmage Xylem, Azshara",AZSH}, o={44,54,"Naga at the ruins on the south coast",AZSH}, r={29,40,"Archmage Xylem",AZSH}},
      {q="Destroy Morphaz", cls="MAGE", g={29,40,"Archmage Xylem, Azshara",AZSH}, o={70,54,"Arcane Shard from Morphaz in the Temple of Atal'Hakkar",SWAMP}, r={29,40,"Archmage Xylem: Fire Ruby, Arcane Crystal Pendant or Glacial Spike",AZSH}},
      {q="An Imp's Request", id=8419, cls="WARLOCK", g=GANRUL, o={43,44,"Bring 1 Felcloth to Impsy, just north of Bloodvenom Falls (verify)",FELW}, r={43,44,"Impsy, Felwood (verify)",FELW}},
      {q="Hot and Itchy", cls="WARLOCK", g={43,44,"Impsy, Felwood (verify)",FELW}, o={43,44,"Follow the quest text (objective unconfirmed; verify)",FELW}, r={43,44,"Impsy",FELW}},
      {q="The Wrong Stuff", cls="WARLOCK", g={43,44,"Impsy, Felwood (verify)",FELW}, o={48,30,"10 Rotting Wood from Irontree Wanderers, Stompers and Withered Protectors; 4 Bloodvenom Essence from Tainted Oozes",FELW}, r={43,44,"Impsy",FELW}},
      {q="Trolls of a Feather", cls="WARLOCK", g={43,44,"Impsy, Felwood (verify)",FELW}, o={70,54,"Temple of Atal'Hakkar: Gasher, Loro, Hukku, Zul'Lor, Mijan, Zolo for 2 Amber, 2 Blue, 2 Green Voodoo Feathers",SWAMP}, r={43,44,"Impsy: Soul Harvester, Abyss Shard or Robe of Servitude",FELW}},
    },
    -- 55-60 Plaguelands, Winterspring, Silithus (shared b12)
    b12 = {
      {man="Level 60: Dreadsteed. Mor'zul Bloodbringer on the hill across from the Altar of Storms, north-west Burning Steppes: the Rage of Blood and Lord Banehollow chains, Gorzeeki's Bell, Wheel and Candle (150 gold or more), Imp Delivery into Scholomance, then Dreadsteed of Xoroth in Dire Maul West (Immol'thar, the ritual, the Dreadsteed Spirit).", cls="WARLOCK", x=12, y=31, map=STEPPES},
      {man="Level 60: Tome of Polymorph: Pig. Archmage Xylem's Warlord Krellian then Fragmented Magic: cast Polymorph 50 times on the Spitelash naga in Azshara.", cls="MAGE", x=29, y=40, map=AZSH},
    },
  }
  local function inject(list, b)
    local extra = list[b.id]
    if not extra then return end
    -- insert before the closing level gate so the class chain sits inside the bracket
    local at = #b.steps
    for i = #b.steps, 1, -1 do if b.steps[i].lv then at = i - 1; break end end
    for j, s in ipairs(extra) do table.insert(b.steps, at + j, s) end
  end
  for _, b in ipairs(ns.TAUREN_BRACKETS) do inject(CASTER_CLASS_STEPS, b) end
  for _, b in ipairs(ns.BRACKETS) do inject(CASTER_CLASS_STEPS, b) end
end

-- Troll route = the two brackets above, the Tauren file's Barrens / Stonetalon / Needles brackets
-- (t3, t4, t5: the Orc/Troll entry is handled by tr2's Far Watch steps), then the shared Horde
-- brackets from 30-35 on.
local TROLL_ROUTE_BRACKETS = {}
for _, b in ipairs(ns.TROLL_BRACKETS) do table.insert(TROLL_ROUTE_BRACKETS, b) end
for i = 3, 5 do table.insert(TROLL_ROUTE_BRACKETS, ns.TAUREN_BRACKETS[i]) end
for i = 7, #ns.BRACKETS do table.insert(TROLL_ROUTE_BRACKETS, ns.BRACKETS[i]) end

table.insert(ns.ROUTES, {
  id = "troll", name = "The Loa's Path", faction = "Horde",
  races = { Troll = true }, raceOnly = 2,
  brackets = TROLL_ROUTE_BRACKETS,
})
