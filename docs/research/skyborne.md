# Skyborne (Shen'dorei) — World of Warcraft: Forever research

Compiled 2026-09-19 from public web sources. Forever was announced at BlizzCon on 2026-09-12; the beta opened 2026-09-17 (build 1.60.1) and runs to 2026-10-21; launch is 2026-11-04. Anything below marked **(verify)** comes from a single fan/forum source, a beta datamine, or a speculative guide and should be checked in-client.

Reliability legend used in the notes: **[Official]** Blizzard news/panel, **[DB]** Wowhead Forever database (datamined from the beta client), **[Press]** Wowhead/Icy Veins/Blizzard Watch/Method editorial, **[Wiki]** warcraft.wiki.gg, **[Player]** beta tester forum posts, **[SEO]** boost-site guides (low value; they mostly rephrase the above and admit they have no quest data).

---

## 1. Lore summary

- The Skyborne call themselves the **shen'dorei** ("hidden people"). They are high-elf descendants of the **Highborne of Eldre'Thalas** (Dire Maul). When Prince Tortheldrin began draining his own people / summoning the demon Immol'thar, a secret rebellion led by a figure called **the Shal'nan ("the Veiled One")** sabotaged him and fled west. [Wiki, Icy Veins, Windows Central dev interview (Kris Zierhut)]
- The exiles struck a pact with the **wind spirits / air elementals of Skywall**, who lifted a chunk of land into the sky and anchored it in **Skywall, the Elemental Plane of Air**. That flying landmass is **Zephras Isle**. [Official panel recap, Wiki]
- They lived there ~10,000 years in isolation. The Shal'nan built the **Shrine of the Four Winds** and abdicated in favour of an elected **Council of Elders**. [Wiki] (verify — wiki-only detail)
- Centuries in Skywall changed them physically: lighter/more agile than kaldorei, feathered hair elements, and the **"Sky-Touched Blessing"** — blue skin, now ~3 in 10 of the population. [Wiki] (verify)
- **The crisis:** "several centuries ago" the wind spirits vanished without a trace. The **anchor pylons** that hold Zephras aloft are failing; parts of the isle are falling into ruin/darkness. The isle has also lost contact with other Skyborne provinces on other islands in Skywall (mentioned in finale dialogue). [Official, Player: Eldryth/MMO-Champion]
- Blizzard framing: Zephras Isle "is intended as a surprising but self-contained experience — unexpected, but added with care and restraint." Devs said they want to minimise its footprint; it is not a place you return to for raids/farming. [Official Found Photos panel recap; Player paraphrase]
- Design origin (Windows Central): Tim Jones (Lead Classic Designer) cited the popularity of "pretty" elf races and the BC-era faction-balance swing (60/40 Alliance flipped to 60/40 Horde after Blood Elves); devs first considered Alliance high elves, felt it "didn't feel right," and Chris Metzen pushed them to "think bigger" (verify — Metzen line is wiki-sourced).

### The three internal factions

| Group | Alignment | Description | Leader (verify) |
|---|---|---|---|
| **Windshapers** | Horde | "The Windshapers are shamanistic spiritual leaders of the Skyborne people on Zephras Isle. They honor the elements and seek to gain a better understanding of the nature of the elemental plane to protect the shen'dorei way of life within Skywall." (Wowhead faction 2778 text) They want to find/help the missing elementals and sought the **Earthen Ring** for help. | Ayessa Dawnsinger |
| **High Order** | Alliance | "The High Order are the Skyborne descendants of the Highborne magisters of Eldre'Thalas. Having spent the past 10,000 years in the realm of Skywall, members of the High Order seek to reclaim the ancient arcane knowledge of their forebears." (Wowhead faction 2779 text) They see dependence on elementals as a vulnerability and follow the **Kirin Tor** / arcane path. | Elaadrin Evengale |
| **Al'Aketh** | Enemy cult | Cult of **Al'Akir the Windlord**; believe the elementals left because of lack of faith in him; have seized a large part of the isle. Main antagonist of the starting zone. | High Priestess Lorthuna |

Both Windshapers (2778) and High Order (2779) exist as **reputation factions** in the beta client with the standard 8-rank Classic reputation table (Exalted at 84,000). [DB] There is also a "High Order Pendant" item (281286) and an "Elaadrin Evengale's Silver Coin" junk item. [DB]

---

## 2. Faction choice mechanic

- **Chosen at character creation.** You pick Horde (→ **Windshaper Skyborne**, race ID 96) or Alliance (→ **High Order Skyborne**, race ID 95) on the creation screen. There is **no in-game choice moment** like Pandaren on the Wandering Isle — Blizzard Watch: "your character doesn't start playing and is exposed to the two sides before you make your decision. There will be no neutral Skyborne." [Press, DB]
- Both variants start on Zephras Isle and play through the **same zone**. Beta testers report the questing is essentially identical for both sides through at least level 7; the **setup of the finale is faction-dependent but the climax is shared**. [Player: US forum thread "Skyborne starting zone"; Eldryth/Scyth on MMO-Champion]
- Flavour: Horde leaders "repeatedly mention that you are a GUEST of the Horde, so you're not fully joining the faction." [Player: Eldryth] (verify Alliance equivalent)
- Caveat: Wowhead's race DB pages currently show placeholder data (faction "Darkspear Trolls", leader Vol'jin, start zone Durotar) — unfinished data, not real. [DB]

---

## 3. Classes per faction

| Class | Horde (Windshaper) | Alliance (High Order) |
|---|---|---|
| Warrior | Yes | Yes |
| Hunter | Yes | Yes |
| Rogue | Yes | Yes |
| Druid | Yes | Yes |
| Shaman | **Yes (Horde only)** | No |
| Mage | No | **Yes (Alliance only)** |
| Paladin / Priest / Warlock | No | No |

Confirmed by the Blizzard panel recap, Wowhead race pages (IDs 95/96), Icy Veins and Blizzard Watch. This matches the reported list in the brief exactly.

Notes:
- Skyborne are the first non-night-elf elves who can be **Druids**; Eldryth (beta) wondered how night-elf druid leadership reacts to Highborne magic users — unanswered.
- **Skyborne Druid forms** are unique: sky-blue, feathered/avian hybrids for **Bear, Cat, Travel (bird-like) and Moonkin**; no Tree form shown; Wowhead compares Bear/Cat to Owlcats and notes the models draw on Shadowlands Kyrian assets. [Press: Wowhead druid-forms post]

---

## 4. Racials (with numbers)

Shared by both variants (Wowhead DB tooltips, Method and Icy Veins agree):

| Racial | Type | Tooltip / numbers |
|---|---|---|
| **Walk on Air** | Active | "Glide downward through the air for 10 sec while controlling your direction of travel." Instant, **2 min cooldown**, applies a Slow Fall aura, triggers "Walking on Air". Spell 1259416. Not usable in arena. |
| **Wind Blessed** | Passive | "1% increased melee, ranged, and spellcasting Haste." |
| **Elemental Insight** | Passive | "Damage to Elementals increased by 5%." |

Faction-specific fourth racial:

| Racial | Faction | Tooltip / numbers |
|---|---|---|
| **Read Ley Line** | Alliance (High Order) | "Attempt to tap into the power of a nearby ley line, increasing your Health and Mana regeneration by 100%. Lasts **15 sec** if no ley line is nearby, and **15 min** if one is found." **2 sec cast, 2 min cooldown**, Arcane, triggers "Energized". Spell 1259705. |
| **Skysight** | Horde (Windshaper) | "Attempt to draw power from a convergence of elements and receive its blessing, increasing your movement and mounted movement speeds by 10%. Lasts **30 sec** if no elemental convergence is nearby, and **15 min** if one is found." **0.5 sec cast, 2 min cooldown**, Nature, triggers "Elemental Blessing". Spell 1259686. |

- Blizzard's Deep Dive described the kit as "two active and two passive" per variant. [Press]
- Beta note (Eldryth): the Alliance racial gets its long duration "at special starter zone locations" — i.e. ley-line / convergence spots exist on Zephras Isle; mainland locations are not yet documented. (verify)
- Community take: Skysight's 10% run speed is widely viewed as weaker than a 15-minute 100% regen buff; no official balancing comment. [Wowhead comments]
- Related datamined zone spell: **Blessing of Zephras** (1258510) — "You have been touched by energizing winds. Increases run speed by 40%" for 5 min, breaks on hostile action. Almost certainly a starting-zone travel buff; source NPC/object not yet documented. [DB] (verify)
- Existing-race racial changes shipped alongside (context): Tauren Cultivation gives bonus herbs without Herbalism; Orc Axe Specialization now grants crit; Gnome Expansive Mind raises max resource plus a new "Eureka!" active. [Press: Wowhead]

---

## 5. Zephras Isle — the starting zone

**Basics:** Zone ID 16593, **level 1–12**, territory "Contested", added 1.60.1. A flying island inside Skywall, ringed by snow-capped mountains with **anchor pylons** around the rim. Art: Classic Warcraft shapes with Skywall-inspired architecture — powder-blue recolour of night-elf style buildings, spired city in the clouds, pink-leafed forests, wooden sky-docks with chained stone spires and ships hanging in the mist. Access requires the **Skyborne Heroic Pack ($29.99) or higher** — not included with a plain subscription. Unknown whether non-Skyborne can visit. [Official, DB, Press]

**Quest count:** not published individually; falls inside Blizzard's stated 50–200-per-zone range. [Press]

### Layout (Blizzard Watch hands-on + Warcraft Wiki subzone list)

The zone plays in a **U-shape**: start NW → south/downhill through forest and farmland → back up to the NE.

Complete subzone list (Warcraft Wiki, from the beta map): Bandit Hideout, East Pylon Watchtower, Fairweather Stables, Falaath Village, Gustberry Lowlands, Nightclaw Cavern, Overlook Standing Stones, Rise of Spirits, Rohashi Spires, Ruins of Ban'aethal, Sanctum of Storms, Shadowgale Forest, Shen'dar Highlands, Shen'dar Village, Shriekling Den, Shrine of Akir, Skywall, Thendal Cave, Thendal Grove, Thendal Standing Stones, Thendal Village, Valanaar, **Valanaar Skydocks**, West Pylon Watchtower, Windfield Orchard.

Settlements:

| Place | Role | Notes |
|---|---|---|
| **Thendal Village** | Level 1 start hub (NW corner) | Both factions start here. First quests around Thendal Grove / Thendal Cave / Standing Stones. Players complained the classic "road is too dangerous, take this to the next village" quest between Thendal and Shen'dar is absent. |
| **Shen'dar Village** | Second hub (Shen'dar Highlands) | Turn-in NPC **Constable Aonda** (quest item "Aonda's Written Report" exists in DB). |
| **Falaath Village** | Third minor hub | (verify position/level) |
| **Valanaar** | **Capital / main city, neutral** | Has the **Valanaar Skydocks** — the airship docks used to leave the isle. Players return here to fix the bugged finale quest. |
| **Shrine of Akir** | Minor settlement / cult area | Presumably the Al'Aketh (Al'Akir) stronghold. (verify) |
| **Sanctum of Storms / Rohashi Spires / Ruins of Ban'aethal** | End of zone (NE) | Ruins of Ban'aethal sit at the NE edge, in the eerie blue-fog **Shadowgale Forest**; a sleeping **Altarius** (the elemental dragon boss from Cataclysm's Vortex Pinnacle) is parked there. Rohashi Spires is named for **Rohash**, the Throne of the Four Winds djinn, who appears in the finale. |

Other named things seen: a bridge at the "Shrine of Alar" (Blizzard Watch's spelling; probably = Shrine of Akir), a bandit cave (Bandit Hideout) where a tester found a camping-system scroll that gave a temporary fire-damage weapon buff, and "Living Storms" elementals near the finale.

### Named quests / NPCs known so far (from beta bug threads — no full list exists yet)

- **"Among the Faithful"** — early-zone stealth quest: hide behind a wardrobe/dresser and eavesdrop on cultists; turns in to **Constable Aonda** in Shen'dar Village. Requires a protective buff that drops if you log out. Was **bugged** on 17–18 Sep (wardrobe doesn't spawn); workaround = full game restart / re-layer. [Player: US + EU forums]
- **"A Firm Response"** — late-zone/finale quest: confront the High Order magister **Belathaan Brightwish**; **High Priestess Lorthuna** and two **Living Storms** spawn. Was **bugged** (NPC says one line then stops; NPCs pre-spawned) on 18 Sep; fixed within a day per MMO-Champion testers. Workarounds were layer-hopping via relog or grouping. [Player: US forum]
- Datamined conversation triggers: "Zephras Finale Convo Trigger" (several spells), "Zephras High Order Conversation" (1271575), "DNT High Order" (1263987). [DB]
- **Druid enclave** near the end of the zone fighting the Al'Aketh; has its own **old-school repeatable reputation grind** — quests take you to Friendly, then you farm cultist ears for a repeatable turn-in. [Player: Eldryth] (verify which reputation — likely the Windshapers/High Order factions above)
- Hunters: level-10 pet quest exists (tame three creatures, then get Beast Training — Classic style). Skyborne tame local winged beasts that display as "Fox" family after taming (verify). A bug blocked pet training until you released and re-tamed. [Player]
- Druids: bear form quest is the normal Classic Moonglade chain at level 10–11 (talk to the night elf near the teleport-in, then the bear quest); works for Skyborne (one Alliance Skyborne confirmed), though some players hit a missing follow-up bug. [Player]
- **Unique class quests:** none reported. Class content appears to be the standard Classic class quests; no Skyborne-specific class quest has been mentioned anywhere. (verify as beta continues)

### Story beat summary (Horde side, from tester Eldryth — the only end-to-end account so far) (verify)

1. Start in Thendal Village; establish that the elementals are gone and pylons are failing; early cult (Al'Aketh) infiltration quests ("Among the Faithful").
2. Move through Shen'dar and the farmlands; bandits and corrupted wildlife; the Windshaper/High Order rivalry escalates.
3. You witness a secret meeting between a **High Order magister and the Al'Aketh**; cultists murder the magister and the High Order blames **you**, raising faction tension.
4. Escort a cult defector to **Valanaar**; he's found dead but leaves intel that the cult plans to **destroy the pylons** hiding the isle.
5. Windshapers and High Order agree to a truce against the cult (the High Order openly says they'll kill you afterwards).
6. Finale: chase the cult leader through a **portal to a floating Skywall tower**; **Rohash** (djinn lord, Throne of the Four Winds) appears. The **Earthen Ring (Muln Earthfury)** and the **Kirin Tor (Ansirem Runeweaver)** arrive as reinforcements; you defeat Rohash's elementals and he retreats. Dialogue mentions other lost Skyborne provinces.
7. Tester finished at **level 13–14**, i.e. the zone comfortably covers 1–12 with headroom.

---

## 6. Leaving the isle and where you land

**Method:** **airship** from the **Valanaar Skydocks** (separate docks per faction). The Ruins of Ban'aethal (NE) were Blizzard Watch's pre-beta guess for an exit; testers instead describe airships at Valanaar. (verify docks vs. any portal)

**Horde (Windshaper):** airship to a **brand-new plateau on the northern cliffs of Mulgore**, with paths down into **Desolace and Stonetalon Mountains**; this is where the Windshapers made contact with **Muln Earthfury / the Earthen Ring**. From there you are effectively in the Horde Kalimdor flow: Mulgore/Thunder Bluff → **The Barrens** (10–25) is the natural next zone, with Stonetalon (15–27) adjacent. [Player: Eldryth, MMO-Champion p.55] (verify plateau name and its flight master)

**Alliance (High Order):** not yet reported end-to-end. Evidence: a **Kirin Tor flag at the other airship dock** (Eldryth), the High Order's stated Kirin Tor alignment, Kirin Tor's Ansirem Runeweaver in the finale, and a pre-beta forum claim that Alliance Skyborne "will have their own district in Dalaran behind the Violet Citadel" (user Jordi). Strong inference: **Alliance Skyborne fly to Dalaran in the Alterac Mountains**. (verify — nobody has posted the Alliance arrival yet)
- Problem for a leveling route: Dalaran/Alterac is a **28–33** area (City of Dalaran dungeon 28–33; Alterac wild mobs ~30+). If the airship really lands a level-12 there, expect a flight/breadcrumb to a lower zone. Nearest Alliance 10–20 content is **Loch Modan (10–20)** and **Westfall (10–20)** via Ironforge/Stormwind, or **Hillsbrad/Southshore (20–30)** via the new Menethil–Southshore–Auberdine boat. (verify in-client)

**Can you leave early?** One US-forum poster said you can apparently leave around level 5; the EU "Among the Faithful" thread says you can skip the bugged quest and leave the island but you'll be under-levelled. (verify whether the airship is gated on the finale quest)

**Where a Skyborne joins the normal route (~level 12):**
- Horde: Mulgore plateau → Thunder Bluff → The Barrens (Crossroads) at 12; then the standard Horde Kalimdor route (Barrens → Stonetalon/Ashenvale → Thousand Needles).
- Alliance: Dalaran (inferred) → hearth/flight to Ironforge/Stormwind → Loch Modan or Westfall at 12; then Redridge/Duskwood/Wetlands as usual. (verify)

---

## 7. Mounts

- **Racial mount family: Galestrider** (visuals not yet published). Datamined names: **Empyrean, Regal, Stormy, Umber Galestrider** (level 40 / 60% tier) and **Swift** versions of each (level 60 / 100% tier). Wowhead race pages list "6 mounts" per variant. Listed as reputation-based rewards in beta data — likely tied to the Windshapers / High Order reputations. [DB, Warcraft Tavern datamine, Warcraft Tavern races guide] (verify vendor/rep requirement)
- **Cerulean Prideclaw** — the ground mount included in the Skyborne Heroic Pack and up (usable by all races). [Official]
- A "world-of-warcraft-forever.wiki" page listing "Zephyr Lynx, Tempest Roc, Cumulus Strider, Gale Charger, Sky Sovereign" with a 310% flying mount is **fabricated** (there is no flying in Forever) — ignore it.
- Forever uses a TBC-style riding model (riding at 40, epic at 60); Galestriders fit the same tiers. [Press]

---

## 8. Dalaran / Alterac

- **Dalaran returns as a rebuilt, grounded city in the Alterac Mountains** (post-Third War, pre-floating). Its concealing Kirin Tor barrier has fallen, enchantments are backfiring, arcane constructs are loose and demonic energy is leaking. [Official panel, Press]
- **City of Dalaran dungeon: level 28–33**, one of nine new dungeons; Blizzard stressed the city is also an explorable area with its own quests ("investigating strange magical trouble in Dalaran"). [Official, Press]
- Skyborne tie-in: the High Order (Alliance) follows the Kirin Tor's arcane philosophy; Kirin Tor's Ansirem Runeweaver shows up in the Zephras finale; Alliance Skyborne appear to airship to Dalaran (see §6). A Skyborne "district behind the Violet Citadel" is a forum claim only. (verify)
- Alterac Mountains outside Dalaran: no announced level change from Classic (~30–40). Not reachable in beta week 1 (cap 20). (verify)

---

## 9. Beta facts relevant to Skyborne

- Beta: **17 Sep – 21 Oct 2026**; launch **4 Nov 2026, 3:00 pm PST**. Progress does not carry to launch; characters must be recreated. [Official]
- **Level cap 20 at start, raised to 30 "after a couple of weeks"** (Clay Stone, Associate Production Director; Nora Mills, Lead Software Engineer). No date given for the raise. No 31–60 or raid testing. [Official, Icy Veins]
- Week-1 content: Skyborne + Zephras Isle, all zone content to 20, dungeons **Hall of Thanes (13–18)** and **Ruins of Lordaeron (15–20)**. More zones, dungeons and the new battleground open later; a "Server Slam" open-access event is planned. [Official]
- Beta access: Skyborne **Epic Pack ($59.99)** or **Warcraft Forever Collection ($79.99)** (the $29.99 Heroic Pack does NOT include beta), or opt-in lottery invites. [Official]
- Beta layering exists (players "layer-hop" by relogging/grouping to dodge bugged spawns). [Player]

---

## 10. Pack contents (for the "is it worth it" question)

**Skyborne Heroic Pack ($29.99):** Skyborne race + Zephras Isle; early name reservation (up to 3 names); Cerulean Prideclaw mount; Shen'dorei Skyseer's Garb cosmetic set; Veteran Adventurer's Rucksack; Shen'dorei Windwell toy; Skyborne housing decor; 1 Invite-A-Friend launch code.
**Skyborne Epic Pack ($59.99):** all of the above + beta access from 17 Sep, 30 days game time from 4 Nov, more Veteran Adventurer cosmetics, tabards, pets (Zergling, Panda, Diablo, Pachimari), 3 Invite-A-Friend codes.
**Warcraft Forever Collection ($79.99, until 11 Jan 2027):** Epic + Warcraft III: Reforged + Forsaken Kingdom campaign + Forsaken/Human figurine decor. [Official]

---

## 11. Open questions to verify in-client

1. Exact Alliance airship destination and the level-appropriate breadcrumb from Dalaran.
2. Name and flight point of the new northern-Mulgore plateau.
3. Whether the Valanaar airship is gated behind the finale quest, and whether it runs both ways (can you return? can other races visit?).
4. Full Zephras quest list and hub order (Thendal → Shen'dar → Falaath → Valanaar → Sanctum/Rohashi?).
5. Locations of ley lines (Read Ley Line) and elemental convergences (Skysight) on the mainland.
6. Galestrider vendor + reputation requirement; whether the Windshaper/High Order rep is faction-locked.
7. Any Skyborne-specific class quest (none seen so far).
8. Date the beta cap goes to 30.

---

## Sources

Official
- https://worldofwarcraft.blizzard.com/en-us/forever
- https://worldofwarcraft.blizzard.com/en-us/news/24302093 (Carve a New Path — announcement)
- https://worldofwarcraft.blizzard.com/en-us/news/24301508 (Pre-purchase editions)
- https://worldofwarcraft.blizzard.com/en-us/news/24304160 (Beta Now Live)
- https://news.blizzard.com/en-us/article/24303862/world-of-warcraft-forever-whats-next-panel-recap
- https://news.blizzard.com/en-us/article/24304071/world-of-warcraft-forever-found-photos-panel-recap

Wowhead (Forever)
- https://www.wowhead.com/forever/guide/skyborne-race-overview
- https://www.wowhead.com/forever/news/skyborne-first-look-new-neutral-race-in-world-of-warcraft-forever-382829
- https://www.wowhead.com/forever/news/racials-for-skyborne-in-forever-and-racial-changes-to-existing-races-382847
- https://www.wowhead.com/forever/news/skyborne-druid-forms-in-wow-forever-382861
- https://www.wowhead.com/forever/news/all-skyborne-male-customization-options-in-wow-forever-382952
- https://www.wowhead.com/forever/guide/overview-features-zones-raids
- https://www.wowhead.com/forever/guide/zones-maps-locations-rewards
- https://www.wowhead.com/guide=34778 (All racials & race-class combos)
- https://www.wowhead.com/forever/zone=16593/zephras-isle
- https://www.wowhead.com/forever/race=95/high-order-skyborne
- https://www.wowhead.com/forever/race=96/windshaper-skyborne
- https://www.wowhead.com/forever/faction=2778/windshapers
- https://www.wowhead.com/forever/faction=2779/high-order
- https://www.wowhead.com/forever/spell=1259416/walk-on-air
- https://www.wowhead.com/forever/spell=1259705/read-ley-line
- https://www.wowhead.com/forever/spell=1259686/skysight
- https://www.wowhead.com/forever/spell=1258510/blessing-of-zephras
- https://www.wowhead.com/forever/item=269681/empyrean-galestrider

Icy Veins / Method / Blizzard Watch / Warcraft Tavern
- https://www.icy-veins.com/wow-forever/skyborne-race-guide
- https://www.icy-veins.com/wow/news/meet-wow-forevers-new-race-everything-we-know-about-the-skyborne/
- https://www.icy-veins.com/wow-forever/news/who-are-the-skyborne-the-lore-behind-wow-forevers-new-race/
- https://www.icy-veins.com/wow-forever/news/the-wow-forever-beta-starts-at-level-20-level-30-after-couple-of-weeks/
- https://www.icy-veins.com/wow-forever/news/new-warcraft-forever-race-requires-skyborne-heroic-pack/
- https://www.method.gg/wow-classic/all-new-racial-abilities-in-world-of-warcraft-forever
- https://blizzardwatch.com/2026/09/14/skyborne-starting-zone-wow-forever/
- https://blizzardwatch.com/2026/09/16/skyborne-classes-factions/
- https://blizzardwatch.com/2026/09/13/know-world-warcraft-forevers-new-zones-quests-dungeons-raids/
- https://www.warcrafttavern.com/forever/guides/races/
- https://www.warcrafttavern.com/forever/guides/beta/
- https://www.warcrafttavern.com/forever/news/all-new-zones-areas-in-wow-forever-revealed-at-blizzcon/
- https://www.warcrafttavern.com/forever/news/mount-names-datamined-in-wow-forever/

Wiki / other press
- https://warcraft.wiki.gg/wiki/Skyborne
- https://warcraft.wiki.gg/wiki/Zephras_Isle
- https://www.windowscentral.com/gaming/blizzard/why-is-world-of-warcraft-forever-adding-another-elf-race-i-asked-blizzard
- https://outputlag.com/news/world-of-warcraft-forevers-skyborne-split-into-the-windshapers-and-the-high-order/
- https://noobtoboss.com/wow-forever-new-race-class-changes/
- https://mobalytics.gg/wow-forever/guides/wow-forever-skyborne
- https://wowforeverguides.com/races/skyborne
- https://www.zockify.com/forever/skyborne/

Beta player reports
- https://www.mmo-champion.com/threads/2669879-World-of-Warcraft-Forever-Megathread/page55 (Eldryth: story, Mulgore airship, Kirin Tor dock)
- https://www.mmo-champion.com/threads/2669879-World-of-Warcraft-Forever-Megathread/page57 (Eldryth: Horde finale, Rohash, level 13–14)
- https://www.mmo-champion.com/threads/2669879-World-of-Warcraft-Forever-Megathread/page58
- https://us.forums.blizzard.com/en/wow/t/skyborne-starting-zone/2352828
- https://us.forums.blizzard.com/en/wow/t/skybourne-zone-after-starting-zone-is-finished/2349801
- https://us.forums.blizzard.com/en/wow/t/a-firm-response-unable-to-progress/2353697
- https://us.forums.blizzard.com/en/wow/t/quest-among-the-faithful-not-working-cant-progress-past-starting-area/2353010
- https://eu.forums.blizzard.com/en/wow/t/among-the-faithful-skyborne-quest/629624
- https://eu.forums.blizzard.com/en/wow/t/big-zephras-isle-problem/629393
- https://us.forums.blizzard.com/en/wow/t/druid-questline-for-bear-form-broken-for-me/2353628
- https://us.forums.blizzard.com/en/wow/t/unable-to-train-pet/2353618
