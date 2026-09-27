# Everpanel + XP/Gold trackers — design

Date: 2026-09-26. Status: approved in conversation, awaiting spec review.

Two new Evergreen modules and a plugin bar that hosts them:

- **Everpanel** (`everpanel`): a Titan Panel–style bar across the top of the screen with plugins.
- **XP tracker** (`xp`) and **Gold tracker** (`gold`): session and rolling rates, breakdowns, history.
  They show short text on Everpanel and open a detailed pop-up panel on click.

Out of scope here (separate spec later): dungeon journal map tab and boss viewer. Also out of scope:
gathering-node sonar (dropped).

## Fit with the existing addon

- Each is an entry in `ns.MODULES` (`Modules.lua`), gated by `ns.ModuleEnabled(id)` at `ADDON_LOADED`,
  toggled by `/eg module <id> on|off` + `/reload`, same as Buffs/Move/Reveal/Journal.
- All frames use the shared skin (`ns.Skin.Panel`, `Skin.Text`, `Skin.Button`, `Skin.Hud`).
- Saved variables live under `EvergreenDB` (account) and a per-character table (see History).
- Modules work independently: XP/Gold without Everpanel still track and open their panel via
  `/eg track`; Everpanel without XP/Gold simply lacks those plugins.

## Files

| File | Purpose |
|---|---|
| `Modules/Everpanel.lua` | bar frame, plugin registry, layout, right-click menu, screen offset |
| `Modules/Everpanel/Basics.lua` | Clock, Performance, Location, Bags plugins |
| `Modules/Everpanel/Gear.lua` | Durability, Ammo/reagents plugins |
| `Modules/Everpanel/Evergreen.lua` | Guide, Everbuff, Journal plugins |
| `Modules/Everpanel/Social.lua` | Friends, Guild plugins |
| `Modules/Tracker.lua` | shared tracker core: session clock, rolling buckets, pop-up panel, history, `/eg track` |
| `Modules/Tracker_XP.lua` | XP accounting + XP section + XP plugin |
| `Modules/Tracker_Gold.lua` | money accounting + Gold section + Gold plugin |

TOC order: `Everpanel.lua` before its plugin files; `Tracker.lua` before `Tracker_XP.lua`/`Tracker_Gold.lua`;
all after `Modules.lua` and `Core.lua`. Tracker plugins register with Everpanel only if `ns.Everpanel` exists
(and is enabled).

## Everpanel

### Bar
- Full-width bar, top of screen, ~20 px tall, `Skin.Hud` backdrop, strata `MEDIUM`.
- Plugins laid out in two groups, left and right, in saved order; each plugin is a button:
  optional 14 px icon + optional label + text. Spacing 12 px. Text truncates if the bar overflows
  (right group wins; overflowing left plugins hide).
- Hide/show: `/eg panel` (and right-click menu). Lock prevents reordering by drag.

### Plugin API
```lua
ns.Everpanel.Add{
  id = "clock", label = "Clock", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
  side = "right",                 -- default side; user can move it
  text = function() return "21:05" end,          -- bar text (may include color codes)
  tooltip = function(tt) ... end,                -- optional; tt = GameTooltip, already owned
  onClick = function(button) ... end,            -- optional; button = "LeftButton"/"RightButton"
  events = { "BAG_UPDATE" },                     -- optional; redraw on these
  interval = 1,                                  -- optional; redraw every N seconds
  hidden = false,                                -- optional; default visibility
}
ns.Everpanel.Update(id)                          -- a plugin asks for a redraw
```
- Redraw only on the plugin's events or interval (one shared ticker at 0.5 s drives interval plugins).
- `text()` errors are caught (pcall); the plugin shows `?` and the error is printed once.

### Right-click menu (on empty bar or any plugin with no own right-click)
Show/hide each plugin; move left/right; move earlier/later; show icons; show labels; lock bar; hide bar.
Uses a simple skinned dropdown built from buttons (not `UIDropDownMenu`, to avoid taint).

### LibDataBroker (optional, off by default)
If `LibStub` and `LibDataBroker-1.1` are present and the setting is on, each LDB data object becomes a
plugin (`text` from `obj.text`, tooltip from `obj.OnTooltipShow`, click from `obj.OnClick`), redrawn on
LDB attribute-changed callbacks.

### Screen offset
- When shown, shift top-anchored Blizzard frames down by the bar height: `MinimapCluster`, `BuffFrame`,
  `PlayerFrame`, `TargetFrame` (only those currently anchored to the top of `UIParent`).
- Only out of combat; queued to `PLAYER_REGEN_ENABLED` otherwise. Re-applied on `PLAYER_ENTERING_WORLD`
  and `UI_SCALE_CHANGED`.
- Setting `offset = false` disables shifting (bar overlaps). If Edit Mode on the Forever client fights the
  shift (verify in game), default becomes `false`.

### Settings — `EvergreenDB.everpanel`
`{ shown=true, locked=false, icons=true, labels=false, offset=true, ldb=false,
   order={left={...ids}, right={...ids}}, hidden={[id]=true} }`

### Plugins

| id | Bar text | Tooltip | Click |
|---|---|---|---|
| `xp` | `24.1k/h · 14m` | XP section of tracker | toggle tracker panel |
| `gold` | `12g 40s · +1g 90s/h` | Gold section of tracker | toggle tracker panel |
| `clock` | `21:05` | server and local time | toggle server/local |
| `perf` | `60fps 45ms` | home/world latency | — |
| `location` | `Silverpine 45.2, 61.8` | zone, subzone | toggle world map |
| `bags` | `12/80` free | free/total per bag | toggle all bags |
| `durability` | `87%` (lowest item) | each slotted item % | toggle character frame |
| `ammo` | `1,240 arrows` | ammo, shards, reagents | — (hidden for classes that use none) |
| `guide` | current step, ≤40 chars | full step text | open guide |
| `everbuff` | `3 buffs` | who needs what | show Everbuff panel |
| `journal` | icon only | — | open journal |
| `friends` | `4` online | online friends list | toggle friends frame |
| `guild` | `12` online | online guild list | toggle guild frame |

Evergreen plugins read through small public functions added to the owning modules
(`ns.GuideCurrentStepText()`, `ns.EverbuffQueueInfo()`, `ns.JournalToggle()`); each plugin is skipped if
its module is disabled.

## Trackers

### Core (`Tracker.lua`)
- **Session**: starts at login (`PLAYER_LOGIN`) or on Reset. `elapsed` counts wall time while logged in.
- **Rolling window**: 15 one-minute buckets per stat (ring buffer keyed by `floor(GetTime()/60)`).
  Recent rate = sum of buckets / covered minutes (min 1).
- **Rate choice for estimates**: recent rate if session ≥ 3 min and recent rate > 0, else session rate.
- **Pop-up panel** (`Skin.Panel` "Evergreen Tracker"): XP section above Gold section; each section present
  only if its module is on. Buttons: Reset, History. Movable, position saved. `/eg track` toggles;
  `/eg track reset`, `/eg track history`.
- Registration: `ns.Tracker.AddSection{ id, title, draw(frame, y) -> y, tooltip(tt) }`.

### XP (`Tracker_XP.lua`)
- Gain: on `PLAYER_XP_UPDATE`, `delta = UnitXP - lastXP`; if level went up, `delta = (lastMax - lastXP) + UnitXP`.
- Sources:
  - quest: `QUEST_TURNED_IN(questID, xpReward, moneyReward)` → `xpReward` credited to quests; the matching
    XP delta that follows is not double-counted (pending-quest amount subtracted from the next delta).
  - kill: `CHAT_MSG_COMBAT_XP_GAIN` with a kill pattern (built from the `COMBATLOG_XPGAIN_FIRSTPERSON*`
    globals) → amount credited to kills; count kills.
  - other: remainder.
- Shown: current/max, to go, rested (`GetXPExhaustion()`), XP/h session and last 15 min, time to level,
  kills to level (`toGo / avgKillXP`), quests to level (`toGo / avgQuestXP`), source split %.
- At max level (`UnitLevel == GetMaxPlayerLevel()`): section shows "max level", XP plugin hidden.
- Level times: on `PLAYER_LEVEL_UP`, call `RequestTimePlayed()`; on `TIME_PLAYED_MSG(total, thisLevel)`
  after a level-up, store `levelTimes[oldLevel] = thisLevel` (suppress the chat print while requesting).

### Gold (`Tracker_Gold.lua`)
- Change: on `PLAYER_MONEY`, `delta = GetMoney() - lastMoney`.
- Context flags set by events: `MERCHANT_SHOW/CLOSED`, `TRAINER_SHOW/CLOSED`, `MAIL_SHOW/CLOSED`,
  `AUCTION_HOUSE_SHOW/CLOSED`; repair flag set by hooking `RepairAllItems` (and repairing single items
  via the merchant cursor) for the next money change.
- Classification (first match):
  1. pending quest money from `QUEST_TURNED_IN` → quests
  2. `CHAT_MSG_MONEY` within 1 s ("You loot ...") → loot
  3. repair flag → repairs (out)
  4. trainer open → training (out)
  5. merchant open → gain: vendor, loss: purchases
  6. mailbox open, gain → auction (and mail); auction house open, loss → auction deposits/buyouts
  7. else → other (in/out)
- Shown: net this session, gold/h session and last 15 min (net), in-breakdown, out-breakdown.

### History — per character, `EvergreenCharDB.tracker` (existing per-character saved variable)
- `sessions`: last 20 `{ date, seconds, xp, money, levels }`, written on logout (`PLAYER_LOGOUT`) and on Reset.
- `levelTimes[level] = seconds`.
- History view (panel toggle / `/eg track history`): session list + level-time list.

## Error handling
- Every event handler body runs through one pcall wrapper per module that prints the first error once
  per session with the module name, so one bad plugin cannot break the bar.
- APIs missing on the client (`GetXPExhaustion`, `C_Map.GetPlayerMapPosition`, guild APIs) → the
  plugin/field is hidden, not errored.
- Coordinates unavailable (instances) → location shows zone only.

## Testing
- `addon/tools/test_harness.lua` gains an `EVERPANEL=1 TRACKER=1` mode:
  - stubs for the new APIs (`GetMoney`, `UnitXP`, `UnitXPMax`, `GetXPExhaustion`, `GetFramerate`,
    `GetNetStats`, `GetContainerNumFreeSlots`/`C_Container`, `GetInventoryItemDurability`, time played).
  - scripted sequence: login → kill XP ×3 → quest turn-in with XP+money → loot money → merchant sale →
    repair → level-up wrap → 20 simulated minutes → reset → logout.
  - asserts totals, source splits, rates (session and rolling), time to level, level wrap, level time
    recorded, saved history entry, every plugin `text()` returns a string, bar lays out with no error.
  - `OK tracker` / `OK everpanel` lines checked by `rebuild.sh`.
- In game: bar visible and shifted frames not overlapping; each plugin's tooltip and click; rates move
  after kills; gold categories after a vendor trip and repair; `/reload` keeps settings; history after relog.

## Build order
1. Everpanel core + Basics plugins → test in game.
2. Tracker core + XP + Gold (sections, plugins, history).
3. Gear, Evergreen, Social plugins.
4. (Separate spec) Journal map tab + boss viewer.
