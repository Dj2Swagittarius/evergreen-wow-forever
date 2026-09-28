# !Everror: Lua errors that are easy to copy, and readable by Claude

## Goal
Copying a Lua error out of the Forever client is slow and noisy: Blizzard's popup shows one error at a
time, old errors linger across reloads, repeats show as one entry with a huge count, and locals
dump whole addon tables. `!Everror` keeps every error in a short format, groups them by
login/reload, offers a select-all copy window, and saves them to SavedVariables so Claude can read
them straight from `WTF` without any pasting.

## Packaging
Standalone addon `addon/!Everror` (the `!` makes it load before every other addon, so it catches
load-time errors of everything, Evergreen included). Interface `16001, 11509`. SavedVariables
`EverrorDB`. Deployed by `addon/tools/rebuild.sh --deploy` next to Evergreen.

## Capture (Capture.lua)
- `seterrorhandler` with our handler at file load, chaining to the previous handler (Blizzard's
  `HandleLuaError`, which still logs and feeds the crash reporter).
- Stack/locals level computed the way Blizzard's Forever handler does:
  `GetCallstackHeight() - (GetErrorCallstackHeight() - 1)`, fallback level 4.
  `debuglocals(level, true)` skips functions and userdata.
- Re-entrancy guard; our own work runs in `pcall` so a bug here never hides the real error.
- Secret (inaccessible) messages are stored as `<secret message>`.
- `ADDON_ACTION_BLOCKED` / `ADDON_ACTION_FORBIDDEN` are recorded as kind `blocked`.
- Errors that arrive before `EverrorDB` is loaded are buffered and flushed at `ADDON_LOADED`.

## Storage and format (Core.lua, pure Lua, unit-tested)
- `EverrorDB.sessions`: newest last; each `{ id, start, kind = "login"|"reload", errors = {...} }`.
  A session starts at our `ADDON_LOADED`; `PLAYER_ENTERING_WORLD` sets its kind.
- Entry: `{ key, msg, stack, locals, addon, kind, count, first, last }`. Repeats within a session
  (same message + stack) bump `count` and `last`.
- Addon = first `Interface/AddOns/<Name>/` in message or stack that isn't `!Everror`.
- Stack: drop lines from `!Everror`, keep at most 20 lines.
- Locals: keep only top-level lines; a table local collapses to `name = <table>`; lines capped at
  160 chars, at most 25 lines.
- Limits: 10 sessions, 200 errors in total (oldest sessions' errors dropped first, the current
  session keeps a `dropped` counter once it alone exceeds the cap).
- Text format:
  ```
  == Session #12  09-27 23:09  reload  (2 errors) ==
  [x1469] ExampleGuide  23:01:23-23:05:10
  Message: ...
  Stack:
  ...
  Locals:
  ...
  ```

## UI (UI.lua)
- Error button: small red movable button `! N` (N = errors this session), hidden at 0, pulses on a
  new error; position saved. Click opens the window.
- Window: scrollable read-only multi-line edit box with all text selected and focused, so Ctrl+C
  copies. Buttons: This session, Last session, All, Clear, Close. Escape closes.
- Blizzard popup: while `EverrorDB.popupOff` (default on), CVar `scriptErrors` is set to 0; the old
  value is remembered and `/err popup` toggles back.
- Slash: `/err` (window), `/err clear`, `/err popup`, `/err help`; `/everror` alias.

## Testing
`addon/tools/test_everror.lua` (LuaJIT): dedupe and counts, session rollover and kinds, locals and
stack trimming, addon attribution, limits, text format. Added to `rebuild.sh`.
