# Evergreen for WoW Forever

Leveling guides for every race and class of **World of Warcraft: Forever** (Blizzard's Classic+ ruleset, beta from Sep 17 2026, launch Nov 4 2026), and **Evergreen**, the in-game companion addon that plays them: a leveling guide with a waypoint arrow, a dungeon journal, a buff button, a window mover and a world map reveal.

Not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment.

## Install the addon

Copy `addon/Evergreen` into `World of Warcraft\_classic_beta_\Interface\AddOns\` (Forever beta) or `\_classic_era_\Interface\AddOns\` (Classic Era) and restart the game. `/eg` opens the guide, `/ej` the dungeon journal, `/eg modules` lists everything. Details: [`addon/README.md`](addon/README.md).

## The guide pages

- `index.html` — the menu: pick faction, race and class, and it opens the right guide with the class filter set (`<race>.html?class=<class>`). The pick is remembered per browser.
- One guide page per race, same layout, no build step; checkbox progress is stored in that browser's localStorage only. Class quests are folded into the steps as `<li data-class="druid">`; the class picker at the top (or `?class=druid` in the URL) hides the other classes' steps and is remembered per browser.

| Page | Title | Faction | Classes (Forever-only in italics) |
|---|---|---|---|
| `undead.html` | The Forsaken Road | Horde | Warrior, Rogue, Priest, Mage, Warlock, *Paladin* |
| `tauren.html` | The Long Walk | Horde | Warrior, Hunter, Shaman, Druid |
| `orc.html` | The Blood Road | Horde | Warrior, Hunter, Rogue, Shaman, Warlock, *Mage* |
| `troll.html` | The Loa's Path | Horde | Warrior, Hunter, Rogue, Priest, Shaman, Mage, *Warlock* |
| `skyborne-horde.html` | The Falling Sky | Horde | *Warrior, Hunter, Rogue, Druid, Shaman* (Forever race; beta data) |
| `human.html` | The King's Road | Alliance | Warrior, Paladin, Rogue, Priest, Mage, Warlock, *Hunter* |
| `dwarf.html` | The Deep Road | Alliance | Warrior, Paladin, Hunter, Rogue, Priest, *Shaman* |
| `gnome.html` | The Long Tinker | Alliance | Warrior, Rogue, Mage, Warlock, *Priest* |
| `nightelf.html` | The Moon Road | Alliance | Warrior, Hunter, Rogue, Priest, Druid |
| `skyborne-alliance.html` | The Violet Road | Alliance | *Warrior, Hunter, Mage, Rogue, Druid* (Forever race; beta data) |

The 20–60 halves are shared per faction (Horde pages reuse the Tauren brackets, Alliance pages the Human ones) with the travel and hearth lines rewritten per race. Anything not re-checked against a source carries a `verify` tag; the Skyborne pages and every Forever-only class are beta or unpublished data and say so.
- `docs/research/` — raw research notes per race/class that the pages were built from.
- `addon/Evergreen/` + `addon/Evergreen_*/` — in-game companion addon (WoW Forever beta + Classic Era): a core and one addon per module, listed under Evergreen in the AddOns list. The guide (`Evergreen_Guide`) is a race-agnostic engine with a route registry; one route per race in `Routes_<Race>.lua` (Undead, Tauren, Orc, Troll, Human, Dwarf, Gnome, Night Elf, Skyborne Horde and Alliance), picked by race then faction. Steps may be class-gated (`cls="DRUID"`); the engine shows only the player's class. Tracks quests from your log, shows the next step, sets an in-world waypoint. See `addon/README.md`.
- `addon/Evergreen_Journal/`, `_Buffs/`, `_Move/`, `_Reveal/`, `_Everpanel/`, `_Trackers/` — the other modules: dungeon journal, buff button (formerly Everbuff), window mover (formerly EverMove), world map reveal, info bar, XP/gold trackers.
- `addon/tools/` — the data pipeline: route optimizer, route audit against Questie, dungeon journal and map-reveal data builders, and a headless test harness (`rebuild.sh` runs all of it).
- `docs/superpowers/specs/` — design notes and assumptions.

## Versions

- Baseline: Classic Era / 20th Anniversary (1.15) rules and quest data.
- WoW Forever: beta Sep 17 – Oct 21, 2026, launch Nov 4, 2026, level cap stays 60. Known changes are flagged in violet "Forever" callouts inside the guide. Re-check the watchlist section against the beta client before trusting any Forever-specific claim.

## Editing

Each level bracket is a `<section class="bracket">` with a `.meta` grid (hub, hearth, flight point) and an ordered `.steps` list. Add or reorder `<li>` items freely; the checkbox script keys progress by section id plus position, so inserting a step shifts saved ticks after it.

Quest names use `<span class="q">`, coordinates use `<span class="c">`, and anything not re-verified against a source uses `<span class="tag verify">verify</span>`.

## Credits and licence

Evergreen and the guide pages are released under the **GNU General Public License, version 2 or (at your option) any later version** (`LICENSE`).

Data sources, used with thanks:
- **AtlasLootClassic** (GPL-2, https://github.com/Hoizame/AtlasLootClassic): boss loot tables in `addon/Evergreen_Journal/Journal_Data.lua`. This is why the project is GPL-2 compatible.
- **Questie** (https://github.com/Questie/Questie): quest ids, NPC names and spawn coordinates, dungeon entrances and quest rewards were read from its database to generate `QuestIDs.lua`, `Routes_Questie_Fixes.lua` and the journal's quest lists. No Questie code is included.
- **WoWDBDefs** (https://github.com/wowdev/WoWDBDefs): DB2 layouts used by `addon/tools/wdc5.py`.
- The WoW Forever client's own data tables (world map overlays, map positions) and Wowhead's Forever database (new dungeons, Forever quests) for Forever-only content.
