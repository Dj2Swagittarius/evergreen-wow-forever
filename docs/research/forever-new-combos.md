# WoW Forever: new race/class combos, class quests for levels 1-30

Researched 2026-09-26 (beta running since 2026-09-17, level cap 30, client 1.60.1). Undead Paladin is out of scope here because it is covered elsewhere.
Confidence tags:
- **confirmed-datamined**: the quest or NPC exists in Wowhead's Forever database (wowhead.com/forever).
- **beta-player-report**: a Forever-specific guide written from beta or demo play (Warcraft Tavern, ForeverWisp).
- **unverified**: SEO or aggregator content, Classic-baseline assumptions, or conflicting data.

No Turtle WoW or private-server sources were used.

Wowhead's Forever list pages (`/forever/quests/classes/...`) and zone pages render their data with JavaScript. WebFetch and curl get only the page shell, and curl gets a CloudFront 403. The Chrome extension was not connected. Many quest IDs, levels and coordinates therefore could not be pulled from the DB, so the per-quest pages below were read one by one.

---

## 0. Correction: the six combos (no Night Elf Mage)

Blizzard's official announcement and the Deep Dive list these six new combos:
**Human Hunter, Gnome Priest, Dwarf Shaman, Orc Mage, Troll Warlock, Undead Paladin.**

- Blizzard (worldofwarcraft.blizzard.com/news/24304075) says the new combos are "Orc Mages, Troll Warlocks, Undead Paladins, Human Hunters, Gnome Priests, Dwarf Shamans, and the debut of the Skyborne."
- LFCarry, wow.gg, MrGM on X, and Icy Veins (title only, because the page returned 403) all give the same six.
- **Night Elf Mage is NOT a Forever combo.** No official or datamined source mentions it. It was a Cataclysm addition. The brief's list was wrong, and the sixth combo is really two: **Orc Mage** and **Troll Warlock** (plus Undead Paladin, which is handled elsewhere).
- The Night Elf Mage section below explains this and does not invent any quests.

---

## 1. Human Hunter

### Trainer
| Item | Data | Confidence |
|---|---|---|
| Northshire hunter trainer | **Not published for Forever.** Warcraft Wiki's Ashley Blank (Northshire, "east of the entrance to Northshire Abbey, beside the horse pickets") is a **Cataclysm 4.0.3a** NPC, so it is not evidence for Forever. | unverified (verify) |
| Goldshire / Stormwind | games.gg (Elwynn guide, 2026-09-19) says: "The WoW Forever human hunter is new, has no classic quest data in this zone, and should check the Goldshire trainers in game." Beastmaster.io's Forever trainer roster lists only the Stormwind hunter trainers Einris Brightspear, Ulfir Ironbeard and Thorfin Stoneshield (Dwarven District, no coords, marked "preliminary"). | beta-player-report (roster) / unverified (Goldshire) |

### Level 10 taming chain ("Taming the Beast")
- **Nothing is published for a Human (Elwynn) version.** Search turned up no Forever quest ID, rod, beast list or turn-in NPC for humans.
- The Forever DB does contain the Orc/Troll version, quest 6083 "Taming the Beast". It is given by Thotar at Razor Hill and asks you to tame a Surf Crawler; it is part 3 of a 5-quest chain that starts with "The Hunter's Path". That proves the Classic taming framework is in Forever, but not what humans get. **Tag: confirmed-datamined (Horde only).**
- One aggregator snippet names "Bertrand Hearn, Eastvale Logging Camp, tame a Timber Wolf west of Goldshire". Its source is a Classic-era guide (noobtoboss), and there were no human hunters in Classic. **Treat it as unverified and probably wrong. Do not use it.**
- **Generic path until verified:** start at the Northshire or Goldshire hunter trainer (check in game). At level 10 the trainer should start a 3-rod taming chain on low-level Elwynn beasts, followed by a final "Training the Beast"-style turn-in at the Stormwind hunter trainers in the Dwarven District. The Classic Alliance version sends you to the Ironforge Hall of Arms. **Everything in this bullet is (verify).**
- Beta bug report (Blizzard forums, "Unable to train pet"): pets tamed from the new zone (Vuldren) can't learn skills after the pet quest line. Wolves work fine.

## 2. Dwarf Shaman

The source for all of this section, unless noted, is Warcraft Tavern's *Dwarf Shaman Totem Quests* (Forever guide). ForeverWisp (beta, updated Sep 23) independently confirms the NPC names and most coords. The NPCs Teo Hammerstorm (classic/Forever npc 239189) and Norric Lochthane (forever npc 258043) exist in Wowhead's DB, but their Forever pages give no coords.

### Trainer
- **Teo Hammerstorm**, Shaman Trainer, inside **Anvilmar, Coldridge Valley (Dun Morogh 28.8, 66.2)**. Both sources give the same location. **beta-player-report + NPC confirmed-datamined.**
- Kharanos and Ironforge shaman trainers: not published (verify in game).

### Call of Earth, level 4 (Forever quest 1521 exists in DB)
| # | Giver | Objective | Turn-in | Reward |
|---|---|---|---|---|
| 1 | Teo Hammerstorm, Anvilmar (28.8, 66.2) | Collect 2 Iceclaw Bear Pendants from Frostmane Troll Whelps (~27.3, 79.6) | Teo | Earth Sapta / next step |
| 2 | Teo | Take the path from 25.8, 69.3 and drink Earth Sapta at the Spirit Stone (25.0, 62.4). Talk to Minor Manifestation of Earth. | Minor Manifestation of Earth | Rough Quartz |
| 3 | Minor Manifestation of Earth | Bring Rough Quartz back to Teo | Teo Hammerstorm | **Earth Totem (item 5175) + Stoneskin Totem (spell 8071)** |

Confidence: beta-player-report. Quest 1521 "Call of Earth" is listed on wowhead.com/forever, and the Forever DB lists Stoneskin Totem + Earth Totem as its reward.

### Call of Fire, level 10
| # | Giver | Objective | Turn-in | Reward |
|---|---|---|---|---|
| 1 | Any shaman trainer | Go to **Bruegs Kindleborn** in a Dun Morogh mountain cave. Warcraft Tavern gives the path start as **86.7, 47.0**; ForeverWisp puts him at about **87.6, 43.6** (verify) | Bruegs | Torch of Dormant Flame |
| 2 | Bruegs | Take the torch through the southern tunnel to **Braldir Ashmantle, Loch Modan (32.0, 66.3)** | Braldir | - |
| 3 | Braldir Ashmantle | Get Fire Tar from Tunnel Rat Geomancers in Silver Stream Mine (35.6, 20.2), and a Reagent Pouch from Stonesplinter Seers in Stonesplinter Valley (31.0, 77.4) | Braldir | Fire Sapta |
| 4 | Braldir | Drink Fire Sapta at the Fire Spirit Stone (31.9, 64.5), kill Minor Manifestation of Fire, then use the Brazier of Dormant Flame | - | Torch of Eternal Flame |
| 5 | - | Return to Bruegs Kindleborn, Dun Morogh | Bruegs | **Fire Totem (item 5176) + Searing Totem (spell 3599)** |

Confidence: beta-player-report.

### Call of Water, level 20
| # | Giver | Objective | Turn-in | Reward |
|---|---|---|---|---|
| 1 | Shaman trainer | Go to **Norric Lochthane, Loch Modan (41.9, 19.0)** | Norric | - |
| 2 | Norric | Go to **Hervdana Saegrund**, in the Wetlands cave behind a waterfall (65.7, 76.4). Fill the Unfilled Brown Waterskin at the waterfall outside. | Hervdana | Unfilled Red Waterskin |
| 3 | Hervdana | Fill it at Stonewatch Falls, Redridge (73.7, 61.6) | Hervdana | Unfilled Blue Waterskin |
| 4 | Hervdana | Fill it at the lake near Astranaar, Ashenvale (37.0, 51.6) | Hervdana | Water Sapta |
| 5 | Norric | Drink Water Sapta at the Forgotten Shrine, Westfall (47.5, 60.4), kill Corrupt Minor Manifestation of Water, then use the shrine | - | Corrupt Manifestation's Bracers |
| 6 | - | Wait for Minor Manifestation of Water in the pond, then talk to it | - | Shard of Water |
| 7 | - | Return to Norric Lochthane, Loch Modan | Norric | **Water Totem (item 5177) + Healing Stream Totem (spell 5394)** |

Confidence: beta-player-report. The route crosses to Kalimdor (Ashenvale), so check it against the in-game quest text.

### Call of Air, level 30
- **Not published.** Warcraft Tavern marks it "coming soon." Level 30 is the beta cap, so it may not be testable yet. (verify)

## 3. Gnome Priest

### Trainer
- The Gnome priest trainer's name and coords in Coldridge Valley, Kharanos or Ironforge are **not published** for Forever (verify in game). The racial-spell quests below point to **High Priestess Mims, Hall of Mysteries (Mystic Ward), Ironforge**. Her coords are not on Wowhead's Forever pages (verify).

### Racial class-spell quests (confirmed in Wowhead Forever DB)
There are several versions of each quest, one per starting point. Each is picked up from a priest trainer (race-generic text says "young <race>") and ends at Mims.

| Quest | Level | Forever quest IDs seen | Giver / text | Turn-in | Reward | Confidence |
|---|---|---|---|---|---|---|
| **Confounding Flash** | 10 | 94821, 94823, 94824, 94825, 94826 | Priest trainers. The text says a priest came looking for you and you should "return to the Hall of Mysteries in Ironforge" (one version mentions Stormwind, one Darnassus) | **High Priestess Mims**, Hall of Mysteries, Ironforge | Spell **Confounding Flash** (confuses up to 5 enemies within 8 yd for 3 s, 2 min CD) | confirmed-datamined |
| **Contingency Plan** | 20 | 94818, 94819, 94820 | Same pattern: "Speak to High Priestess Mims in Ironforge" (Mystic Ward) | High Priestess Mims | Spell **Contingency Plan** (spell 1277457: 15 s Holy ward; when the target drops below 35% HP it gets an absorb shield and a heal over time) | confirmed-datamined |

- The levels (10 and 20) come from Wowhead search snippets. The WebFetch page reads did not show levels (verify). ForeverWisp says "live eligibility and spell rewards remain under review."
- The generic priest quests in levels 1-30 (Classic baseline) presumably also apply. Nothing Forever-specific is published for gnomes.

## 4. Night Elf Mage (not a Forever combo)

- It is not in Blizzard's list and not in the Deep Dive. Every search came back empty for it: Wowhead Forever, WGE's Forever mage-quest guide ("zero mentions of Night Elf mages"), wow.gg and LFCarry.
- **Recommendation:** do not add a Night Elf Mage route. If it ever appears in game, the Shadowglen, Dolanaar and Darnassus mage trainers would have to be added from scratch. There is no data now.

## 5. Orc Mage (new combo)

- **Trainer:** **Mai'ah**, Mage Trainer, in the Den, Valley of Trials, Durotar. That is the Classic Troll mage trainer. The search snippet was aggregator-sourced, so this is **unverified** and the coords are not published (verify). In Classic, Razor Hill had no mage trainer, and the next stop was Orgrimmar (Darkbriar Lodge, Valley of Spirits).
- **Class quests 1-30:** **nothing Forever-specific is published.** WGE (2026-09-16) says: "Orc mages have no Classic precedent here, so ask the Orgrimmar trainer which errand Forever assigns you." It also expects a level 10 trainer errand for a starter orb or staff, which is **unverified**.
- No Orc-specific racial class-spell quest (like the Gnome Priest ones) turned up.
- **Generic path:** use the Troll mage route from Valley of Trials: Mai'ah, then the Orgrimmar mage trainers. (verify)

## 6. Troll Warlock (new combo)

- **Trainer:** **Nartok**, Warlock Trainer, at the back of the Den, Valley of Trials. That is the Classic Orc warlock trainer, so **unverified** for Forever; no coords published.
- **Class quests 1-30:** **nothing Forever-specific is published.** WGE (2026-09-16) states: "Blizzard has not published Forever changes to any Warlock class chain, so every step... is the Classic-era baseline." Its Classic-baseline chain is:
  - Imp: "Vile Familiars" (WGE says it comes from Ruzan, Valley of Trials; another snippet says Zureetha Fargaze). **unverified and conflicting**
  - Level 10 Voidwalker: Ophek (Razor Hill) → "Gan'rul's Summons" → "Creature of the Void" → "The Binding" (Skull Rock). **unverified (Classic baseline)**
  - Level 20 Succubus: Gan'rul Bloodeye (Cleft of Shadows) → "Devourer of Souls", "Blind Cazul", "News of Dogran", "Ken'zigla's Draught", "Dogran's Captivity" → Summon Succubus. **unverified (Classic baseline)**
- **Generic path:** the Orc warlock route (Valley of Trials → Razor Hill → Orgrimmar Cleft of Shadows). Check it against a beta character.

---

## Open items to verify in game
1. Human Hunter: trainer names and coords in Northshire and Goldshire, the level 10 taming chain (rods, beasts, where), and the final turn-in NPC.
2. Gnome Priest: starter trainer name and coords, Mims' coords in the Mystic Ward, and the exact level requirements.
3. Dwarf Shaman: Bruegs Kindleborn's coords (86.7,47.0 vs 87.6,43.6), and Call of Air (level 30).
4. Orc Mage / Troll Warlock: whether Mai'ah and Nartok train the new races in Valley of Trials, and any Forever-specific class quests.
5. Wowhead's `/forever/quests/classes/*` listings, once they can be read with a real browser, to catch any quest IDs this research missed.

## Sources
- Blizzard: Create the Hero You Want to Be in WoW: Forever. https://worldofwarcraft.blizzard.com/en-us/news/24304075/create-the-hero-you-want-to-be-in-world-of-warcraft-forever
- Icy Veins: All New Race and Class Combos (official), title only because of the 403. https://www.icy-veins.com/wow-forever/news/all-new-race-and-class-combos-and-racial-abilities-in-wow-forever-official/
- MrGM on X: https://x.com/MrGMYT/status/2098940588762812425
- LFCarry, Forever classes: https://lfcarry.com/guides/wow-forever-classes
- wow.gg, class combinations: https://wow.gg/guides/wow-forever-class-combinations
- Wowhead Forever guide page (content not readable): https://www.wowhead.com/forever/guide/new-race-class-combinations
- Warcraft Tavern, Dwarf Shaman Totem Quests: https://www.warcrafttavern.com/forever/guides/dwarf-shaman-totem-quests/
- ForeverWisp, Dwarf/Gnome 1-20 (beta, Sep 23): https://www.foreverwisp.com/guides/wow-forever-dwarf-gnome-leveling-guide
- Wowhead Forever, Call of Earth: https://www.wowhead.com/forever/quest=1521/call-of-earth
- Wowhead Forever, Teo Hammerstorm: https://www.wowhead.com/forever/npc=239189/teo-hammerstorm
- Wowhead Forever, Norric Lochthane: https://www.wowhead.com/forever/npc=258043/norric-lochthane
- Wowhead Forever, Confounding Flash: https://www.wowhead.com/forever/quest=94825/confounding-flash (also 94821, 94823, 94824, 94826)
- Wowhead Forever, Contingency Plan: https://www.wowhead.com/forever/quest=94819/contingency-plan (also 94818, 94820)
- Wowhead Forever, Contingency Plan spell: https://www.wowhead.com/forever/spell=1277457/contingency-plan
- Warcraft Tavern, Priest racials (2026-09-12): https://www.warcrafttavern.com/forever/news/priest-racials-in-world-of-warcraft-forever-fear-ward-is-baseline/
- Wowhead Forever, Taming the Beast (Horde): https://www.wowhead.com/forever/quest=6083/taming-the-beast
- games.gg, Elwynn Forest (Forever): https://games.gg/world-of-warcraft/guides/wow-forever-elwynn-forest/
- Beastmaster.io, Forever trainers: https://beastmaster.io/forever/trainers
- Blizzard forums, Unable to train pet (beta): https://us.forums.blizzard.com/en/wow/t/unable-to-train-pet/2353618
- WGE, Forever Mage class quests: https://worstguidesever.com/wow-forever-mage-class-quests/
- WGE, Forever Warlock class quests: https://worstguidesever.com/wow-forever-warlock-class-quests/
- Warcraft Wiki, Ashley Blank (Cataclysm NPC, not Forever evidence): https://warcraft.wiki.gg/wiki/Ashley_Blank
