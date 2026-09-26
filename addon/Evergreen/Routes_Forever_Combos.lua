-- Evergreen: class steps for WoW Forever's new race/class combos. Loaded after every Routes_*.lua.
--
-- Forever adds six combos: Human Hunter, Gnome Priest, Dwarf Shaman, Orc Mage, Troll Warlock and
-- Undead Paladin (Blizzard, "Create the Hero You Want to Be", Sep 2026; Night Elf Mage is NOT one).
-- Troll Warlock needs nothing here: Routes_Troll.lua already carries the Valley of Trials warlock
-- chain. Everything else is injected below into the brackets that already exist, by bracket id.
-- Steps in shared brackets carry race= as well as cls=, so only that race's version of the class
-- sees them (see ClassFits in Core.lua).
--
-- Research: docs/research/forever-new-combos.md and docs/research/forever-forsaken-paladin.md.
-- Beta cap is 30, so nothing past 30 is published. (verify) marks beta-report or guessed data.
local ADDON, ns = ...

local DUR, ORG = 1411, 1454
local TIR, SIL, UC, HIL = 1420, 1421, 1458, 1424
local DM, LM, IF = 1426, 1432, 1455
local ELW, SW, WF, RR, WET, ASH = 1429, 1453, 1436, 1433, 1437, 1440

-- ------------------------------------------------------------------ injection helper
local byId = {}
for _, r in ipairs(ns.ROUTES) do
  for _, b in ipairs(r.brackets) do byId[b.id] = byId[b.id] or b end
end

-- Insert steps into bracket `id`: at the start when afterLv is 0, right after its {lv=afterLv}
-- gate when given, otherwise
-- just before the bracket's closing level gate (the way Routes_Tauren.lua injects).
local function inject(id, steps, afterLv)
  local b = byId[id]
  if not b then return end
  local at
  if afterLv == 0 then
    at = 0
  elseif afterLv then
    for i, s in ipairs(b.steps) do if s.lv == afterLv then at = i; break end end
  end
  if not at then
    at = #b.steps
    for i = #b.steps, 1, -1 do if b.steps[i].lv then at = i - 1; break end end
  end
  for j, s in ipairs(steps) do table.insert(b.steps, at + j, s) end
end

-- ================================================================== Dwarf Shaman
-- Source: Warcraft Tavern "Dwarf Shaman Totem Quests" + ForeverWisp (beta player reports).
local TEO     = {29,66,"Teo Hammerstorm, shaman trainer inside Anvilmar",DM}
local BRUEGS  = {88,44,"Bruegs Kindleborn, mountain cave; path starts at 86.7,47.0 (sources differ: 86.7,47.0 vs 87.6,43.6, verify)",DM}
local BRALDIR = {32,66,"Braldir Ashmantle, Loch Modan",LM}
local NORRIC  = {42,19,"Norric Lochthane, north Loch Modan",LM}
local HERV    = {66,76,"Hervdana Saegrund, cave behind the waterfall",WET}

inject("d1", {
  {q="Call of Earth", p=1, cls="SHAMAN", g=TEO, o={27,80,"2 Iceclaw Bear Pendants from Frostmane Troll Whelps at the troll cave"}, r=TEO},
  {q="Call of Earth", p=2, cls="SHAMAN", g=TEO, o={25,62,"Path from 25.8,69.3 up to the Spirit Stone: drink the Earth Sapta, talk to the Minor Manifestation of Earth"}, r={25,62,"Minor Manifestation of Earth"}},
  {q="Call of Earth", p=3, cls="SHAMAN", g={25,62,"Minor Manifestation of Earth"}, r={29,66,"Teo Hammerstorm: Earth Totem, Stoneskin Totem"}},
}, 4)

inject("d2", {
  {q="Call of Fire", p=1, cls="SHAMAN", g=TEO, r=BRUEGS},
  {man="Shaman: the rest of Call of Fire is in Loch Modan. Keep the Torch of Dormant Flame; Braldir Ashmantle (32,66) takes it when you arrive.", cls="SHAMAN", x=88, y=44},
})

inject("d3", {
  {q="Call of Fire", p=2, cls="SHAMAN", g=BRUEGS, r=BRALDIR},
  {q="Call of Fire", p=3, cls="SHAMAN", g=BRALDIR, o={36,20,"Fire Tar from Tunnel Rat Geomancers in Silver Stream Mine (35.6,20.2); a Reagent Pouch from Stonesplinter Seers in Stonesplinter Valley (31,77)"}, r=BRALDIR},
  {q="Call of Fire", p=4, cls="SHAMAN", g=BRALDIR, o={32,65,"Fire Spirit Stone: drink the Fire Sapta, kill the Minor Manifestation of Fire, use the Brazier of Dormant Flame"}},
  {q="Call of Fire", p=5, cls="SHAMAN", g={32,65,"Brazier of Dormant Flame"}, r={88,44,"Bruegs Kindleborn: Fire Totem, Searing Totem (verify coords)",DM}},
})

-- Call of Water starts at 20 in Loch Modan and runs through the 20-25 bracket's zones.
inject("d3", {
  {q="Call of Water", p=1, cls="SHAMAN", g={0,0,"Your shaman trainer"}, r=NORRIC},
})
inject("a4", {
  {q="Call of Water", p=2, race="Dwarf", cls="SHAMAN", g=NORRIC, o={66,76,"Fill the Unfilled Brown Waterskin at the waterfall outside Hervdana's cave",WET}, r=HERV},
  {q="Call of Water", p=3, race="Dwarf", cls="SHAMAN", g=HERV, o={74,62,"Fill the Red Waterskin at Stonewatch Falls",RR}, r=HERV},
  {q="Call of Water", p=4, race="Dwarf", cls="SHAMAN", g=HERV, o={37,52,"Fill the Blue Waterskin at the lake by Astranaar",ASH}, r=HERV},
  {q="Call of Water", p=5, race="Dwarf", cls="SHAMAN", g=HERV, o={48,60,"Forgotten Shrine, Westfall: drink the Water Sapta, kill the Corrupt Minor Manifestation of Water, use the shrine; talk to the Minor Manifestation of Water that rises",WF}},
  {q="Call of Water", p=6, race="Dwarf", cls="SHAMAN", g={48,60,"Minor Manifestation of Water",WF}, r={42,19,"Norric Lochthane: Water Totem, Healing Stream Totem",LM}},
  {forever=true, race="Dwarf", cls="SHAMAN", t="Dwarf Shaman: the level-30 Call of Air has not been published yet (beta cap is 30). Ask your trainer at 30."},
})

-- ================================================================== Gnome Priest
-- Source: Wowhead Forever database (quests 94821-94826 Confounding Flash, 94818-94820
-- Contingency Plan). Levels from search snippets (verify). Mims' coordinates unpublished.
local MIMS = {24,5,"High Priestess Mims, Hall of Mysteries, Mystic Ward, Ironforge (verify spot)",IF}

inject("g2", {
  {q="Confounding Flash", race="Gnome", cls="PRIEST", g={0,0,"Your priest trainer (sends you to Ironforge)"}, r={24,5,"High Priestess Mims: Confounding Flash (confuse up to 5 enemies, 8 yd)",IF}},
})
inject("a4", {
  {q="Contingency Plan", race="Gnome", cls="PRIEST", g={0,0,"Your priest trainer"}, r={24,5,"High Priestess Mims: Contingency Plan (ward: absorb and heal-over-time below 35% health)",IF}},
})

-- ================================================================== Human Hunter
-- Nothing Human-specific is published. The Classic taming framework exists in Forever (Horde
-- "Taming the Beast" 6083 is in its database), so the steps below follow that shape. (verify all)
local SW_HUNT = {62,36,"Stormwind hunter trainers, Dwarven District (Ulfir Ironbeard, Einris Brightspear, Thorfin Stoneshield)",SW}

inject("h1", {
  {forever=true, race="Human", cls="HUNTER", t="Human Hunter (Forever): find your trainer in Northshire Abbey; the Goldshire trainers take over at 6. No Human hunter quest is published yet."},
})
inject("h2", {
  {q="Taming the Beast", p=1, race="Human", cls="HUNTER", g={0,0,"Your hunter trainer, Goldshire (verify)"}, o={0,0,"Use the Taming Rod on the beast the quest names (verify)"}},
  {q="Taming the Beast", p=2, race="Human", cls="HUNTER", g={0,0,"Your hunter trainer, Goldshire (verify)"}, o={0,0,"Second rod, second beast (verify)"}},
  {q="Taming the Beast", p=3, race="Human", cls="HUNTER", g={0,0,"Your hunter trainer, Goldshire (verify)"}, o={0,0,"Third rod, third beast (verify)"}},
  {q="Training the Beast", race="Human", cls="HUNTER", g={0,0,"Your hunter trainer (verify)"}, r=SW_HUNT},
  {man="Hunter: after Training the Beast you can tame any beast. Wolves train fine; a beta bug stops pets from the new zones learning skills.", race="Human", cls="HUNTER", x=62, y=36, map=SW},
}, 10)

-- ================================================================== Orc Mage
-- Nothing Orc-specific is published. The Valley of Trials mage trainer is Mai'ah (Classic's
-- troll trainer, verify); the level-10 chain is assumed to be the Troll one from Sen'jin.
inject("o1", {
  {forever=true, race="Orc", cls="MAGE", t="Orc Mage (Forever): your trainer is in the Den, Valley of Trials (Mai'ah, verify). No Orc mage quest is published; the Troll chain below is the best guess."},
})
inject("o2", {
  {q="Ju-Ju Heaps", race="Orc", cls="MAGE", opt=true, g={56,74,"Un'thuwa, Sen'jin Village mage trainer (verify Orcs get it)",DUR}, o={67,86,"Destroy 4 Ju-Ju Heaps among the huts on Echo Isle",DUR}, r={56,74,"Un'thuwa: Ley Orb or Ley Staff",DUR}},
  {man="Mage: past 10 your trainers are in Orgrimmar, Darkbriar Lodge in the Valley of Spirits.", race="Orc", cls="MAGE", x=39, y=86, map=ORG},
})

-- ================================================================== Undead (Forsaken) Paladin
-- Source: Wowhead Forever database (beta client data); quest ids are the real Forever ids.
-- Dungeon item sources and a few spots are beta-player reports. Nothing published past 26.
local ARAMIS  = {31,66,"Aramis Hammerhand, Deathknell church",TIR}
local SHARI   = {60,53,"Shari Stilwell, Brill paladin trainer",TIR}
local BRETON  = {22,45,"Breton Samuels, Bandarion Keep",TIR}
local DANITHA = {22,45,"Danitha Morr, Bandarion Keep",TIR}
local JORIN   = {23,45,"Jorin Croge, Bandarion Keep",TIR}
local BILLMUTH= {22,45,"Deathguard Billmuth, downstairs in Bandarion Keep",TIR}
local TANIS   = {66,38,"Tanis Alderwood, Trade Quarter, Undercity",UC}
local TREVAN  = {43,41,"Trevan Rol, the Sepulcher (basement)",SIL}
local LUMINA  = {43,41,"Lumina Windsinger, the Sepulcher",SIL}
local OTT     = {60,26,"Ott, by the Horde wagon, south-east Tarren Mill",HIL}

inject("b1", {
  {q="A Difficult Path", id=98601, cls="PALADIN", g={31,66,"Shadow Priest Sarvis, Deathknell (hands you the Consecrated Scroll)"}, r=ARAMIS},
  {q="Rediscovering the Light", id=90902, cls="PALADIN", g=ARAMIS, o={32,65,"Holy Light 5 Injured Deathguard around the church"}, r={31,66,"Aramis Hammerhand: Holy Light"}},
  {q="A Light in the Darkness", id=98389, cls="PALADIN", g=ARAMIS, o={27,59,"Free 6 Webbed Forsaken in Night Web's Hollow"}, r=ARAMIS},
  {q="Coming to Terms", id=91208, cls="PALADIN", g=ARAMIS, o={28,64,"Offer aid to the Frightened Paladin in the hills west of the chapel"}, r=ARAMIS},
  {q="Continue Your Training", id=91209, cls="PALADIN", g=ARAMIS, r=SHARI},
})

inject("b2", {
  {q="A Second Home", id=91282, cls="PALADIN", g=SHARI, r=BRETON},
  {q="Murlocs at the Gates", id=91285, cls="PALADIN", g=BRETON, o={18,57,"8 Vile Fin Attackers, 8 Vile Fin Seers on the bluffs and lake camps"}, r=BRETON},
  {q="Touring the Grounds", id=91294, cls="PALADIN", g=BRETON, o={22,47,"Talk to Hilda the Breaker (22,47), Jorin Croge (23,45), Ander Solliden (25,50), Danitha Morr (22,45)"}, r=DANITHA},
  {q="Making Repairs", id=91316, cls="PALADIN", g=JORIN, o={13,66,"12 Sturdy Lumber in the Shadowvale crypt; entrance in the burned house"}, r=JORIN},
  {q="The Tarnished", id=91317, cls="PALADIN", g=DANITHA, o={12,64,"8 Tarnished Drudges, 6 Tarnished Zealots, Commander Rudolph Gelhardt's head, Shadowvale"}, r=DANITHA},
  {q="A Token of Good Faith", id=95803, cls="PALADIN", g=DANITHA, r={58,92,"Lady Sylvanas Windrunner, Royal Quarter, Undercity",UC}},
}, 10)

-- Redemption at 12: all seven parts are named "A Lesson in Divinity".
inject("b3", {
  {q="A Lesson in Divinity", p=1, id=94427, cls="PALADIN", g=DANITHA, r=TANIS},
  {q="A Lesson in Divinity", p=2, id=94434, cls="PALADIN", g=TANIS, o={66,38,"10 Linen Cloth",UC}, r=TANIS},
  {q="A Lesson in Divinity", p=3, id=94435, cls="PALADIN", g=TANIS, r={22,45,"Danitha Morr: Symbol of Life",TIR}},
  {q="A Lesson in Divinity", p=4, id=94436, cls="PALADIN", g=DANITHA, r=BILLMUTH},
  {q="A Lesson in Divinity", p=5, id=94438, cls="PALADIN", g=BILLMUTH, o={87,48,"Use the Symbol of Life on Deathguard Falgan, Venomweb Vale",TIR}, r={87,48,"Deathguard Falgan",TIR}},
  {q="A Lesson in Divinity", p=6, id=94440, cls="PALADIN", g={87,48,"Deathguard Falgan",TIR}, o={87,48,"Scarlet Crusade Attack Plans from the Scarlet Crusaders in Venomweb Vale (verify mobs)",TIR}, r=BILLMUTH},
  {q="A Lesson in Divinity", p=7, id=94441, cls="PALADIN", g=BILLMUTH, r={22,45,"Danitha Morr: Redemption",TIR}},
}, 0)

-- Moonsilver Blade / Wolfsbane, 18-26. The Silverpine part fits the Hillsbrad bracket (the
-- Sepulcher is on the way in); the Kor Gem and the finish fit 25-30 as a detour.
inject("b5", {
  {q="Diplomatic Incident", id=91858, cls="PALADIN", g=DANITHA, r=TREVAN},
  {q="A Curious Pair", id=91859, cls="PALADIN", g=TREVAN, r={46,42,"Deathguard Baldren, Sepulcher entrance",SIL}},
  {q="A Grim Fate", id=91860, cls="PALADIN", g={46,42,"Deathguard Baldren",SIL}, o={65,25,"The Tauren corpse on a pyre on the Fenris Isle shore (verify spot)",SIL}},
  {q="Into Fenris Keep", id=91861, cls="PALADIN", g={65,25,"The pyre, Fenris Isle (verify)",SIL}, r={66,23,"Lumina Windsinger, caged in the Fenris Keep basement",SIL}},
  {q="Lumina Windsinger", id=91862, cls="PALADIN", g={66,23,"Lumina Windsinger",SIL}, o={66,24,"Fenris Isle Key from the Rot Hide gnolls in the keep",SIL}, r={66,23,"Lumina Windsinger",SIL}},
  {q="The Windshaper's Wrath", id=96204, cls="PALADIN", g={66,23,"Lumina Windsinger",SIL}, o={66,23,"Escort her out to the dock",SIL}, r=LUMINA},
  {q="The Debt", id=95034, cls="PALADIN", g=LUMINA, r=LUMINA},
  {q="A Moon-Kissed Blade", id=95036, cls="PALADIN", g=LUMINA, o={43,41,"Trevan's Weapon Notes, then: Whitestone Oak Lumber (Goblin Woodcarvers, Deadmines), Enchanted Silver Ingot (table beside Arugal, Shadowfang Keep), Purified Kor Gem (Seeking the Kor Gem, Ashenvale)",SIL}, r=TREVAN},
  {man="Paladin: run Shadowfang Keep (Silverpine 45,68) for the Enchanted Silver Ingot beside Arugal while you are here. The Deadmines lumber means a trip to Westfall; group up for it.", cls="PALADIN", x=45, y=68, map=SIL},
})
inject("b6", {
  {q="Seeking the Kor Gem", id=95042, cls="PALADIN", g={12,34,"Ulric Frostveil, Zoram Strand",1440}, o={15,12,"Corrupted Kor Gem from Blackfathom Tide Priestesses and Oracles outside Blackfathom Deeps",1440}, r={12,34,"Ulric Frostveil: Purified Kor Gem",1440}},
  {man="Paladin detour: with lumber, ingot and gem, go back to the Sepulcher to finish the blade (Undercity zeppelin, fly to the Sepulcher).", cls="PALADIN", x=43, y=41, map=SIL},
  {q="An Underrated Talent", id=95111, cls="PALADIN", g=TREVAN, r=OTT},
  {q="Ott's Masterwork", id=95125, cls="PALADIN", g=OTT, o={60,26,"Watch Ott forge the blade (30 s)",HIL}, r=OTT},
  {q="The Moonsilver Blade", id=95126, cls="PALADIN", g=OTT, r={43,41,"Trevan Rol: Moonsilver Blade",SIL}},
  {q="Old Fire-Eye", id=95140, cls="PALADIN", g=LUMINA, o={50,87,"Old Fire-Eye (elite worgen) by the Greymane Wall; hit him with the Moonsilver Blade to break his shield. Train 2H Swords first (Archibald, War Quarter, Undercity). Group of 2+",SIL}, r={43,41,"Lumina Windsinger: Wolfsbane",SIL}},
  {forever=true, cls="PALADIN", t="Forsaken Paladin: nothing past 26 is published yet (beta cap 30). A Retribution-themed level-60 charger quest is announced."},
})
