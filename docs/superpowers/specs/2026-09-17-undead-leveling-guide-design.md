# Undead Leveling Guide — Design Spec

Date: 2026-09-17
Status: built without a live review round (user ran the request unattended); assumptions listed below.

## Goal

One-page, high-density Forsaken (Undead) 1–60 leveling guide for Classic WoW. Baseline is Classic Era / 20th Anniversary rules. Marked callouts flag what WoW Forever (beta 2026-09-17, launch 2026-11-04, permanent 60 cap) is known to change, so the page can be re-scoped once beta data lands.

## Assumptions

- Audience: a player who knows WoW basics, wants a route they can follow without an addon.
- Deliverable is a static HTML page (`index.html`) at repo root, also published as a claude.ai Artifact. No build step, no framework.
- Route favors Eastern Kingdoms hubs (Undercity zeppelins, Sepulcher, Tarren Mill, Hammerfall, Grom'gol) to cut travel for a Forsaken, with Kalimdor swings only where the XP density is clearly better (Barrens 17–20, Thousand Needles 25–30, Desolace/Tanaris/Feralas/Un'Goro later).
- Quest data for 1–30 was cross-checked against Joana's, wow-pro (Manovan, SilverKnight, Jame's), Wowhead Classic and Warcraft Wiki. 30–60 is hub- and chain-level from Classic knowledge; counts and coordinates there are approximate and marked as such.

## Approaches considered

1. Markdown file in repo — fastest, but no navigation, no checklists, poor on phone. Rejected.
2. Multi-page site (Next.js) — overkill for a brand-new, unscoped project. Rejected for now; can be migrated later.
3. Single HTML page with sticky bracket nav, per-quest checkboxes (localStorage), theme tokens for light/dark — chosen.

## Structure

1. Masthead: name, version banner (Era baseline / Forever dates).
2. Start here: how to read the page, version caveat.
3. Racials (Era vs Forever table).
4. Class pick for leveling.
5. Rules of the road (hearth policy, rested XP, First Aid, Cannibalize, gold).
6. Route by bracket, 12 brackets 1–60. Each: level range, zone, hub, hearth, flight point, numbered "do this" list with quest names + coords, grind spot, leave-when line, checkboxes.
7. Dungeons worth running (Horde/Forsaken quest hooks).
8. Undercity logistics: zeppelins, boats, flight points to collect, city quarters.
9. Mount and gold.
10. WoW Forever watchlist.
11. Sources.

## Design tokens

- Palette: bone `#E8E6DD` ground / ink `#1C1F1B` / plague green accent `#3E7D34` / Forsaken violet `#5A4478` / parchment-gold for coordinates `#8A6B1F`. Dark theme swaps to `#121513` ground, `#D9DCCF` ink, `#7FD35E`, `#A98FD6`, `#D2AE4C`.
- Type: Grenze Gotisch (display, headings only), Source Serif 4 (body), IBM Plex Mono (levels, coordinates).
- Layout: sticky left bracket nav on desktop, stacked on phone; content column ~72ch.

## Out of scope (for now)

- Per-class talent builds.
- Addon setup walkthroughs.
- Anything requiring WoW Forever beta data not yet public.
