# Race page builder brief

How to build one race's leveling guide page and Evergreen addon route so it matches the existing Undead (`index.html`) and Tauren (`tauren.html`) guides. Read this whole file, then `tauren.html` end to end, before writing anything.

## Deliverables per race

1. `<race>.html` at the repo root (`orc.html`, `troll.html`, `human.html`, `dwarf.html`, `gnome.html`, `nightelf.html`, `skyborne-horde.html`, `skyborne-alliance.html`).
2. `addon/Evergreen/Routes_<Race>.lua` (`Routes_Orc.lua`, `Routes_Troll.lua`, `Routes_Human.lua`, `Routes_Dwarf.lua`, `Routes_Gnome.lua`, `Routes_NightElf.lua`, `Routes_Skyborne.lua`).

Do not edit `index.html`, `tauren.html`, `Data.lua`, `Core.lua`, `Routes_Tauren.lua` or the TOC. The integrator splices the TOC and cross-links.

## The page

The Undead guide is `undead.html` (no class picker yet; it is being retrofitted separately). Copy `tauren.html` verbatim as the starting point and change only content. Keep every CSS rule, the `<script>` block, the section ids (`start`, `racials`, `classes`, `rules`, `b1`…`b11` or `b12`, `dungeons`, `logistics`, `mount`, `forever`, `sources`), the `.picker` markup, and the `data-class` mechanics. Then:

- `<title>`: a two-to-four-word name in the same spirit ("The Forsaken Road", "The Long Walk"). Pick one per race, e.g. Orc "The Blood Road", Troll "The Loa's Path", Human "The King's Road", Dwarf "The Deep Road", Gnome "The Long Tinker", Night Elf "The Moon Road", Skyborne "The Falling Sky". Update the `<h1>` (one accent `<span>` word), the masthead eyebrow (faction · race · 1–60), the lede, the `.sister` line (keep the `index.html` "All guides" link, which is the menu; name `undead.html` and `tauren.html` as sister guides), and `meta description`.
- Storage keys in the script: change `KEY='long-walk-v1'` and `CKEY='long-walk-class'` to `<race>-v1` / `<race>-class` so pages do not share tick state.
- The class picker: one button per class the race can play in Classic Era, plus Forever-only combos as buttons with a `<span class="tag forever">Forever</span>` inside the label. Update the `CLASSES` array in the script and the four `body[data-class=…]` CSS selectors to the race's class list (lower-case ids: warrior, paladin, hunter, rogue, priest, shaman, mage, warlock, druid).
- Accent colour: pick a race-appropriate accent in `:root` (light and dark), keep violet for Forever. Orc dark red-brown, Troll teal-green, Human royal blue, Dwarf bronze, Gnome pink-magenta, Night Elf indigo-silver, Skyborne sky-blue. Change only `--accent`, `--accent-ink`, `--accent-soft`.
- Racials section: Era vs Forever table for the race from `docs/research/<file>.md` (racials are in `alliance-1-20.md` for Alliance races, `orc-troll-1-20.md` for Orc/Troll, `skyborne.md` for Skyborne). Four rows plus the violet note.
- Class cards: one `<article data-class="…">` per playable class, ranked for solo leveling speed, with the race's class-quest highlights. Forever-only classes get the violet tag and a card that says the class quests are unpublished.
- Rules of the road: keep the structure, rewrite the race-specific habits list (racials, First Aid trainer in the starting hub, profession pick, mount vendor and price), and the gold notes.
- Brackets: 1–20 from the race's research file (three or four brackets, quest by quest, coordinates as `<span class="c">x,y</span>`), then the faction's shared 20–60 brackets. Horde races reuse the Tauren page's brackets b4–b11 (Stonetalon/Ashenvale 20–25, Thousand Needles 25–30, then 30–60) with the travel/hearth lines rewritten for the race's home city (Orgrimmar zeppelin tower for Orc/Troll). Alliance races build 20–60 from `docs/research/alliance-20-60.md` (eight brackets) with Ironforge/Stormwind/Darnassus logistics. Every bracket keeps: `.sec-head` with level eyebrow, `.meta` grid (Hub, Hearth, Flight point, Trainers or Travel), optional `.note`, `<ol class="steps">`, `<p class="leave">`, and a violet Forever note where anything is known.
- Class quests: every class quest chain for every class the race can play, as `<li data-class="…">` steps inside the bracket where the level matches, starting with `<span class="tag cls">Class</span>`. Take them from `docs/research/class-quests-all.md` (and `tauren-class-quests.md` for Horde warrior/hunter/shaman/druid chains, which are faction-wide). Level 10 class quests (stance, pet, totem, Bear Form, Voidwalker, rogue and mage errands, Redemption at 12) go in the 6–12 bracket; poisons/Succubus/Verigan's Fist at 20; Felhunter/Berserker Stance/Whirlwind/Call of Air at 30; Felsteed/Warhorse at 40; every Sunken Temple chain at 50; Charger/Dreadsteed at 60 as one line in the last bracket.
- Dungeons table: same rows, rewrite the last column for the race/faction's quest hooks.
- Logistics section: the home city (districts, where each class trainer is, the inn, the bank, flight master, boats/zeppelins/tram), flight points to collect in route order per continent, and the "Class quest stops" list by level.
- Mount and gold: race mount vendor and riding trainer, prices (100 g at 40, 1,000 g epic at 60, Paladin/Warlock free mounts), gold expectations.
- Forever watchlist: same table shape, rows re-scoped to what affects this race's route (its new combos, Undercity surface, Shen'dralas, Riverdale, Dalaran, Wetlands expansion for Alliance, Zephras Isle for Skyborne, talents, 1,000 quests).
- Sources: paragraph plus link list, URLs from the research files' Sources sections.
- Every fact not in a research file and not certain from Classic knowledge gets `<span class="tag verify">verify</span>`.
- No em-dashes anywhere in prose. Use commas, colons or full stops.
- Finish by running: `python -c "from html.parser import HTMLParser..."` tag-balance check (copy the one in this brief's appendix) and `node --check` on the extracted script.

## The addon route file

Read the header comment of `addon/Evergreen/Data.lua` (step format) and all of `addon/Evergreen/Routes_Tauren.lua` (a complete example including class steps, map ids, and how a route reuses shared brackets). Then write `Routes_<Race>.lua`:

```lua
-- Evergreen route: <Race> ("<Title>"). Loaded after Data.lua; appends to ns.ROUTES.
local ADDON, ns = ...
ns.<RACE>_BRACKETS = { ...race-only brackets, ids "<r>1", "<r>2"... (o1, o2 for Orc; h1 for Human; d1 Dwarf; g1 Gnome; n1 Night Elf; s1 Skyborne) }
local ROUTE_BRACKETS = {}
for _, b in ipairs(ns.<RACE>_BRACKETS) do table.insert(ROUTE_BRACKETS, b) end
-- Horde: then the shared brackets. Orc/Troll: ns.TAUREN_BRACKETS[3] (Barrens 12-20, id t3), [4], [5], then ns.BRACKETS[7..12].
-- Alliance: an ns.ALLIANCE_BRACKETS table defined ONCE in Routes_Human.lua (ids a4..a11 for 20-60); Dwarf, Gnome and Night Elf files reuse it via ns.ALLIANCE_BRACKETS (Human's file loads first).
table.insert(ns.ROUTES, { id="<race>", name="<Title>", faction="Horde"|"Alliance", races={ <RaceFileName>=true }, raceOnly=<number of race-only brackets>, brackets=ROUTE_BRACKETS })
```

Race file names from `UnitRace`: Orc, Troll, Human, Dwarf, Gnome, NightElf, Scourge, Tauren. Skyborne is unknown; use `Skyborne` and note it in the header comment.

Map ids already in `ns.MAP_NAMES`: see Data.lua. Add new ones with `ns.MAP_NAMES[id] = "Name"` at the top of your file (Classic map ids: Durotar 1411, Elwynn 1429, Westfall 1436, Redridge 1433, Duskwood 1431, Dun Morogh 1426, Loch Modan 1432, Wetlands 1437, Teldrassil 1438, Darkshore 1439, Stormwind 1453, Ironforge 1455, Darnassus 1457, Alterac 1416, Blasted Lands 1419, Deadwind 1430, Moonglade 1450, Stonetalon 1442, Mulgore 1412). Zephras Isle has no known id; use 0 and mark verify.

Class steps: `cls="WARRIOR"` (upper-case class file name) or `cls={WARRIOR=true, ROGUE=true}`. Every quest in a class chain is its own step with `p=` for repeated names. Shared class chains that belong in the faction's shared brackets: Horde ones are already injected into ns.BRACKETS by Routes_Tauren.lua; do not duplicate them. Alliance ones go into ns.ALLIANCE_BRACKETS in Routes_Human.lua (Alliance warrior Whirlwind, all Alliance level-50 Sunken Temple chains, paladin Warhorse/Charger, warlock Felsteed/Dreadsteed, druid Torwa), and Dwarf/Gnome/Night Elf files add nothing there.

Validate with LuaJIT: `"C:/Users/DJ/AppData/Local/Programs/LuaJIT/bin/luajit.exe" -bl Routes_<Race>.lua` must print no error, then load headless:

```lua
local ns = {}
for _, f in ipairs({"Data.lua","Routes_Tauren.lua","Routes_Human.lua","Routes_<Race>.lua"}) do assert(loadfile(f))("Evergreen", ns) end
for _, r in ipairs(ns.ROUTES) do
  for i, b in ipairs(r.brackets) do assert(b.id and b.lv and b.steps and b.map, r.id..i)
    for _, st in ipairs(b.steps) do for _, k in ipairs({"g","o","r"}) do local c=st[k]; if c then assert(type(c[1])=="number" and type(c[2])=="number", b.id.." "..(st.q or "?")) end end end end end
print("ok")
```
(run from `addon/Evergreen`; omit Routes_Human.lua for Horde races).

## Report back

Reply with at most 250 words: files written, bracket list with levels, number of class-gated steps per class, anything you could not source (list the `verify` items that matter most), and the validation output. Do not paste file contents.

## Appendix: tag-balance check

```python
from html.parser import HTMLParser
class P(HTMLParser):
    def __init__(s): super().__init__(); s.stack=[]; s.err=[]
    def handle_starttag(s,t,a):
        if t not in ('meta','link','input','br','img'): s.stack.append((t,s.getpos()))
    def handle_endtag(s,t):
        if s.stack and s.stack[-1][0]==t: s.stack.pop()
        else: s.err.append((t,s.getpos()))
p=P(); p.feed(open('<race>.html',encoding='utf-8').read()); print('errors:',p.err[:5],'unclosed:',p.stack[:5])
```
