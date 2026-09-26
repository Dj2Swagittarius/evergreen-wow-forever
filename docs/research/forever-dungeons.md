# WoW Forever: new dungeons and raids (research, 2026-09-26)

Scope: instances that are **new in WoW Forever** (client 1.60.1, beta since 2026-09-17, launch 2026-11-04, raids unlock 2026-12-09). Classic Era instances that return unchanged (Onyxia's Lair and the rest) are only mentioned where it helps.

**Tags**
- `[DM]`: confirmed-datamined. Taken from Wowhead Forever's database: page markup, Listview data, Mapper data, or `nether.wowhead.com/forever/tooltip/*`.
- `[BETA]`: beta-player report. Comes from a Wowhead beta walkthrough/guide or from third-party sites that ran the beta.
- `[ANN]`: announced-only. Blizzard news, a BlizzCon panel, or a blue post.
- `[UNV]`: unverified. Comes from a single third-party site, sources conflict, or it is my inference.

**Method notes**
- Wowhead zone ids are AreaTable ids, **not** uiMapIDs. Where a uiMapID is given, it is the Classic Era value for the parent zone. `[UNV]`: Forever may renumber them.
- Wowhead has **no boss levels** for the new NPCs. Their tooltips show only type and classification, for example "Undead (Elite)". Any boss level below comes from third-party sites and is tagged `[UNV]`.
- Wowhead has **no drop tables** yet for the new bosses. Item pages have no "Dropped by" data. Boss→item mapping comes from Wowhead's own beta guide (Hall of Thanes) or from third-party beta guides (Ruins of Lordaeron). Every item id and name below was verified against the Wowhead Forever tooltip API.
- Several third-party "guide" sites contradict each other on boss order and coordinates, and some list item names that do not exist in the database. Those names are flagged. Turtle WoW and other private-server content is excluded.

---

## 1. The Hall of Thanes

| Field | Value |
|---|---|
| Type | 5-player dungeon `[DM]` (zone 16919, "Territory: Contested") |
| Levels | 13-18 `[ANN]` (Blizzard, via Wowhead news 382895). Wowhead's "at level" is 14 `[BETA]` |
| Beta | Playable since beta start (level-20 phase) `[BETA]` |
| Location | Beneath the High Seat of Ironforge. Go through the open door to "Old Ironforge" immediately left after entering the High Seat, then follow the path to the bottom to the portal `[BETA]` (Wowhead guide 34887) |
| Parent map | Ironforge (Classic uiMapID 1455 `[UNV]`) |
| Entrance x,y | **Not published** as map coordinates. The quest givers inside Old Ironforge are at Ironforge map ~31.4-33.2, 44.4-48.6 `[DM]` (Mapper data for Thom Filch and Afadra Dunwall) |
| Nearest spirit healer | Dun Morogh 52.4, 37.8 `[BETA]` |

### Bosses, in order (Wowhead guide 34887) `[BETA]`, with NPC ids `[DM]`
The kill-count achievement is `63573` (Durgen Dirgehammer Kills) `[DM]`. Boss levels are unknown.

| # | Boss | NPC id | Notes |
|---|---|---|---|
| 1 | Faldrim Anvilmar | 261306 | Undead elite. Patrols Anvilmar's Rest. Tank-and-spank with Mind Blast and a 10-min "Curse of Anvilmar" on the tank |
| 2 | Magmatus | 261316 | Elemental elite, comes with a Dark Iron Summoner (263438). Fire Nova-like pulse; "Combust" on a random player |
| 3 | Plunder | 261311 | Elemental elite (golem). Patrols a hallway. Knockback only |
| 4 | Durgen Dirgehammer | 261319 | Humanoid elite, final boss. Two Lesser Stone Golems (263466) plus Dark Iron Looters (263396). AoE fear and Rend |

### Loot per boss `[BETA]` (Wowhead guide 34887), ids and stats `[DM]`
All items are quality 3 (rare), ilvl 18, require level 13.

| Boss | Item (id) | Slot |
|---|---|---|
| Faldrim Anvilmar | Spiritwraith Drape (271097) | Cloak |
| Faldrim Anvilmar | Ephemeral Choker (270227) | Neck |
| Faldrim Anvilmar | Aetherwisp Bracers (271096) | Cloth wrist |
| Magmatus | Kindlegem Girdle (270230) | Mail waist |
| Magmatus | Flamefist Grips (270231) | Leather hands |
| Magmatus | Fang of Magmatus (271095) | MH dagger |
| Plunder | Golemheart Stave (270228) | 2H staff |
| Plunder | Golemguard Chest (271098) | Mail chest |
| Plunder | Treads of the Protector Golem (270229) | Mail feet |
| Durgen Dirgehammer | Durgen's Crescent Axe (270256) | MH axe |
| Durgen Dirgehammer | Direhammer Leggings (270260) | Leather legs |
| Durgen Dirgehammer | Robes of the Disgraced Thane (270261) | Cloth chest |

### Quests
Levels and required levels come from the Wowhead Listview `[DM]`. `side` 1 means Alliance. Coordinates come from Wowhead Mapper data `[DM]` unless noted.

| Quest (id) | Lvl / req | Faction | Giver: zone, coords | Objective | Rewards (item ids) |
|---|---|---|---|---|---|
| Underground Map (96391) | 15 / 9 | Alliance | Starts from the item Dark Iron Map (274268). Turn in to Earthseer Farsen (264936), Dun Morogh 64.8, 58.4 | Deliver the map. This is the prereq for 96393 | unknown |
| Old Ironforge Incursion (96393) | 16 / 9 | Alliance | Earthseer Farsen (264936), Dun Morogh (Gol'Bolar Quarry) 64.8, 58.4. Ends at King Magni Bronzebeard (2784), Ironforge 39.4, 55.4 | Loot Durgen Dirgehammer's Head (274286) | choice: 279894 Calibrated Blunderbuss, 279895 Ironforge Greathammer, 279896 Deepblaze. Also 8s money and 1450 xp |
| The Restless Dead (96394) | 15 / 10 | Alliance | Afadra Dunwall (264943), Ironforge ~32.4, 47.8 | Kill 15 Enraged Apparition (263389) and 10 Tormented Soul (263390) | choice: 279897 Dusty Belt, 280095 Cryptwalker Bracers |
| An Ancient Grudge (96395) | 15 / 10 | Both (side None) | Ghostly Attendant (265002), inside the dungeon at Anvilmar's Rest | Kill Faldrim Anvilmar | choice: 279899 Catacomb Cloak, 279900 Deepgrave Trousers |
| Important Heirlooms (96403) | 15 / 10 | Alliance `[DM]` (Wowhead's guide table says both) | Thom Filch (265003), Ironforge ~31.4, 45.4 (guide gives /way 32.6 44.6) | Collect 8 Dwarven Heirloom (274289) | choice: 279898 Dwarven Tome, 280096 Tomb Robber's Gloves |
| The Treaty of Understanding (98423) | 16 / 9 | Alliance | Starts from the item Treaty of Understanding (281030), found in a vault in the Reliquary of Kings. Ends at Magni Bronzebeard, Ironforge 39.4, 55.4 | Deliver the treaty | unknown |

The Wowhead guide table puts Afadra Dunwall at "/way 64.8 58.4". That is a copy error: the Mapper data puts her in Ironforge. `[UNV]`

---

## 2. Ruins of Lordaeron

| Field | Value |
|---|---|
| Type | 5-player dungeon `[DM]` (zone 16611, "Contested") |
| Levels | 15-20 `[ANN]` |
| Beta | Playable since beta start `[BETA]` |
| Location | Surface ruins of Lordaeron (Capital City) above Undercity, Tirisfal Glades. The portal/meeting stone is in the east courtyard `[BETA]` |
| Parent map | Tirisfal Glades (Classic uiMapID 1420 `[UNV]`) |
| Entrance x,y | Tirisfal Glades **71.6, 11.4** `[UNV]` (coachcarry and theclick agree). One site (woweternity) gives 61.2, 67.4, which is inconsistent with the location, so disregard it |

### Bosses `[DM]` names and ids. Order and levels `[UNV]`
Rath'mael's kill achievement is `63571` `[DM]`. Sources disagree on the order:
- wowhandbook: Witherfang → The Abandoned → The Baron → Rath'mael → Lordaeron Captain → Viktor → Bjork.
- coachcarry and woweternity: The Baron → Witherfang → The Abandoned → Bjork → Rath'mael → Viktor, with the Captain as a rare.

The dungeon has a non-linear courtyard layout, so treat the order as unknown. Rath'mael is the end boss (Wowhead ties the kill achievement to him). The levels in the table are from coachcarry `[UNV]`.

| Boss | NPC id | Type | Notes |
|---|---|---|---|
| The Baron | 250660 | Undead elite | Abomination. Drops Head of the Baron / Abominable Head for quests. Lvl 17 `[UNV]` |
| Witherfang | 250483 | Beast elite | Spider. Holds Highly Toxic Strain for quest 95216. Lvl 17 `[UNV]` |
| The Abandoned | 250631 | Undead elite | Banshee/spirit. Spawns in the courtyard after all enemies there are cleared, followed by waves `[UNV]`. Lvl 18 `[UNV]` |
| Bjork | 256097 | Undead elite | Tank-and-spank with heavy tank damage and a knockback `[UNV]`. Lvl 18 `[UNV]` |
| Rath'mael | 250657 | Undead elite | Necromancer at an unholy altar at the end of the corridor, using frost and necromancy. Lvl 19 `[UNV]` |
| Viktor the Vile | 256035 | Beast elite | Secret/event boss: click the kindling at the campfire in the SW ruined house, then survive waves `[UNV]` |
| Lordaeron Captain | 255699 | Undead **rare** elite | Rare spawn, not present every run `[DM]` (classification) / `[UNV]` |

### Loot per boss
Boss→item mapping is `[BETA]`/`[UNV]`: four third-party beta guides agree apart from the name slips noted below. All ids and stats are `[DM]` and all items are quality 3. The ilvl groupings match the mapping.

| Boss | Item (id) | Slot, ilvl, req |
|---|---|---|
| Witherfang | Atrophic Girdle (271201) | Mail waist, 20, 15 |
| Witherfang | Witherbite Bracers (271202) | Leather wrist, 20, 15 |
| Witherfang | Segmented Spider Leg (271203) | 2H staff, 20, 15 |
| The Baron | Meathook Slicer (271204) | 1H dagger, 20, 15 |
| The Baron | Abomination Bones (271205) | Mail chest, 20, 15 |
| The Baron | Leftover Abomination Skin (271206) | Cloth chest, 20, 15 |
| The Abandoned | Rotmender's Leggings (271207) | Cloth legs, 22, 17. Some sites call it "Wispcloth Leggings", which is not in the DB |
| The Abandoned | Grip of Fear (271208) | Mail hands, 22, 17 |
| The Abandoned | Scepter of the Abandoned (271216) | MH mace, 22, 17 |
| Bjork | Bonerust Leggings (271209) | Mail legs, 21, 16 |
| Bjork | Tuskwrap Belt (271210) | Cloth waist, 21, 16 |
| Bjork | Corpse Chopper (271217) | 2H axe, 21, 16 |
| Viktor the Vile | Vilewalkers (271211) | Mail feet, 22, 17 |
| Viktor the Vile | Bloodied Chestwraps (271212) | Leather chest, 22, 17 |
| Viktor the Vile | Vileblood Scimitar (271218) | 1H sword, 22, 17 |
| Rath'mael | Mirror of Rath'mael (271213) | Shield, 24, 19 |
| Rath'mael | Rotmender's Treads (271214) | Cloth feet, 24, 19. Some sites call it "Frostbane Treads", which is not in the DB |
| Rath'mael | Coldspire Staff (271215) | 2H staff, 24, 19 |
| Lordaeron Captain | Haunting Blade (6641) | Classic item reused, ilvl 27, req 22 `[UNV]` (2 sites) |
| Lordaeron Captain | Phantom Armor (6642) | Classic item reused, ilvl 27, req 22 `[UNV]` (2 sites) |

### Quests
Ids, levels, faction and objectives are `[DM]` (zone-16611 Listview, quest pages, tooltips).

| Quest (id) | Lvl / req | Faction | Giver: zone, coords | Objective | Rewards |
|---|---|---|---|---|---|
| A Frightened Request (92401) | 22 / 15 | Horde | Tabitha Heartweaver (250686), Silverpine Forest 44.4, 43.0 | Investigate the disappearance of Edward Heartweaver in the Ruins of Lordaeron. A third-party site says this means killing Witherfang `[UNV]` | 251485 Edward's Knife, 251486 Tabitha's Cuffs (listed near the rewards; choice vs. fixed unknown) |
| The Wrath of Rath'mael (92422) | 22 / 15 | Horde | Deathguard Kristof (251001), Tirisfal Glades (Brill) 65.2, 60.2 | Kill Rath'mael | choice: 251533 Forsaken Greataxe, 251534 Gnarled Necromancer's Staff |
| Light's Justice (92421) | 22 / 15 | Horde | Morbin Lightbane (266484), Undercity 57.4, 90.4 | Collect 25 Intact Limbs | choice: 279874 The Stitcher, 279875 Spare Part Bindings. Also 45s |
| The New Plague (95216) | 22 / 16 | Horde | Theodore Griffs (11835), Undercity 46.4, 71.4 | Highly Toxic Strain (275443) from Witherfang | choice: 279876 Plaguefang, 279877 Blight Gloves |
| Unending Torment (97288) | 21 / 16 | Horde | Starts from the item Abominable Head (280438), a drop. Ends at Master Apothecary Faranell (2055), Undercity 48.4, 69.4 | Deliver the head. The chain continues with 97289 (bring Head of the Baron to Othmar's body), 97291 (collect Toxic Skullcap, Blisterweed and Essence of Agony in Undercity) and 97292 (inject the Hissing Serum), all level 21 | none listed. 97289-97292 give 13s each |
| Crest of Lordaeron (95204) | 22 / 16 | Horde | Starts from the item Crest of Lordaeron (268579). Ends at Oran Snakewrithe (7825), Undercity 73.4, 32.4 | Deliver the crest | 280567 Small Sack of Gems |
| Abominable Creatures (95250) | 21 / 16 | Alliance | Giver not on Wowhead. Third parties say Captain Truman, Hillsbrad Foothills 50.8, 59.2 `[UNV]` | Head of the Baron (268518) | choice: 279864 Monstrous Cleaver, 279865 Grave Shroud, 279867 Slain Baron's Signet |
| Bloodied Insignia (95195) | 22 / 16 | Alliance | Ends at General Marcus Jonathan (466), Stormwind 63.4, 75.8. The start may be an item or Jonathan himself (Wowhead's guide says Jonathan) | Collect 10 Bloodied Insignia (items 268535/268540) | choice: 279868 Duty Bound Leggings, 279869 Remembrance Armor. Also 45s |
| Crest of Lordaeron (95189) | 22 / 16 | Alliance | Starts from the item Crest of Lordaeron (275521). Ends at Lady Dena Kennedy (15991), Stormwind 62.4, 5.8 | Deliver the crest | 280567 Small Sack of Gems |
| Remember That I Love You (92415) | 22 / 15 | Alliance | Starts from the item Blood-Stained Letter (251522), a drop. Ends at Orphan Matron Nightingale (14450), Stormwind ~47.4, 38.6 | Deliver the letter | none listed |

The Ruins of Lordaeron have quests for both factions, so the zone is "Contested" even though it sits beside Undercity.

---

## 3. Excavation Site: Wetlands

| Field | Value |
|---|---|
| Type | 5-player dungeon `[DM]` (zone 16732). Related world zone: Whelgar's Excavation Site (16876) `[DM]` |
| Levels | 24-29 `[ANN]` |
| Beta | Wowhead's beta overview says it opens with the level-30 phase "after two weeks" (about Oct 1) `[BETA]`. It is not confirmed open as of today |
| Location | Wetlands, on top of or behind Whelgar's Excavation Site `[ANN]` (the Blizzard panel says "above Whelgar's Excavation") |
| Parent map | Wetlands (Classic uiMapID 1437 `[UNV]`) |
| Entrance x,y | **Unknown** |

### Bosses: names and ids `[DM]`, order `[UNV]` (wowhandbook)
1. Saltspine, 260322 (Beast elite, crocolisk)
2. Shadetooth, 260325 (Beast elite, raptor leader)
3. Highland Horror, 260808 (Elemental elite)
4. Relic Guardian, 260326 (Elemental elite, construct)

Levels are unknown.

### Loot
**Unknown.** No source attributes drops. Candidate datamined blues fit the 24-33 band and the theme: 273022 Supple Bellyskin Leggings, 273025 Raptorclaw Greaves, 273027 Raptor's Gaze and 273028 Reliquary Mantle, all ilvl 31-33, req 26-28 `[UNV]`, inference from the names only. **Do not use these as boss loot until confirmed.**

### Quests
None found on Wowhead (the zone page has no quest list). wowhandbook says there are none `[UNV]`. Related items: 278049 and 278398 Excavation Tools, and 280403 Whelgar Relic Package `[DM]`. They are probably world quests.

---

## 4. City of Dalaran

| Field | Value |
|---|---|
| Type | 5-player dungeon `[DM]`. There are **two** zone ids: 16544 ("Sanctuary") and 16560 ("Contested"), probably the restored city hub and the dungeon phase `[UNV]` |
| Levels | 28-33 `[ANN]`. An older Wowhead text said 20-35 |
| Beta | Unconfirmed. Some third parties say "the start of City of Dalaran" is testable `[UNV]` |
| Location | Alterac Mountains, the former Dalaran dome. The barrier is down. Sewers entrance leads to the underbelly `[UNV]` (warcrafttavern). Dalaran Sewer Key item 277507 `[DM]` |
| Parent map | Alterac Mountains (Classic uiMapID 1416 `[UNV]`) |
| Entrance x,y | **Unknown** |

### Encounters: names and ids `[DM]`, set and order `[UNV]`
Kill achievements `[DM]`: Shade of the Archmage (63572) and Lyn the Ignored (63589). warcrafttavern lists 3 bosses (Arcane Anomaly, Unstable Sentinel, Shade of the Archmage). wowhandbook lists 9, in this order:

| Name | NPC id | Type |
|---|---|---|
| Arcane Anomaly | 245999 | Elemental elite |
| Fel Ancient | 246003 | Demon elite |
| Mana Devourer | 246008 | Demon elite |
| Mana Elemental | 240352 | Wowhead shows "Level 63 Elemental (Elite)". This id may not be the dungeon NPC `[UNV]` |
| Unstable Sentinel | 246017 | Elemental elite |
| Shade of the Archmage | 246020 | Elemental elite. Has a kill achievement, so probably the end boss `[UNV]` |
| Lyn the Ignored | 247032 | Humanoid **rare** elite, with a kill achievement |
| Atrexis the Grave Knight | 247126 | Humanoid elite |
| Mana Wraith | 246931 | Elemental elite |

Arcanic Enigma (246016, Elemental elite) is also in the id block `[DM]`, but no source names it as a boss.

### Loot
**Unknown.** Candidate datamined blues with arcane or construct names: 273042 Manascale Treads, 273044 Arcanowisp Robes, 273045 Drape of Shifting Energy, 273046 Guardian's Dualblade, 273047 Unstable Crystalline Shoulderpads and 273052 Ponderous Orb (ilvl 32-35, req 27-30) `[UNV]`, inference from names only. Also 279841 Defender of Dalaran (ilvl 36), which could be a quest reward.

### Quests
None attributed yet. 94946 "The Magical City of Dalaran" (lvl 13) exists `[DM]`, probably a breadcrumb for the city, not a dungeon quest.

---

## 5. The Drowned City

| Field | Value |
|---|---|
| Type | 5-player dungeon `[ANN]` |
| Levels | 35-40 `[ANN]` |
| Beta | No (above the beta cap). It was playable as the BlizzCon 2026 demo `[BETA]`; Wowhead links a Guzu playthrough, youtube k0DVYMoO1x8 |
| Location | Ancient troll ruin off the coast of Stranglethorn Vale `[ANN]`/`[BETA]` |
| Entrance x,y / zone id | **Unknown**. No Wowhead zone id found |

### Encounters
These NPCs are `[DM]`, but their subtitle is "Staging Area N", which looks like demo-build tags. Bosses in the order of those tags:

1. Zul'Alai, 270882 (Undead elite)
2. Var'Taka, 270883 (Humanoid elite)
3. Captain Dreadrise, 270884 (Humanoid elite)
4. Deathless Marrow, 270885 (Elemental elite). Primeval Elemental (270887) is also tagged Staging Area 4
5. Gill, 270888 (Elemental, *normal*)
6. Min'loth the Serpent, 270886 (Humanoid elite)

warcrafttavern lists Zul'Alai, "Zin'aka", Deathless Marrow and Min'loth the Serpent `[UNV]`. No NPC named Zin'aka exists in the DB, so it may be Var'Taka. Loot and quests are unknown.

---

## 6. Krol'dok Stronghold

- 5-player dungeon, **levels 40-45** `[ANN]` (Blizzard blue post correcting the BlizzCon listing). Location: the new Riverglades zone (zone 16591, "Level 36-44" `[DM]`) `[ANN]`. Entrance coordinates are unknown. Not in beta.
- Related datamined items: 267089 Krol'dok Compound Key, 271721 Krol'dok Ogre Key, 267137/267138 Krol'dok Moulding, and item set 2135 "Krol'dok Battlegear" `[DM]`.
- Bosses, loot and quests are unknown.

## 7. Alcaz Prison ("Alcaz Island Prison")

- 5-player dungeon, **levels 48-53** `[ANN]`. Location: Alcaz Island, far NE Dustwallow Marsh `[ANN]`/Wowhead (Classic uiMapID 1445 `[UNV]`). Coordinates are unknown. Not in beta.
- Boss: **Blazeroar** (kill achievement 63575) `[DM]`. No NPC id found. Loot and quests are unknown.

## 8. Blackmaw Hold

- 5-player dungeon, **levels 55-60** `[ANN]`. Described as a great furbolg city behind the furbolg gates in northern Azshara (Wowhead) `[ANN]`/`[UNV]`. The tunnels beneath are hinted to lead to the Barrow Deeps `[UNV]`. Coordinates are unknown. Not in beta.
- Datamined furbolg NPCs: Blackmaw Warrior 237732, Den Watcher 237733, Totemic 237734, Pathfinder 237735, Shaman 237736 and Ursa 237738, all *normal*. These are probably trash or world mobs `[DM]`. Items: 276893 Blackmaw Ritual Totem and 273050 Blackmaw Pouch `[DM]`.
- Bosses, loot and quests are unknown.

## 9. The Shaper's Terrace

- 5-player dungeon, **levels 58-60** `[ANN]`. Location: Un'Goro Crater `[ANN]` (Classic uiMapID 1449 `[UNV]`). Coordinates are unknown. Not in beta.
- Bosses from kill achievements `[DM]`: **Nanaya** (63574), **Cinder** (63590), **Bolt** (63592) and **Snowtalon** (63593). No NPC ids found, and the order is unknown.
- Loot and quests are unknown.

---

## 10. The Barrow Deeps (raid)

- **10-player raid, level 60** `[ANN]`. Unlocks **2026-12-09**, with no attunement at launch `[ANN]` (Blizzard via But Why Tho? interview). It is a Night Elf prison.
- **3 entrances** in the world. One is in Mount Hyjal `[ANN]`/Wowhead. Blackmaw Hold is hinted as another `[UNV]`. Coordinates are unknown.
- Encounters, from achievement "Conquerer of the Deeps" (62035/64020) `[DM]`. There are 8, and the order in the achievement tooltip is not necessarily the kill order:
  Deepscar Matriarch, Khalith the Dreadspinner, Amethrax, Ravus and Darlissa, Elder Tangleclaw, Well of Sorrow, Del'lynar Songwood, Sonya Darkhallow.
  Sonya Darkhallow has a kill achievement (63581), so she is probably the final boss `[UNV]`.
- Related `[DM]` items: 277175 Corrupted Tangleclaw Shard, 277178 Corrupted Sorrowful Shard and 277179 Corrupted Amethrax Shard (rare, unique; purpose unknown), and 286300 Sonya Darkhallow's Gold Coin (junk). Deepscar Brute 274258 and Deepscar Yeti 274259 are NPCs, probably trash.
- No boss NPC ids and no loot found.

## 11. Hyjal Summit (raid)

- **20-player raid, level 60**, in the new Mount Hyjal zone `[ANN]`. Unlocks **2026-12-09**, no attunement `[ANN]`. The entrance is unknown.
- Encounters, from achievement "Conquerer of the Wilds" (62034/64019) `[DM]`. There are 13, order unknown:
  Bandalar, Time-Lost Battalion, Old Gloomlurker, Kathris the Haunted, Elder Minderel, Council of Thorns, The Wild King, Ancient of Decay, Sylvestris Dusksong, Gharalis the Abyssal, Anara Chillwind, Tracker Stillwind, Nythus the Dreambound.
  The Wild King has a kill achievement (63580).
- Related `[DM]`: Token of the Wild King (268967, quest item). Ve'ho Manyhorns, "Lieutenant of the Wild King" (260674 normal / 267182 elite). Blackthorne Courier, "Messenger of the Wild King" (264508). (DNT) Sylvestris' Bow (264671). Hyjal Summit Trash Weapon (274560).
- No boss NPC ids and no loot found.

## Onyxia's Lair (returning, not new)
40-player raid, unlocks 2026-12-09 `[ANN]`. Wowhead notes that the entrance "might have moved" `[UNV]`. Not detailed here.

---

## Other candidates checked

- **Karazhan crypts, Gilneas (instance), Grim Batol, Dragonmaw:** no Blizzard or Wowhead-Forever evidence of a Forever dungeon or raid. The Blizzard "What's Next" panel recap names only the 9 dungeons and 2 raids above.
- Datamined but not instances:
  - "Ruins of Gilneas" (zone 16756), type Zone.
  - "Battle for Gilneas" (16653), a battleground.
  - "Darkspear Islands" (16606), a 15v15 battleground `[ANN]`.
- Datamined 5-player "Dungeon"-type zones with no announcement: **"Half-Pint Tavern" (16632)** and a **"Hillsbrad Foothills" (16562)** instance. Their purpose is unknown `[DM]` (these may be scenarios or phased areas). Worth re-checking later.
- A "Legacy" dungeon achievement list `[DM]` (62031-62033) confirms the full launch dungeon set:
  - Novice: RFC or Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands, and others.
  - Experienced: City of Dalaran, The Drowned City, Krol'dok Stronghold, and others.
  - Master: Alcaz Prison, Blackmaw Hold, The Shaper's Terrace, and others.

---

## Sources

- Wowhead Forever:
  - Dungeons Overview guide 34783: https://www.wowhead.com/forever/guide/dungeons-overview-locations-details
  - Hall of Thanes guide 34887 (Jurdi, patch 1.60.1, 2026-09-25): https://www.wowhead.com/forever/guide/hall-of-thanes-dungeon-overview-location-rewards
  - Every Dungeon Quest guide 34916: https://www.wowhead.com/forever/guide/34916
  - Raids Overview guide 34784: https://www.wowhead.com/forever/guide/34784
  - Forever Overview guide 34781: https://www.wowhead.com/forever/guide/34781
  - Beta Overview guide 34794: https://www.wowhead.com/forever/guide/34794
  - News 382854 (New Dungeons and Raids), 382895 (Krol'dok level clarification, blue post), 382964 (no attunements interview), 382991 (Hall of Thanes walkthrough), 383002 (item sets), 383018 (loot mail): https://www.wowhead.com/forever/news/…
  - Zone pages 16919, 16611, 16732, 16876, 16544, 16560, 16591, 16632, 16562, 16756: https://www.wowhead.com/forever/zone=NNNNN
  - Quest pages (Mapper and giver data): https://www.wowhead.com/forever/quest=NNNNN
  - Tooltip API used to verify every id: https://nether.wowhead.com/forever/tooltip/{item,npc,quest,achievement}/NNNNN
- Blizzard, *World of Warcraft: Forever What's Next Panel Recap*: https://news.blizzard.com/en-us/article/24303862/world-of-warcraft-forever-whats-next-panel-recap
- Third-party (`[UNV]` unless corroborated):
  - https://coachcarry.com/blog/wow-forever-ruins-of-lordaeron-guide
  - https://wowhandbook.com/zones/dungeons/ruins-of-lordaeron/
  - https://wowhandbook.com/zones/dungeons/excavation-site-wetlands/
  - https://wowhandbook.com/zones/dungeons/city-of-dalaran/
  - https://www.zockify.com/forever/dungeons/ruins-of-lordaeron/
  - https://woweternity.com/forever/dungeons/ruins-of-lordaeron
  - https://www.warcrafttavern.com/forever/guides/dungeons/
  - https://lfcarry.com/guides/wow-forever-dungeons
  - https://lfcarry.com/guides/wow-forever-raids
  - theclick.gg / allthings.how (RoL entrance, via search snippets)

---

## Summary table (machine-friendly)

`items_with_ids` counts boss-loot items with verified ids and boss attribution (candidates excluded). `quests` counts dungeon quest ids found, including item-started and chain steps. `?` means unknown.

| instance | type | players | levels | zone (wowhead zone id) | entrance_xy | beta_now | boss_count | items_with_ids | quests |
|---|---|---|---|---|---|---|---|---|---|
| The Hall of Thanes | dungeon | 5 | 13-18 | Ironforge / Old Ironforge (16919) | ? | yes | 4 | 12 | 6 |
| Ruins of Lordaeron | dungeon | 5 | 15-20 | Tirisfal Glades (16611) | 71.6,11.4 (UNV) | yes | 7 (incl. 1 rare, 1 secret) | 20 (2 UNV) | 13 |
| Excavation Site: Wetlands | dungeon | 5 | 24-29 | Wetlands (16732) | ? | level-30 phase (~Oct 1) | 4 | 0 | 0 |
| City of Dalaran | dungeon | 5 | 28-33 | Alterac Mountains (16544/16560) | ? | unconfirmed | 3-9 (UNV) | 0 | 0 |
| The Drowned City | dungeon | 5 | 35-40 | Stranglethorn coast (?) | ? | no | 5-6 (UNV) | 0 | 0 |
| Krol'dok Stronghold | dungeon | 5 | 40-45 | Riverglades (?) | ? | no | ? | 0 | 0 |
| Alcaz Prison | dungeon | 5 | 48-53 | Dustwallow Marsh, Alcaz Island (?) | ? | no | >=1 | 0 | 0 |
| Blackmaw Hold | dungeon | 5 | 55-60 | Azshara (north) (?) | ? | no | ? | 0 | 0 |
| The Shaper's Terrace | dungeon | 5 | 58-60 | Un'Goro Crater (?) | ? | no | >=4 | 0 | 0 |
| The Barrow Deeps | raid | 10 | 60 | Mount Hyjal + 2 other entrances (?) | ? | no (Dec 9) | 8 | 0 | 0 |
| Hyjal Summit | raid | 20 | 60 | Mount Hyjal (?) | ? | no (Dec 9) | 13 | 0 | 0 |
