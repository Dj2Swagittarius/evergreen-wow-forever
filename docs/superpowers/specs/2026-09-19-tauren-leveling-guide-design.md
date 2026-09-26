# Tauren Leveling Guide — Design Spec

Date: 2026-09-19
Status: built without a live review round (user asked for it and moved on); assumptions listed below. Sister of `2026-09-17-undead-leveling-guide-design.md`.

## Goal

A Tauren 1–60 leveling guide with the same shape as The Forsaken Road, in two places:

1. `tauren.html` — a static page next to `index.html`, same CSS, same checkbox script, same bracket markup.
2. A `tauren` route in the Evergreen addon (`addon/Evergreen/Data.lua`), picked automatically for Tauren characters.

Both carry class-specific quest steps (Warrior, Hunter, Shaman, Druid: the four Tauren classes in Era and in Forever) and show only the ones for the class being played.

## Assumptions

- Same audience and baseline as the Undead guide: Classic Era / Anniversary data, violet Forever callouts, `verify` tags on anything not re-checked.
- Route stays on Kalimdor where the XP density allows it, because a Tauren's hearth and flight net are Thunder Bluff / Crossroads / Camp Taurajo. Eastern Kingdoms legs (Stranglethorn, Arathi, Badlands, Swamp, Hinterlands, Plaguelands) are kept where the Undead route already justified them; the 25–60 brackets are the Forsaken Road's with the logistics lines rewritten for a Tauren.
- Brackets: 1–6 Red Cloud Mesa (Camp Narache), 6–12 Bloodhoof Village and Mulgore, 12–20 The Barrens (Crossroads, Ratchet, Camp Taurajo), 20–25 Stonetalon and Ashenvale, then the shared 25–60 brackets.
- Class picking on the page: a four-button class picker in the "Pick your class" section, remembered in localStorage, also settable with `?class=druid` in the URL. Steps tagged `data-class` are hidden for other classes. With no class picked, every class step shows with a class tag.
- Class picking in the addon: `UnitClass("player")`. Steps carry `cls="DRUID"` (or a set); the engine drops steps for other classes when it selects the route. Step keys are per-character, and a character's class never changes, so filtered indices are stable.
- Class quest data (Bear/Aquatic form, totem calls, Tauren taming, warrior stances, level-50 Sunken Temple chains) is cross-checked against Wowhead Classic and Warcraft Wiki; anything not confirmed gets `verify`.

## Approaches considered

1. One page with a race switcher (Undead / Tauren) — heavy rewrite of a working page, and the two races share only half the route. Rejected.
2. Separate `tauren.html` sharing the stylesheet by copy — chosen; no build step, the two pages stay independent and the Undead page is untouched apart from a cross-link.
3. Class filter only in the addon, none on the page — rejected; the page is the deliverable people read without the game open.

## Structure (page)

Masthead → Start here → Why Tauren (racials Era vs Forever) → Pick your class (picker + cards) → Rules of the road → 12 brackets → Dungeons → Thunder Bluff logistics → Mount and gold → Forever watchlist → Sources. Same ids as `index.html` (`b1`…`b12`, `start`, `racials`, …) so links and the nav script carry over.

## Structure (addon)

- `ns.TAUREN_BRACKETS`: four race-only brackets (Mulgore ×2, Barrens, Stonetalon/Ashenvale).
- `ns.ROUTES` gains `{ id="tauren", name="The Long Walk", faction="Horde", races={Tauren=true}, raceOnly=4, brackets = tauren brackets ++ forsaken brackets 6–12 }`.
- `Core.lua`: `SelectRoute` filters each bracket's steps by `cls` against the player's class; `StepTitle` appends a muted class label to class steps.
- Map ids added: Mulgore 1412, Stonetalon 1442, Moonglade 1450.

## Out of scope

- Talent builds, addon setup walkthroughs, Forever data not yet public (Shen'dralas level range, Mulgore rework).
- An Orc/Troll starting route (they join the Tauren route at the Barrens, like non-Undead Horde join the Forsaken Road).
