-- Evergreen: Forsaken class-quest steps for "The Forsaken Road". Loaded after Data.lua and
-- Routes_Tauren.lua; injects cls=-tagged steps into ns.BRACKETS (b1..b12) before each bracket's
-- closing {lv=...} gate, exactly the way Routes_Tauren.lua's SHARED_CLASS_STEPS block does.
-- Routes_Tauren.lua already injects the Horde-wide warrior Whirlwind chain (b7, b8) and the warrior,
-- hunter, shaman and druid Sunken Temple chains (b11); nothing below duplicates those.
-- Step format is documented at the top of Data.lua. Coordinates marked (verify) are approximate.
local ADDON, ns = ...

ns.MAP_NAMES[1416] = ns.MAP_NAMES[1416] or "Alterac Mountains"
ns.MAP_NAMES[1437] = ns.MAP_NAMES[1437] or "Wetlands"

local TIR, SIL, BAR, DUR, UC, ORG = 1420, 1421, 1413, 1411, 1458, 1454
local HIL, ASH, TN, STV, ARA, DUS = 1424, 1440, 1441, 1434, 1417, 1445
local WET, ALT, FEL, AZS, SOS, BL, BS, WPL = 1437, 1416, 1448, 1447, 1435, 1419, 1428, 1422

-- Undercity NPCs (quarter positions on the Undercity map; the Magic Quarter value matches Data.lua)
local UC_CARENDIN  = {84,18,"Carendin Halgar, Magic Quarter, Undercity",UC}
local UC_ANASTASIA = {84,18,"Anastasia Hartwell, Magic Quarter, Undercity (verify)",UC}
local UC_JOSEF     = {84,18,"Josef Gregorian, tailor, Magic Quarter, Undercity (verify)",UC}
local UC_MENNET    = {75,57,"Mennet Carkad, Rogues' Quarter, Undercity (verify)",UC}
local UC_ANDRON    = {63,47,"Andron Gant, Undercity (verify)",UC}
local UC_WAR       = {33,28,"War Quarter, Undercity (verify)",UC}
local UC_WARRIOR   = {33,28,"Any warrior trainer, War Quarter, Undercity (verify)",UC}
local UC_PRIEST    = {33,28,"Any priest trainer, War Quarter, Undercity (verify)",UC}
local UC_ROGUE     = {75,57,"Any rogue trainer, Rogues' Quarter, Undercity (verify)",UC}
local UC_MAGE      = {84,18,"Any mage trainer, Magic Quarter, Undercity",UC}
local UC_WARLOCK   = {84,18,"Any warlock trainer, Magic Quarter, Undercity",UC}
-- Field NPCs shared by several chains
local STRAHAD  = {62,35,"Strahad Farsan, hill above Ratchet (verify)",BAR}
local SHENTHUL = {48,46,"Shenthul, Cleft of Shadow, Orgrimmar (verify)",ORG}
local DEINO    = {39,86,"Deino, Valley of Spirits, Orgrimmar (verify)",ORG}
local TABETHA  = {43,57,"Tabetha, Dustwallow Marsh",DUS}
local TIRTH    = {77,76,"Magus Tirth, Shimmering Flats, Thousand Needles",TN}
local BATHRAH  = {80,67,"Bath'rah the Windwatcher, ruins north-east of Tarren Mill, Alterac",ALT}
local KLANNOC  = {68,48,"Klannoc Macleod, Fray Island south of Ratchet",BAR}
local THUNGRIM = {57,30,"Thun'grim Firegaze, top of Thorn Hill (path up from 55,32)",BAR}
local RUGA     = {44,59,"Ruga Ragetotem, Camp Taurajo (verify)",BAR}
local OGTINC   = {42,43,"Ogtinc, cliffs above the Ruins of Eldarath, Azshara",AZS}
local XYLEM    = {28,50,"Archmage Xylem's tower; the elf at 28,50 teleports you up (verify)",AZS}
local JORACH   = {86,79,"Lord Jorach Ravenholdt, Ravenholdt Manor, hills north of Durnholde, Alterac (verify)",ALT}
local IMPSY    = {40,44,"Impsy, just north of Bloodvenom Falls, Felwood (verify)",FEL}
local MORPHAZ  = {70,54,"Morphaz in the Temple of Atal'Hakkar",SOS}

local FORSAKEN_CLASS_STEPS = {
  -- ============================================================ 1-6 Deathknell
  b1 = {
    {q="Piercing the Veil", cls="WARLOCK", g={31,66,"Maximillion, Deathknell chapel"}, o={34,62,"Tainted Scroll from the Rattlecage Skeletons in the ruined houses (verify)"}, r={31,66,"Maximillion: Summon Imp"}},
    {q="In Favor of Darkness", cls="PRIEST", g={31,66,"Dark Cleric Duesten, Deathknell chapel (verify)"}, r={61,52,"Dark Cleric Beryl, Brill (verify)"}},
  },
  -- ============================================================ 6-12 Brill
  b2 = {
    {q="Veteran Uzzek", cls="WARRIOR", g={60,52,"Deathguard Dillinger, Brill gate (warrior trainer)"}, r={62,31,"Uzzek, under a tree south-west of Far Watch Post (verify); the route reaches him at 17",BAR}},
    {q="Mennet Carkad", cls="ROGUE", g={31,66,"David Trias, Deathknell (or Marion Call, Brill)"}, r=UC_MENNET},
    {q="The Deathstalkers", p=1, cls="ROGUE", g=UC_MENNET, r=UC_ANDRON},
    {q="Speak with Anastasia", cls="MAGE", g={31,66,"Isabella, Deathknell (or Cain Firesong, Brill) (verify)"}, r=UC_ANASTASIA},
    {q="The Balnir Farmstead", cls="MAGE", g=UC_ANASTASIA, o={75,60,"Balnir Snapdragons at Balnir Farmstead"}, r=UC_ANASTASIA},
    {q="Halgar's Summons", cls="WARLOCK", g={31,66,"Maximillion, Deathknell (or Rupert Boch, Brill)"}, r=UC_CARENDIN},
    {q="Creature of the Void", cls="WARLOCK", g=UC_CARENDIN, o={45,33,"Egalin's Grimoire from Gregor Agamand, Agamand Mills (verify)"}, r=UC_CARENDIN},
    {q="The Binding", p=1, cls="WARLOCK", g=UC_CARENDIN, o={84,18,"Summon and defeat the Voidwalker at Carendin's circle",UC}, r={84,18,"Carendin Halgar: Summon Voidwalker",UC}},
    {q="Touch of Weakness", cls="PRIEST", g={61,52,"Dark Cleric Beryl, Brill (any priest trainer)"}, r={61,52,"Any priest trainer: talk, learn"}},
  },
  -- ============================================================ 12-18 Silverpine
  b3 = {
    {q="The Deathstalkers", p=2, cls="ROGUE", g=UC_ANDRON, o={45,20,"Astor Hadren walks the road north of the Sepulcher (verify): hand him Andron's letter, kill him when he turns, loot his reply"}, r=UC_ANDRON},
    {q="The Deathstalkers", p=3, cls="ROGUE", g=UC_ANDRON, r=UC_MENNET},
    {q="The Deathstalkers", p=4, cls="ROGUE", g=UC_MENNET, r={75,57,"Mennet Carkad: Blade of Cunning",UC}},
    {q="Fenwick Thatros", cls="ROGUE", opt=true, g=UC_MENNET, r={32,66,"Fenwick Thatros, Deathknell (verify)",TIR}},
    {q="Tools of the Trade", cls="ROGUE", opt=true, g={32,66,"Fenwick Thatros (verify)",TIR}, o={38,45,"Lockpicking practice on the Silverpine coast (verify); the poison quest at 20 wants 75 Lockpicking"}, r={32,66,"Fenwick Thatros (verify)",TIR}},
    {q="Report to Anastasia", cls="MAGE", g={61,52,"Cain Firesong, Brill (any mage trainer) (verify)",TIR}, r=UC_ANASTASIA},
    {q="Investigate the Alchemist Shop", cls="MAGE", g=UC_ANASTASIA, o={84,18,"Reveal the Rift Spawn in the Undercity alchemist shop with the cantation, capture it in 3 containment coffers (verify)",UC}, r=UC_ANASTASIA},
    {q="Gathering Materials", cls="MAGE", g=UC_ANASTASIA, o={84,18,"10 Linen Cloth, 6 Charged Rift Gems from the crates the quest marks (verify)",UC}, r=UC_JOSEF},
    {q="Spellfire Robes", cls="MAGE", g=UC_JOSEF, r=UC_JOSEF},
  },
  -- ============================================================ 17-20 Barrens
  b4 = {
    {q="Path of Defense", cls="WARRIOR", g={62,31,"Uzzek, Far Watch Post (verify)"}, o={39,32,"5 Singed Scales from thunder lizards at Thunder Ridge, across the bridge into Durotar",DUR}, r={62,31,"Uzzek: Defensive Stance, Sunder Armor, Taunt"}},
    {q="Thun'grim Firegaze", cls="WARRIOR", g={62,31,"Uzzek"}, r=THUNGRIM},
    {q="Forged Steel", cls="WARRIOR", g=THUNGRIM, o={55,26,"Stolen Iron Chest by the broken wagon north-west, guarded by quilboar"}, r={57,30,"Thun'grim: pick a weapon"}},
    {q="Speak with Ruga", cls="WARRIOR", g={72,34,"Any capital warrior trainer (Valley of Honor, Orgrimmar) (verify)",ORG}, r=RUGA},
    {fp="Camp Taurajo", cls="WARRIOR", x=44, y=59},
    {q="Trial at the Field of Giants", cls="WARRIOR", g=RUGA, o={48,80,"5 Twitching Antennae from silithids in the Field of Giants; 30 minutes from the first drop"}, r={44,59,"Ruga: Ruga's Bulwark"}},
    {q="Speak with Thun'grim", cls="WARRIOR", g=RUGA, r=THUNGRIM},
  },
  -- ============================================================ 20-25 Hillsbrad
  b5 = {
    {q="Rogues of the Shattered Hand", cls="ROGUE", g=UC_ROGUE, r={48,46,"Shenthul, Cleft of Shadow, Orgrimmar: Poisons (verify)",ORG}},
    {q="The Shattered Salute", cls="ROGUE", g=SHENTHUL, o={48,46,"/salute Shenthul; needs 75 Lockpicking",ORG}, r=SHENTHUL},
    {q="Deep Cover", cls="ROGUE", g=SHENTHUL, o={57,9,"Fire the flare gun at the Sludge Fen, north Barrens; Taskmaster Fizzule appears",BAR}, r={57,8,"Taskmaster Fizzule, just north of the Sludge Fen (verify)",BAR}},
    {q="Mission: Possible But Not Probable", cls="ROGUE", g={57,8,"Taskmaster Fizzule (verify)",BAR}, o={57,9,"2 Mutated Venture Co. Drones, 2 Lookouts, 2 Patrollers; Gallywix's Head from the top of the tower; pickpocket Silixiz's Tower Key; loot the Cache of Zanzil's Altered Mixture",BAR}, r={48,46,"Shenthul: Recipe: Thistle Tea",ORG}},
    {q="Hinott's Assistance", p=1, cls="ROGUE", g=SHENTHUL, r={62,19,"Serge Hinott, Tarren Mill"}},
    {q="Hinott's Assistance", p=2, cls="ROGUE", opt=true, g={62,19,"Serge Hinott, Tarren Mill"}, r=SHENTHUL},
    {q="Carendin Summons", cls="WARLOCK", g=UC_WARLOCK, r=UC_CARENDIN},
    {q="Devourer of Souls", cls="WARLOCK", g=UC_CARENDIN, o={84,18,"Follow the quest text (verify)",UC}, r=UC_CARENDIN},
    {q="Hearts of the Pure", cls="WARLOCK", g=UC_CARENDIN, o={50,65,"Hearts from the Scarlet Crusade in Tirisfal (verify)",TIR}, r=UC_CARENDIN},
    {q="The Binding", p=2, cls="WARLOCK", g=UC_CARENDIN, o={84,18,"Summon and defeat the Succubus at Carendin's circle; let the Voidwalker hold it",UC}, r={84,18,"Carendin Halgar: Summon Succubus",UC}},
    {q="Devouring Plague", cls="PRIEST", g=UC_PRIEST, r={33,28,"Any priest trainer: talk, learn (verify)",UC}},
  },
  -- ============================================================ 25-30 Ashenvale -> Needles
  b6 = {
    {q="Speak with Deino", cls="MAGE", g=UC_MAGE, r=DEINO},
    {q="Waters of Xavian", cls="MAGE", g=DEINO, o={76,41,"Xavian Water Sample from the waterfall at Xavian, north of Splintertree; satyrs"}, r=DEINO},
    {q="Laughing Sisters", cls="MAGE", g=DEINO, o={58,55,"The dryads at the Laughing Sisters camp west of Splintertree (verify)"}, r=DEINO},
    {q="Nether-lace Garment", cls="MAGE", g=DEINO, r={39,86,"Deino: Nether-lace Garment",ORG}},
    {q="The Orb of Soran'ruk", cls="WARLOCK", g={49,57,"Doan Karhan, southern Barrens south of Camp Taurajo (verify)",BAR}, o={14,14,"3 Soran'ruk Fragments from Twilight Acolytes in Blackfathom Deeps; 1 Large Soran'ruk Fragment from Shadowfang Darksouls in Shadowfang Keep (Silverpine 45,68)"}, r={49,57,"Doan Karhan: Orb or Staff of Soran'ruk",BAR}},
    {q="Brutal Armor", cls="WARRIOR", opt=true, g=THUNGRIM, o={62,91,"15 Smoky Iron Ingots (Stonetalon kobolds), 10 Powdered Azurite (Azurelode miners, Hillsbrad, verify), 10 Iron Bars, 1 Vial of Phlogiston (Roogug, Razorfen Kraul)",1442}, r=THUNGRIM},
    {q="Brutal Hauberk", cls="WARRIOR", opt=true, g=THUNGRIM, r=THUNGRIM},
    {q="The Islander", cls="WARRIOR", g=UC_WARRIOR, r=KLANNOC},
    {q="The Affray", cls="WARRIOR", g=KLANNOC, o={68,48,"Step on the grate, kill the challenger waves, then Big Will (33)",BAR}, r={68,48,"Klannoc: Berserker Stance, Intercept",BAR}},
    {q="The Windwatcher", cls="WARRIOR", g=KLANNOC, r=BATHRAH},
  },
  -- ============================================================ 30-35 STV + Desolace
  b7 = {
    {q="Seeking Strahad", cls="WARLOCK", g=UC_WARLOCK, r=STRAHAD},
    {q="Tome of the Cabal", p=1, cls="WARLOCK", g=STRAHAD, o={44,37,"Tattered Manuscript from the cave north-west of Freewind Post (entrance 44,37); grab it before leaving the Needles",TN}, r=STRAHAD},
    {q="Tome of the Cabal", p=2, cls="WARLOCK", g=STRAHAD, o={45,45,"3 Rods of Channeling from Dragonmaw Bonewarders at the Angerfang Encampment; ride south over Thandol Span from Hammerfall at 35",WET}, r=STRAHAD},
    {q="Tome of the Cabal", p=3, cls="WARLOCK", g=STRAHAD, r={62,35,"Strahad reconstructs the tome (verify)",BAR}},
    {q="The Binding", p=3, cls="WARLOCK", g=STRAHAD, o={62,35,"Summon and defeat the Felhunter at Strahad's circle",BAR}, r={62,35,"Strahad Farsan: Summon Felhunter",BAR}},
  },
  -- ============================================================ 35-40 Arathi / STV / Dustwallow
  -- b8, b11 and b12 (Felsteed, the caster and rogue Sunken Temple chains, Dreadsteed) are shared with every
  -- Horde route and are injected once by Routes_Troll.lua.
}

for _, b in ipairs(ns.BRACKETS) do
  local extra = FORSAKEN_CLASS_STEPS[b.id]
  if extra then
    -- insert before the closing level gate so the class chain sits inside the bracket
    local at = #b.steps
    for i = #b.steps, 1, -1 do if b.steps[i].lv then at = i - 1; break end end
    for j, s in ipairs(extra) do table.insert(b.steps, at + j, s) end
  end
end
