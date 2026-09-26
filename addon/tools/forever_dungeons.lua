-- WoW Forever's new dungeons and raids, hand-curated for the Dungeon Journal from
-- docs/research/forever-dungeons.md (Wowhead Forever database + beta guides, 2026-09-26).
-- Item and NPC ids are datamined; boss -> loot and boss order come from beta guides.
-- 32 of the item ids were also checked against the beta client's own hotfix item data (all match).
-- Merged into Evergreen/Modules/Journal_Data.lua by build_journal.lua (run rebuild.sh).
-- Schema: same as a generated instance, plus note = shown in the journal header.
-- uiMaps: Dun Morogh 1426, Ironforge 1455, Tirisfal 1420, Silverpine 1421, Undercity 1458,
-- Stormwind 1453, Hillsbrad 1424, Wetlands 1437, Alterac 1416, Stranglethorn 1434,
-- Dustwallow 1445, Azshara 1447, Un'Goro 1449.

local function items(...) local t = {} for _, id in ipairs({ ... }) do t[#t + 1] = { id } end return t end

return {
  {
    key = "HallOfThanes", name = "The Hall of Thanes", area = 16919, levels = { 13, 15, 18 },
    entrances = { { 1455, 32.5, 46.0 } },
    note = "Beneath the High Seat of Ironforge: go through the door to Old Ironforge on the left inside the High Seat and follow the path down to the portal. Entrance spot approximate.",
    bosses = {
      { name = "Faldrim Anvilmar", npc = 261306, desc = "Undead; patrols Anvilmar's Rest. Mind Blast, and a 10-minute Curse of Anvilmar on the tank.",
        items = items(271097, 270227, 271096) },
      { name = "Magmatus", npc = 261316, desc = "Fire elemental with a Dark Iron Summoner. Pulsing fire nova; Combust on a random player.",
        items = items(270230, 270231, 271095) },
      { name = "Plunder", npc = 261311, desc = "Golem patrolling a hallway. Knockback.",
        items = items(270228, 271098, 270229) },
      { name = "Durgen Dirgehammer", npc = 261319, desc = "Final boss, with two Lesser Stone Golems and Dark Iron Looters. AoE fear and Rend.",
        items = items(270256, 270260, 270261) },
    },
    quests = {
      { id = 96391, name = "Underground Map", lvl = 15, req = 9, fac = "A", g = { 0, 0, 0, "Dark Iron Map (item drop)" }, r = { 1426, 64.8, 58.4, "Earthseer Farsen" },
        txt = "Deliver the Dark Iron Map. Leads to Old Ironforge Incursion." },
      { id = 96393, name = "Old Ironforge Incursion", lvl = 16, req = 9, fac = "A", pre = { 96391 },
        g = { 1426, 64.8, 58.4, "Earthseer Farsen" }, r = { 1455, 39.4, 55.4, "King Magni Bronzebeard" },
        txt = "Bring Durgen Dirgehammer's Head.", rew = { 279894, 279895, 279896 } },
      { id = 96394, name = "The Restless Dead", lvl = 15, req = 10, fac = "A", g = { 1455, 32.4, 47.8, "Afadra Dunwall" }, r = { 1455, 32.4, 47.8, "Afadra Dunwall" },
        txt = "Kill 15 Enraged Apparitions and 10 Tormented Souls.", rew = { 279897, 280095 } },
      { id = 96395, name = "An Ancient Grudge", lvl = 15, req = 10, g = { 0, 0, 0, "Ghostly Attendant (inside, Anvilmar's Rest)" }, r = { 0, 0, 0, "Ghostly Attendant" },
        txt = "Kill Faldrim Anvilmar.", rew = { 279899, 279900 } },
      { id = 96403, name = "Important Heirlooms", lvl = 15, req = 10, fac = "A", g = { 1455, 31.4, 45.4, "Thom Filch" }, r = { 1455, 31.4, 45.4, "Thom Filch" },
        txt = "Collect 8 Dwarven Heirlooms.", rew = { 279898, 280096 } },
      { id = 98423, name = "The Treaty of Understanding", lvl = 16, req = 9, fac = "A", g = { 0, 0, 0, "Treaty of Understanding (item, vault in the Reliquary of Kings)" }, r = { 1455, 39.4, 55.4, "King Magni Bronzebeard" },
        txt = "Deliver the treaty found in the dungeon." },
    },
  },
  {
    key = "RuinsOfLordaeron", name = "Ruins of Lordaeron", area = 16611, levels = { 15, 18, 20 },
    entrances = { { 1420, 61.2, 67.4 } },
    note = "The ruined city above Undercity; the portal and meeting stone are in the east courtyard. Entrance spot unverified. Boss order is not fixed (open courtyard); Viktor the Vile is an event (light the kindling at the campfire in the south-west house), the Lordaeron Captain a rare.",
    bosses = {
      { name = "Witherfang", npc = 250483, desc = "Spider. Holds the Highly Toxic Strain for The New Plague.", items = items(271201, 271202, 271203) },
      { name = "The Baron", npc = 250660, desc = "Abomination. Drops Head of the Baron / Abominable Head for quests.", items = items(271204, 271205, 271206) },
      { name = "The Abandoned", npc = 250631, desc = "Spirit; appears once the courtyard is cleared, then waves.", items = items(271207, 271208, 271216) },
      { name = "Bjork", npc = 256097, desc = "Heavy tank damage and a knockback.", items = items(271209, 271210, 271217) },
      { name = "Viktor the Vile", npc = 256035, desc = "Event boss: click the kindling at the campfire, survive the waves.", items = items(271211, 271212, 271218) },
      { name = "Rath'mael", npc = 250657, desc = "Final boss: necromancer at the unholy altar at the end of the corridor. Frost and necromancy.", items = items(271213, 271214, 271215) },
      { name = "Lordaeron Captain", npc = 255699, rare = true, desc = "Rare spawn, not every run. Loot from two beta sites.", items = items(6641, 6642) },
    },
    quests = {
      { id = 92401, name = "A Frightened Request", lvl = 22, req = 15, fac = "H", g = { 1421, 44.4, 43.0, "Tabitha Heartweaver" }, r = { 1421, 44.4, 43.0, "Tabitha Heartweaver" },
        txt = "Find out what happened to Edward Heartweaver in the Ruins of Lordaeron.", rew = { 251485, 251486 } },
      { id = 92422, name = "The Wrath of Rath'mael", lvl = 22, req = 15, fac = "H", g = { 1420, 65.2, 60.2, "Deathguard Kristof" }, r = { 1420, 65.2, 60.2, "Deathguard Kristof" },
        txt = "Kill Rath'mael.", rew = { 251533, 251534 } },
      { id = 92421, name = "Light's Justice", lvl = 22, req = 15, fac = "H", g = { 1458, 57.4, 90.4, "Morbin Lightbane" }, r = { 1458, 57.4, 90.4, "Morbin Lightbane" },
        txt = "Collect 25 Intact Limbs.", rew = { 279874, 279875 } },
      { id = 95216, name = "The New Plague", lvl = 22, req = 16, fac = "H", g = { 1458, 46.4, 71.4, "Theodore Griffs" }, r = { 1458, 46.4, 71.4, "Theodore Griffs" },
        txt = "Bring the Highly Toxic Strain from Witherfang.", rew = { 279876, 279877 } },
      { id = 97288, name = "Unending Torment", lvl = 21, req = 16, fac = "H", g = { 0, 0, 0, "Abominable Head (drop)" }, r = { 1458, 48.4, 69.4, "Master Apothecary Faranell" },
        txt = "Deliver the Abominable Head. The chain continues (97289, 97291, 97292): the Head of the Baron to Othmar's body, herbs in Undercity, the Hissing Serum." },
      { id = 95204, name = "Crest of Lordaeron", lvl = 22, req = 16, fac = "H", g = { 0, 0, 0, "Crest of Lordaeron (drop)" }, r = { 1458, 73.4, 32.4, "Oran Snakewrithe" },
        txt = "Deliver the crest.", rew = { 280567 } },
      { id = 95250, name = "Abominable Creatures", lvl = 21, req = 16, fac = "A", g = { 1424, 50.8, 59.2, "Captain Truman (unverified)" }, r = { 1424, 50.8, 59.2, "Captain Truman (unverified)" },
        txt = "Bring the Head of the Baron.", rew = { 279864, 279865, 279867 } },
      { id = 95195, name = "Bloodied Insignia", lvl = 22, req = 16, fac = "A", g = { 1453, 63.4, 75.8, "General Marcus Jonathan" }, r = { 1453, 63.4, 75.8, "General Marcus Jonathan" },
        txt = "Collect 10 Bloodied Insignia.", rew = { 279868, 279869 } },
      { id = 95189, name = "Crest of Lordaeron", lvl = 22, req = 16, fac = "A", g = { 0, 0, 0, "Crest of Lordaeron (drop)" }, r = { 1453, 62.4, 5.8, "Lady Dena Kennedy" },
        txt = "Deliver the crest.", rew = { 280567 } },
      { id = 92415, name = "Remember That I Love You", lvl = 22, req = 15, fac = "A", g = { 0, 0, 0, "Blood-Stained Letter (drop)" }, r = { 1453, 47.4, 38.6, "Orphan Matron Nightingale" },
        txt = "Deliver the letter." },
    },
  },
  {
    key = "ExcavationSiteWetlands", name = "Excavation Site: Wetlands", area = 16732, levels = { 24, 27, 29 },
    note = "Above Whelgar's Excavation Site, Wetlands; entrance coordinates not published yet. Opens in the beta with the level-30 phase (about Oct 1). Loot and quests not known yet; boss order unverified.",
    bosses = {
      { name = "Saltspine", npc = 260322, desc = "Crocolisk.", items = {} },
      { name = "Shadetooth", npc = 260325, desc = "Raptor leader.", items = {} },
      { name = "Highland Horror", npc = 260808, desc = "Elemental.", items = {} },
      { name = "Relic Guardian", npc = 260326, desc = "Construct.", items = {} },
    },
  },
  {
    key = "CityOfDalaran", name = "City of Dalaran", area = 16560, levels = { 28, 30, 33 },
    note = "The old Dalaran dome in Alterac Mountains, barrier down; the sewers lead to the underbelly (Dalaran Sewer Key). Sources disagree on 3 or 9 bosses; the list below is the longer one. Loot not known yet.",
    bosses = {
      { name = "Arcane Anomaly", npc = 245999, items = {} },
      { name = "Fel Ancient", npc = 246003, items = {} },
      { name = "Mana Devourer", npc = 246008, items = {} },
      { name = "Unstable Sentinel", npc = 246017, items = {} },
      { name = "Atrexis the Grave Knight", npc = 247126, items = {} },
      { name = "Mana Wraith", npc = 246931, items = {} },
      { name = "Lyn the Ignored", npc = 247032, rare = true, items = {} },
      { name = "Shade of the Archmage", npc = 246020, desc = "Probably the final boss (kill achievement).", items = {} },
    },
  },
  {
    key = "DrownedCity", name = "The Drowned City", area = 0, levels = { 35, 37, 40 },
    note = "An ancient troll ruin off the Stranglethorn coast. Not in the beta yet; bosses from the BlizzCon demo build.",
    bosses = {
      { name = "Zul'Alai", npc = 270882, items = {} },
      { name = "Var'Taka", npc = 270883, items = {} },
      { name = "Captain Dreadrise", npc = 270884, items = {} },
      { name = "Deathless Marrow", npc = 270885, items = {} },
      { name = "Gill", npc = 270888, items = {} },
      { name = "Min'loth the Serpent", npc = 270886, items = {} },
    },
  },
  {
    key = "KroldokStronghold", name = "Krol'dok Stronghold", area = 0, levels = { 40, 42, 45 },
    note = "In the new Riverglades zone. Not in the beta yet; bosses and loot unknown (a Krol'dok Battlegear set exists).",
    bosses = {},
  },
  {
    key = "AlcazPrison", name = "Alcaz Prison", area = 0, levels = { 48, 50, 53 },
    note = "Alcaz Island, far north-east Dustwallow Marsh. Not in the beta yet.",
    bosses = { { name = "Blazeroar", items = {} } },
  },
  {
    key = "BlackmawHold", name = "Blackmaw Hold", area = 0, levels = { 55, 58, 60 },
    note = "Furbolg city behind the gates in northern Azshara; its tunnels are said to lead toward the Barrow Deeps. Not in the beta yet.",
    bosses = {},
  },
  {
    key = "ShapersTerrace", name = "The Shaper's Terrace", area = 0, levels = { 58, 59, 60 },
    note = "Un'Goro Crater. Not in the beta yet; boss order unknown.",
    bosses = { { name = "Nanaya", items = {} }, { name = "Cinder", items = {} }, { name = "Bolt", items = {} }, { name = "Snowtalon", items = {} } },
  },
  {
    key = "BarrowDeeps", name = "The Barrow Deeps", area = 0, raid = true, levels = { 60, 60, 60 },
    note = "10-player raid, a Night Elf prison with three entrances (one in Mount Hyjal). Opens Dec 9, 2026, no attunement. Encounter list from the achievement, not kill order.",
    bosses = {
      { name = "Deepscar Matriarch", items = {} }, { name = "Khalith the Dreadspinner", items = {} }, { name = "Amethrax", items = {} },
      { name = "Ravus and Darlissa", items = {} }, { name = "Elder Tangleclaw", items = {} }, { name = "Well of Sorrow", items = {} },
      { name = "Del'lynar Songwood", items = {} }, { name = "Sonya Darkhallow", desc = "Probably the final boss (kill achievement).", items = {} },
    },
  },
  {
    key = "HyjalSummit", name = "Hyjal Summit", area = 0, raid = true, levels = { 60, 60, 60 },
    note = "20-player raid in the new Mount Hyjal zone. Opens Dec 9, 2026, no attunement. Encounter list from the achievement, not kill order.",
    bosses = {
      { name = "Bandalar", items = {} }, { name = "Time-Lost Battalion", items = {} }, { name = "Old Gloomlurker", items = {} },
      { name = "Kathris the Haunted", items = {} }, { name = "Elder Minderel", items = {} }, { name = "Council of Thorns", items = {} },
      { name = "The Wild King", desc = "Has a kill achievement.", items = {} }, { name = "Ancient of Decay", items = {} },
      { name = "Sylvestris Dusksong", items = {} }, { name = "Gharalis the Abyssal", items = {} }, { name = "Anara Chillwind", items = {} },
      { name = "Tracker Stillwind", items = {} }, { name = "Nythus the Dreambound", items = {} },
    },
  },
}
