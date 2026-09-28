# Forever API gap scan

Finds game functions an addon calls that the WoW Forever client doesn't have.

1. `cd "/e/Project HearthBreak/tools/forever-port" && python <here>/blizz_globals.py out/blizz_globals.json`
   reads every Blizzard Lua file and API doc in the Forever CASC (needs that repo's `casc` reader).
2. `grep -aoE '[A-Za-z_][A-Za-z0-9_]{3,}' WowB.exe | sort -u > exe_names.txt` (C functions).
3. `python scan_addon.py <AddOn folder> blizz_globals.json exe_names.txt`

Output lists capitalized calls not defined by the addon, Blizzard Lua or the exe, most-used first,
then `C_*` namespace calls missing from the docs. Expect noise from guide text and data files and
from methods called through locals; filter to the files the TOC loads.
