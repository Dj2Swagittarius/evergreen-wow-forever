# Evergreen split into child addons

## Goal
Each Evergreen module can be turned on or off from the in-game AddOns list, and the modules show
nested under Evergreen, like "Routes Import/Export" under Routes and "GatherMate2Data" under
GatherMate2. Everbid and !Everror are listed under Evergreen too.

## Layout
| Folder | List title | Files |
|---|---|---|
| `Evergreen` | Evergreen | `Modules.lua` (skin, shared namespace, `/eg` dispatcher, module status), `arrow.tga`, `Maps/` |
| `Evergreen_Guide` | Evergreen - Guide | `Data.lua`, `Routes_*.lua`, `QuestIDs.lua`, `Core.lua` |
| `Evergreen_Journal` | Evergreen - Journal | `Journal_Data`, `Journal`, `Journal_Boss`, `Journal_MapData`, `Journal_Map` |
| `Evergreen_Buffs` | Evergreen - Buffs | `Buffs.lua`, `Bindings.xml` |
| `Evergreen_Move` | Evergreen - Move | `Move.lua` |
| `Evergreen_Reveal` | Evergreen - Map Reveal | `Reveal_Data.lua`, `Reveal.lua` |
| `Evergreen_Everpanel` | Evergreen - Everpanel | `Everpanel.lua`, `Plugins/*.lua` |
| `Evergreen_Trackers` | Evergreen - Trackers | `Tracker.lua`, `Tracker_XP.lua`, `Tracker_Gold.lua` |

Child TOCs: `## Dependencies: Evergreen`, `## Group: Evergreen`, and `## OptionalDeps` for load
order: Journal after Guide; Everpanel after Guide, Journal, Buffs; Trackers after Everpanel. The Guide
also takes over `## OptionalDeps: TomTom`. Everbid and !Everror get `## Group: Evergreen` only (no
dependency; they still work alone and !Everror still loads first).

## Shared namespace
The core sets `EvergreenNS = ns`. Each child's first file is `Link.lua`:
`setmetatable(ns, { __index = EvergreenNS, __newindex = EvergreenNS })`, so every existing file keeps
`local ADDON, ns = ...` unchanged (and data generators keep writing that header); `ADDON` is the
child's own name, which is what its `ADDON_LOADED` check needs.

## Module on/off
`ns.ModuleEnabled(id)` = the child addon is loaded/loading, or enabled for this character
(`C_AddOns.GetAddOnEnableState(name, character) > 0`), and not switched off in
`EvergreenDB.modules` (kept for the test harness). The first load of this version clears old
`EvergreenDB.modules` flags (`EvergreenDB.split = true`) so the AddOns list is the only switch.
`/eg modules` lists each child and its state; `/eg module ...` now says to use the AddOns list.

## /eg
The core owns `/eg` and `/evergreen` and dispatches `modules`, `minimap`, `journal`, `reveal`,
`panel`, `track`; everything else goes to `ns.GuideSlash`, which the Guide sets instead of
registering the slash itself. With the Guide off, `/eg` says so.

## Settings
All SavedVariables stay declared by the core (`EvergreenDB`, `EverbuffDB`, `EverMoveDB`,
`EvergreenCharDB`), so existing settings carry over.

## Tools and tests
Harness loads the core TOC then each child TOC in dependency order, firing `ADDON_LOADED` per addon.
Route tools read `../Evergreen_Guide`; data generators write into the child folders. `rebuild.sh
--deploy` replaces every `Evergreen*` folder in the beta client (removing the old `Evergreen/Modules`).
All existing test runs must pass unchanged.
