# WoW Forever: Forsaken (Undead) Paladin class quests

Research date: 2026-09-26 (beta build 1.60.1, level cap 30).
Main source: the Wowhead Forever database (`wowhead.com/forever`). Its quest pages are built from beta client data, and its map coordinates come from the Wowhead client. Quest IDs are included so you can check them in game with `/run print(C_QuestLog.IsQuestFlaggedCompleted(ID))`.

Confidence tags:
- **confirmed-datamined**: the quest page, giver, turn-in, objective, reward and coordinates all come from Wowhead Forever DB data.
- **beta-player-report**: the detail comes from a Wowhead comment by a beta player, dated Sep 20-25 2026.
- **unverified**: no primary source was found.

Coordinates are map percent (x, y) on the zone map named in each entry. Unless stated otherwise, every quest below requires the Undead race and the Paladin class, is Horde-only and is **not sharable**.

---

## Horde paladin trainers (confirmed-datamined, Wowhead NPC data, tag "Paladin Trainer")

| Trainer | Location | Coords |
|---|---|---|
| Aramis Hammerhand (npc 244808) | Deathknell church, Tirisfal Glades | 31.0, 66.2 |
| Shari Stilwell (npc 246152) | Brill, Tirisfal Glades | 60.2, 52.6 |
| Hilda the Breaker (npc 246389) | Bandarion Keep (Tyr's Watch), Tirisfal Glades | 22.0, 47.2 |
| Garen Largo (npc 260093) | Undercity (War Quarter area) | 47.4, 15.0 |
| Alodan the Hopeful (npc 246344) | Thunder Bluff (Tauren paladins, listed for completeness) | 25.4, 14.6 |

The Bandarion Keep hub sits at about 22, 45 in Tirisfal Glades. It is on the bluffs northwest of Solliden Farmstead, in the new "Whispering Wood" area, and the order based there is called **Tyr's Watch**. Its leader is Danitha Morr at 22.0, 44.6.

---

## Levels 1-4: Deathknell

### 1. A Difficult Path (quest 98601), level 1, requires level 1
- **Giver:** Shadow Priest Sarvis, Deathknell, Tirisfal Glades, 30.8, 66.2. The giver is an existing Classic NPC. He hands you the scroll when you return from his first quest (verify which prerequisite unlocks it).
- **Objective:** Read the Consecrated Scroll (provided, item 282423) and speak to Aramis Hammerhand in the Deathknell church.
- **Turn-in:** Aramis Hammerhand, 31.0, 66.2.
- **Reward:** 40 XP and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=98601
- Tag: **confirmed-datamined**

### 2. Rediscovering the Light (quest 90902), level 2, requires level 2
- **Giver:** Aramis Hammerhand, Deathknell church, 31.0, 66.2.
- **Objective:** Heal 5 Injured Deathguard with Holy Light. They are around the church at about 30-32.4, 62.2-66.6, with the densest group near 31.6, 64.8.
- **Turn-in:** Aramis Hammerhand, 31.0, 66.2.
- **Reward:** You learn **Holy Light** (spell 635). Also 85 XP and 50 Undercity reputation.
- Note: Holy Light is supposed to damage you while you do this quest. The developer Josh Greenfield (@AggrendWoW) said on X that this was bugged in the first beta build, and Icy Veins reported that it will be fixed in the next build.
- Note: Wowhead's "series" box lists "A Second Home" as step 1 before this quest. That is almost certainly a Wowhead chain-data quirk, because A Second Home is a level 11 quest (verify).
- Source: https://www.wowhead.com/forever/quest=90902
- Tag: **confirmed-datamined**

### 3. A Light in the Darkness (quest 98389), level 4, requires level 2
- This quest is **not class-restricted**. It is open to any Horde character and **sharable**, but its giver is the paladin trainer.
- **Giver:** Aramis Hammerhand, 31.0, 66.2.
- **Objective:** Free 6 Webbed Forsaken in Night's Web Hollow, the spider cave northwest of Deathknell. They are spread through the cave, centred around 26.6, 59.4. Each one you free spawns a Forsaken Adventurer who thanks you and runs off.
- **Turn-in:** Aramis Hammerhand.
- **Reward:** 355 XP and 100 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=98389 (beta-player comment dated 2026-09-25 confirms the mechanics)
- Tag: **confirmed-datamined**

### 4. Coming to Terms (quest 91208), level 4, requires level 4
- **Giver:** Aramis Hammerhand, 31.0, 66.2.
- **Objective:** Find the Frightened Paladin in the hills directly west of the chapel, at **27.6, 63.8**. A player comment puts him at 27.72, 63.83, just south of the bat cave. Interact to "Offer aid to the Frightened Paladin".
- **Turn-in:** Aramis Hammerhand.
- **Reward:** 180 XP and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=91208
- Tag: **confirmed-datamined**

### 5. Continue Your Training (quest 91209), level 4, requires level 4
- **Giver:** Aramis Hammerhand, 31.0, 66.2. This quest follows Coming to Terms.
- **Objective:** Follow the road east to Brill and report to Shari Stilwell.
- **Turn-in:** Shari Stilwell, Brill, 60.2, 52.6. She is the Brill paladin trainer.
- **Reward:** 90 XP.
- Source: https://www.wowhead.com/forever/quest=91209
- Tag: **confirmed-datamined**

There are no class-restricted quests between levels 5 and 7. The general Forsaken route continues through Brill.

---

## Levels 8-12: Bandarion Keep (Tyr's Watch)

### 6. A Second Home (quest 91282), level 11, requires level 8
- **Giver:** Shari Stilwell, Brill, 60.2, 52.6.
- **Objective:** Find Bandarion Keep and report to Breton Samuels. The keep is at Northface Rock, on the bluffs northwest of Solliden Farmstead.
- **Turn-in:** Breton Samuels, Bandarion Keep, **21.8, 45.2**.
- **Reward:** 220 XP and 1 silver.
- Source: https://www.wowhead.com/forever/quest=91282
- Tag: **confirmed-datamined**

### 7. Murlocs at the Gates (quest 91285), level 11, requires level 7
- **Giver:** Breton Samuels, 21.8, 45.2.
- **Objective:** Kill 8 Vile Fin Attackers and 8 Vile Fin Seers. They are on the bluffs along the road east of the keep and in the camps around the lake to the west. The main concentration is at about **17-18, 57-58**.
- **Turn-in:** Breton Samuels.
- **Reward:** Choose one:
  - Skullthumper: 1H mace, item level 13, 12-23 damage, 2.50 speed.
  - Driftwood Smasher: 2H mace, item level 13, 23-36 damage, 3.30 speed, +2 Stamina.

  Also 880 XP, 4 silver and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=91285
- Tag: **confirmed-datamined**

### 8. Touring the Grounds (quest 91294), level 11, requires level 8
- **Giver:** Breton Samuels. This quest follows Murlocs at the Gates.
- **Objective:** Speak with four residents of the keep:
  - Hilda the Breaker, 22.0, 47.2
  - Jorin Croge, 22.6, 44.8
  - Ander Solliden, about 25.4, 50.4 (he moves between spots)
  - Danitha Morr, 22.0, 44.6
- **Turn-in:** Danitha Morr, 22.0, 44.6.
- **Reward:** 440 XP, 2 silver and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=91294
- Tag: **confirmed-datamined**

### 9. Making Repairs (quest 91316), level 11, requires level 8
- **Giver:** Jorin Croge, 22.6, 44.8.
- **Objective:** Collect 12 Sturdy Lumber. It looks like stacks of wooden beams on the ground inside the Shadowvale crypt or root cellar, southwest of the keep. Players report the entrance at **12.9, 65.9**, in a burned house.
- **Turn-in:** Jorin Croge.
- **Reward:** Salvaged Wooden Tower Shield (item level 14 shield, 311 armor, 5 block). Also 880 XP, 4 silver and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=91316. The entrance coordinates are a **beta-player-report**.
- Tag: **confirmed-datamined** (entrance coordinates: beta-player-report)

### 10. The Tarnished (quest 91317), level 12, requires level 9
- **Giver:** Danitha Morr, 22.0, 44.6.
- **Objective:** Kill 8 Tarnished Drudges and 6 Tarnished Zealots, and collect the head of Commander Rudolph Gelhardt. They are all at Shadowvale, about **11.6, 64**.
- **Turn-in:** Danitha Morr.
- **Reward:** 910 XP, 5 silver and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=91317
- Tag: **confirmed-datamined**

### 11. A Token of Good Faith (quest 95803), level 12, requires level 9
- **Giver:** Danitha Morr. This quest follows The Tarnished.
- **Objective:** Take Rudolph Gelhardt's Head (provided) to Sylvanas in Undercity.
- **Turn-in:** Lady Sylvanas Windrunner, Undercity Royal Quarter, **57.8, 91.8**.
- **Reward:** 910 XP, 5 silver and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=95803
- Tag: **confirmed-datamined**

### 12-18. "A Lesson in Divinity" chain, level 12, requires level 12
This seven-step chain replaces the Alliance "Redemption" quest. All seven steps share the same name.

| Step | Quest ID | Giver (coords) | Objective (coords) | Turn-in (coords) | Reward |
|---|---|---|---|---|---|
| 12a | 94427 | Danitha Morr, Tirisfal Glades (22.0, 44.6) | Go to the Undercity Trade Quarter and speak to Tanis Alderwood | Tanis Alderwood, Undercity (**65.6, 37.8**) | 225 XP |
| 12b | 94434 | Tanis Alderwood (65.6, 37.8) | Bring 10 Linen Cloth | Tanis Alderwood | 910 XP, 50 Undercity reputation |
| 12c | 94435 | Tanis Alderwood | Return to Danitha Morr | Danitha Morr (22.0, 44.6) | **Symbol of Life** (item 6866), 225 XP |
| 12d | 94436 | Danitha Morr | Speak with Deathguard Billmuth downstairs in the keep | Deathguard Billmuth (22.0, 44.6, downstairs) | 90 XP |
| 12e | 94438 | Deathguard Billmuth | Use the Symbol of Life to resurrect Deathguard Falgan at Venomweb Vale in eastern Tirisfal (**86.6, 47.6**) | Deathguard Falgan (86.6, 47.6) | 910 XP, 75 Undercity reputation |
| 12f | 94440 | Deathguard Falgan (86.6, 47.6) | Get the Scarlet Crusade Attack Plans from Scarlet Crusaders at Venomweb Vale (verify exact drop mobs; Wowhead lists Scarlet Zealot and Scarlet Friar as sources) | Deathguard Billmuth, Bandarion Keep (22.0, 44.6) | 680 XP, 5 silver |
| 12g | 94441 | Deathguard Billmuth | Speak with Danitha Morr in the keep | Danitha Morr (22.0, 44.6) | You learn **Redemption** (spell 7328). Also 225 XP and 100 Undercity reputation |

- If you lose the Symbol of Life, Danitha Morr gives you a replacement.
- Sources: https://www.wowhead.com/forever/quest=94427, =94434, =94435, =94436, =94438, =94440, =94441
- Tag: **confirmed-datamined**

---

## Levels 18-26: Silverpine, the Earthen Ring, and the Moonsilver Blade / Wolfsbane

This chain fills the role of the Alliance "Verigan's Fist" weapon quest at level 20. **No Horde equivalent of "Sense Undead" was found.**

### 19. Diplomatic Incident (quest 91858), level 22, requires level 18
- **Giver:** Danitha Morr, Bandarion Keep, 22.0, 44.6.
- **Objective:** Go to The Sepulcher in Silverpine and speak with Trevan Rol about the missing Earthen Ring travellers.
- **Turn-in:** Trevan Rol, The Sepulcher, Silverpine Forest, **43.4, 41.0**. A player reports he is in the basement.
- **Reward:** 435 XP, 3 silver 50 copper and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=91858
- Tag: **confirmed-datamined**

### 20. A Curious Pair (quest 91859), level 22
- **Giver:** Trevan Rol, 43.4, 41.0.
- **Objective:** Speak with Deathguard Baldren near the entrance to the Sepulcher.
- **Turn-in:** Deathguard Baldren, **45.8, 41.8**.
- **Reward:** 435 XP, 3 silver 50 copper and 50 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=91859
- Tag: **confirmed-datamined**

### 21. A Grim Fate (quest 91860), level 22
- **Giver:** Deathguard Baldren, 45.8, 41.8.
- **Objective:** Investigate Fenris Isle to the east and find the Tauren corpse on a pyre on the shore.
- **Turn-in:** the pyre object (object 566037) on Fenris Isle. Wowhead has no coordinates for it; it is on the Fenris Isle shoreline (verify).
- **Reward:** 435 XP and 3 silver 50 copper.
- Source: https://www.wowhead.com/forever/quest=91860
- Tag: **confirmed-datamined** (pyre location: unverified)

### 22. Into Fenris Keep (quest 91861), level 22
- **Giver:** the same pyre object, 566037.
- **Objective:** Search Fenris Keep for the missing party member. Players report she is **in a cage in the basement of the Fenris Keep castle**.
- **Turn-in:** Lumina Windsinger, Fenris Keep, about 65.6, 23.2. She has an escort path, so several spawn points exist.
- **Reward:** 435 XP.
- Source: https://www.wowhead.com/forever/quest=91861
- Tag: **confirmed-datamined** (basement detail: beta-player-report)

### 23. Lumina Windsinger (quest 91862), level 22
- **Giver:** Lumina Windsinger, 65.6, 23.2.
- **Objective:** Get the Fenris Isle Key from Rot Hide gnolls and use it to free her. Wowhead lists the gnolls at about 65-68, 23-26 (Rot Hide Savage, Raging Rot Hide, Rot Hide Bruiser and Snarlmane). A player got the key from the first gnoll killed.
- **Turn-in:** Lumina Windsinger.
- **Reward:** 1750 XP, 14 silver, 50 Undercity reputation and 100 Earthen Ring reputation.
- Note: if she is not in the cage, another player is escorting her and you have to wait for her to respawn.
- Source: https://www.wowhead.com/forever/quest=91862
- Tag: **confirmed-datamined**

### 24. The Windshaper's Wrath (quest 96204), level 22
- **Giver:** Lumina Windsinger.
- **Objective:** Escort her out of Fenris Keep. She walks through the courtyard to the dock, then goes back to the Sepulcher on her own.
- **Turn-in:** Lumina Windsinger at the Sepulcher, **43.2, 40.8**.
- **Reward:** 1750 XP, 14 silver, 50 Undercity reputation and 100 Earthen Ring reputation.
- Lumina is a shen'dorei of the "Windshaper Skyborne", tied to the new Skyborne race. See skyborne.md.
- Source: https://www.wowhead.com/forever/quest=96204
- Tag: **confirmed-datamined**

### 25. The Debt (quest 95034), level 24, requires level 18
- **Giver:** Lumina Windsinger, Sepulcher, 43.2, 40.8.
- **Objective:** Speak with her and click through her dialogue.
- **Turn-in:** Lumina Windsinger.
- **Reward:** 195 XP.
- Source: https://www.wowhead.com/forever/quest=95034
- Tag: **confirmed-datamined**

### 26. A Moon-Kissed Blade (quest 95036), level 25, requires level 20. Type: **Dungeon**
- **Giver:** Lumina Windsinger, 43.2, 40.8.
- **Objective:** Get Trevan's Weapon Notes from Trevan Rol, then bring him four items:
  - **Whitestone Oak Lumber** (item 6994): drops from Goblin Woodcarvers in **The Deadmines**, in Sneed's room. Players reported getting it on the first kill. This is the same item used in the Alliance Test of Righteousness quest.
  - **Enchanted Silver Ingot** (item 267361): lies on a sparkling table next to Arugal at the end of **Shadowfang Keep** (beta-player-report).
  - **Purified Kor Gem** (item 272448): the reward from "Seeking the Kor Gem" (entry 27 below).
  - Trevan's Weapon Notes.
- **Turn-in:** Trevan Rol, 43.4, 41.0.
- **Reward:** 1000 XP, 100 Undercity reputation and 100 Earthen Ring reputation.
- Source: https://www.wowhead.com/forever/quest=95036. The material sources come from Wowhead comments dated 2026-09-20 and 2026-09-22. The Deadmines drop is also confirmed by the Wowhead item 6994 drop table.
- Tag: **confirmed-datamined** (material locations: beta-player-report)

### 27. Seeking the Kor Gem (quest 95042), level 25, requires level 20. Type: **Elite**
- This quest is paladin-only but **not race-restricted**, and it is **sharable**.
- **Giver:** Ulric Frostveil, Zoram Strand, Ashenvale, **11.8, 34.4**.
- **Objective:** Bring a Corrupted Kor Gem. It drops from Blackfathom Tide Priestesses and Oracles, the naga casters outside the Blackfathom Deeps instance at about **13-16.6, 11-13**.
- **Turn-in:** Ulric Frostveil.
- **Reward:** Purified Kor Gem, 2000 XP and 75 Undercity reputation.
- Source: https://www.wowhead.com/forever/quest=95042
- Tag: **confirmed-datamined**

### 28. An Underrated Talent (quest 95111), level 25, requires level 20
- **Giver:** Trevan Rol, 43.4, 41.0. This quest follows A Moon-Kissed Blade.
- **Objective:** Take the Bundle of Blacksmithing Materials (provided) to Ott in Tarren Mill.
- **Turn-in:** Ott, Tarren Mill, Hillsbrad Foothills, **60.4, 26.0**. Players describe him as next to a Horde wagon on the southeast side of Tarren Mill.
- **Reward:** 1000 XP.
- Source: https://www.wowhead.com/forever/quest=95111
- Tag: **confirmed-datamined**

### 29. Ott's Masterwork (quest 95125), level 25
- **Giver:** Ott, 60.4, 26.0.
- **Objective:** Watch Ott forge the blade, which takes about 30 seconds.
- **Turn-in:** Ott.
- **Reward:** 1000 XP and 50 Orgrimmar reputation.
- Source: https://www.wowhead.com/forever/quest=95125
- Tag: **confirmed-datamined**

### 30. The Moonsilver Blade (quest 95126), level 25
- **Giver:** Ott, 60.4, 26.0.
- **Objective:** Bring Ott's Masterwork to Trevan Rol.
- **Turn-in:** Trevan Rol, Sepulcher, 43.4, 41.0.
- **Reward:** **Moonsilver Blade**, a 2H sword:
  - Item level 31, 57-86 damage, 3.40 speed, +7 Stamina, +7 Intellect, Paladin only.
  - Chance on hit: sears certain enchanted targets, which then take extra holy damage.

  Also 1000 XP.
- Source: https://www.wowhead.com/forever/quest=95126
- Tag: **confirmed-datamined**

### 31. Old Fire-Eye (quest 95140), level 26, requires level 20. Type: **Elite**
- **Giver:** Lumina Windsinger, Sepulcher, 43.2, 40.8.
- **Objective:** Equip the Moonsilver Blade and kill Old Fire-Eye, an elite worgen of about level 25. Wowhead places him at **49.6, 87.2**, near the Greymane Wall / Gilneas gate in south Silverpine. He has a purple shield aura, and your first melee hit with the Moonsilver Blade breaks it.
- **Turn-in:** Lumina Windsinger.
- **Reward:** **Wolfsbane**, a 2H sword:
  - Item level 31, 69-105 damage, 3.40 speed, +9 Stamina, +10 Intellect, Paladin only.
  - Chance on hit: 39-59 Holystorm damage, tripled against wolves and worgen.

  Also 2650 XP, 150 Undercity reputation, 150 Earthen Ring reputation and 75 Orgrimmar reputation.
- Tip from a beta player: train 2H Swords first from Weapon Master Archibald in the Undercity War Quarter (about 57.1, 32.5). A group of 2 or more is recommended.
- Source: https://www.wowhead.com/forever/quest=95140 (tips: beta-player-report)
- Tag: **confirmed-datamined**

### Beyond level 30
Nothing is datamined yet for levels 27-60. Blizzard has announced a **level 60 epic charger quest** for Forsaken Paladins themed around Retribution, while the Alliance version is themed around Redemption. No quest names, steps or NPCs are public.
- Sources: Warcraft Tavern, lfcarry, wowguide.net
- Tag: **unverified**

---

## Suggested order for the addon route
1. At levels 1-4 in Deathknell, do A Difficult Path, Rediscovering the Light, A Light in the Darkness, Coming to Terms, then Continue Your Training to Brill.
2. At level 8 or higher, Shari Stilwell in Brill gives A Second Home.
3. At the keep, do Murlocs at the Gates, then Touring the Grounds, then Making Repairs and The Tarnished. Shadowvale is shared with the optional hub quests.
4. Then do A Token of Good Faith, which takes you to the Undercity.
5. At level 12, do A Lesson in Divinity parts a-g. Part a goes to Undercity and part e goes to Venomweb Vale (86.6, 47.6). Part g teaches Redemption.
6. At level 18 or higher, do Diplomatic Incident through The Windshaper's Wrath in Silverpine, then The Debt.
7. At level 20-26, do A Moon-Kissed Blade. It needs Deadmines, Shadowfang Keep and Seeking the Kor Gem at Blackfathom Deeps. Then do An Underrated Talent, Ott's Masterwork, The Moonsilver Blade and Old Fire-Eye.

The exact point where the Silverpine chain becomes available (level 18 plus completion of Lesson in Divinity?) was not checked in game (verify).

## Optional hub quests at or near Bandarion Keep (any Horde character, not class-locked; confirmed-datamined)

| Quest (ID) | Level | Giver (coords) | Summary |
|---|---|---|---|
| As Above, So Below (99152) | 10 | Hilda the Breaker (22.0, 47.2) | Collect 6 Faintly Glowing Bones |
| The One That Got Away (99153) | 10 | Ephram Barbaro (20.2, 46.4) | Find the Glowing Crystal Fragment in the Shadowvale crypt (about 9.7, 69.4; entrance 13, 65) |
| That Shadowvale Green Elixir (95314) | 10 | Carolai Anise, Brill (59.4, 52.2) | Collect 8 Bottles of Whispering Elixir in the Shadowvale crypt |
| Whispering Horror Residue (95328) | 10 | Item drop from an elite in the Shadowvale crypt | Deliver it to Father Lankester in Undercity (49.6, 15.6) |
| The Argent Emissary (96895) → The Cult of the Damned (96897) / Remnants of War (96898) → Bandarion Keep (96899) → A Righteous Cause (96896) → Leonid's Letter (98545) | 13 | Deathguard Terrence, Brill (61.4, 53.4) → Hadric Harlson (65.8, 61.0) → Leonid Barthalomew the Revered at the keep (22.0, 44.8) | Argent Dawn chain ending at Glix Xizzix in Undercity (69.8, 47.0) |

## Sources
- Wowhead Forever paladin quest list: https://www.wowhead.com/forever/quests/classes/paladin
- Wowhead Forever quest pages (IDs as listed): https://www.wowhead.com/forever/quest=ID
- Wowhead Forever NPCs: Aramis Hammerhand https://www.wowhead.com/forever/npc=244808 · Shari Stilwell https://www.wowhead.com/forever/npc=246152 · Garen Largo https://www.wowhead.com/forever/npc=260093 · Alodan the Hopeful https://www.wowhead.com/forever/npc=246344
- Wowhead Forever items: Whitestone Oak Lumber https://www.wowhead.com/forever/item=6994 · Wolfsbane https://www.wowhead.com/forever/item=267369 · Moonsilver Blade https://www.wowhead.com/forever/item=268484
- Icy Veins, "The Light Burns Forsaken Paladins - Intro Quest Will Be Updated": https://www.icy-veins.com/wow-forever/news/the-light-burns-forsaken-paladins-intro-quest-will-be-updated/
- Josh Greenfield (@AggrendWoW) on X, about the Holy Light intro-quest bug: https://x.com/AggrendWoW/status/2102796598728360018
- MMOEXP beta write-up: https://www.mmoexp.com/News/wow-forever-beta-game-guide-undead-paladin-quests-holy-strike-campfire-buffs-new-crafting-rewards-more.html
- Warcraft Tavern Undead Paladin overview: https://www.warcrafttavern.com/forever/guides/undead-paladin/
- wowguide.net Forsaken Paladin: https://wowguide.net/en/guides/wow-forever-forsaken-paladin
- lfcarry Undead Paladin guide: https://lfcarry.com/guides/wow-forever-undead-paladin
- YouTube, "Undercity Paladin Trainer Location, WoW Forever Garen Largo Location": https://www.youtube.com/watch?v=ZK3GBoavRpY
