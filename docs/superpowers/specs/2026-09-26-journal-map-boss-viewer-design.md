# Dungeon journal: Map tab + boss viewer — design

Date: 2026-09-26. Status: approved in conversation (user: "journal map + boss viewer first").

## Goal
The Evergreen dungeon journal (`Modules/Journal.lua`) gains:
- a **Bosses** tab (replaces **Loot**): pick a boss, see a rotatable 3D model, its info and its loot;
- a **Map** tab: the dungeon's own interior map drawn inside the journal, with floor buttons.

Tabs become: **Bosses · Quests · Map**.

## Bosses tab (`Modules/Journal_Boss.lua`)
- Row of boss buttons (skinned red buttons, wrapping onto more rows). The selected one stays highlighted.
  Selection resets to the first boss when another dungeon is picked.
- 3D model below (`PlayerModel`, full content width, 240 px tall) with `SetCreature(npcID)` from
  `Journal_Data`. Drag left/right turns it; mouse wheel zooms (`SetCamDistanceScale`, 0.4–2.5).
- The client may not have the creature cached: retry `SetCreature` every 0.5 s, up to 4 tries, then show
  "Model not available in this client". Entries without an NPC id (e.g. "Trash") show "No model for this entry".
- The model is only reloaded when the selected boss changes (item-info refreshes redraw the page often).
- Under the model: name (large, gold), `rare` tag, level, description (`desc`), then that boss's loot using the
  existing item buttons (tooltips, shift-click link, ctrl-click dress-up, faction filter).
- Dungeons with no bosses listed: "Bosses not known yet."
- World-map entrance pins open the Bosses tab (was Loot). A saved `DB.tab == "Loot"` becomes "Bosses".

## Map tab (`Modules/Journal_Map.lua`)
- Map lookup at runtime, once: scan `C_Map.GetMapInfo(1..3000)` for maps of type Dungeon
  (`Enum.UIMapType.Dungeon`, 4); index by normalised name (lowercase, leading "the " and non-alphanumerics dropped).
- Journal name → key: aliases for names that differ (`Lower/Upper Blackrock Spire` → Blackrock Spire,
  `Dire Maul East/North/West` → Dire Maul, `Temple of Ahn'Qiraj` → Ahn'Qiraj); `"X - Wing"` names use `X`.
- Floors: `C_Map.GetMapGroupID` + `GetMapGroupMembersInfo` (sorted by `relativeHeightIndex`, named by member),
  else every indexed map with that name. For `"X - Wing"`, a floor named like the wing is shown alone.
- Drawing: `C_Map.GetMapArtLayers(id)[1]` gives layer and tile sizes; `C_Map.GetMapArtLayerTextures(id, 1)`
  gives tile file ids, row-major. Tiles are scaled to the content width. Floor buttons above the map when >1.
- No map found: "No map for this dungeon in this client yet." No boss markers (no position data).
- `/ej maps` prints which journal dungeons found a map and which did not (to fix aliases after testing in game).

## Code shape
- `Journal.lua` exposes its pooled helpers on `J` (`GetText`, `GetSmallButton`, `DrawItems`) and keeps a list
  `J.extras` of persistent frames (model, map canvas) hidden on every redraw; it dispatches the Bosses and Map
  tabs to `J.DrawBosses(d, y)` / `J.DrawMap(d, y)`.
- New files load after `Journal.lua` in `Evergreen.toc`.

## Testing
- `test_harness.lua` JOURNAL mode: stub dungeon maps (a single-floor Deadmines, a Scarlet Monastery group whose
  members are named after the wings) and map art; walk every dungeon on all three tabs; assert the Deadmines map
  draws 12 tiles, the Armory shows one floor, the model shows the first boss and switches on a boss click, and
  `/ej maps` runs.
- In game: Deadmines (one floor), Blackrock Depths (several floors), Scarlet Monastery wings, a Forever dungeon;
  boss models turn and zoom; loot tooltips work.
