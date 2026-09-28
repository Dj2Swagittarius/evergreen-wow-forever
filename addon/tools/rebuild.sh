#!/usr/bin/env bash
# Rebuild everything generated from the hand routes, test it, and (with --deploy) copy the addon
# into the WoW Forever beta client. Run from addon/tools after editing any Routes_*.lua / Data.lua.
#   1. audit_routes.lua   -> docs/research/route-audit.md + Evergreen_Guide/Routes_Questie_Fixes.lua
#   2. export_route.lua   -> forsaken_b1-3.json   (route + Questie facts)
#   3. route_optimizer.py -> Evergreen_Guide/Routes_Forsaken_Opt.lua
#   4. build_journal.lua  -> Evergreen_Journal/Journal_Data.lua (AtlasLootClassic + Questie)
#   5. test_harness.lua   -> every Forever race x class played to level 30 (plus the optimized route), and the journal
set -e
cd "$(dirname "$0")"
LJ=/c/Users/DJ/AppData/Local/Programs/LuaJIT/bin/luajit
Q="/e/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/Questie/Database"
ADDONS_DIR="/e/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns"
ITERS=${ITERS:-400000}

echo "== audit"
# fixes are generated from the routes without the old fixes applied
mv ../Evergreen_Guide/Routes_Questie_Fixes.lua /tmp/eg_fixes_prev.lua 2>/dev/null || true
echo 'local ADDON, ns = ...' > ../Evergreen_Guide/Routes_Questie_Fixes.lua
$LJ audit_routes.lua "$Q" ../Evergreen_Guide /tmp/eg_audit_raw.md ../Evergreen_Guide/Routes_Questie_Fixes.lua > /dev/null
$LJ audit_routes.lua "$Q" ../Evergreen_Guide ../../docs/research/route-audit.md
for f in ../Evergreen/*.lua ../Evergreen_*/*.lua ../Evergreen_*/*/*.lua; do [ -f "$f" ] && $LJ -bl "$f" > /dev/null; done

echo "== journal data"
ALC=${ALC:-/c/Users/DJ/AppData/Local/Temp/claude/C--Users-DJ-Desktop-WoW-guide/43e0d1c3-b94e-403a-bb26-4747f7aaab4f/scratchpad/alc/AtlasLootClassic-master/AtlasLootClassic_DungeonsAndRaids/data.lua}
if [ ! -f "$ALC" ]; then
  mkdir -p /tmp/alc && curl -sfL -o /tmp/alc.zip https://github.com/Hoizame/AtlasLootClassic/archive/refs/heads/master.zip && unzip -o -q /tmp/alc.zip -d /tmp/alc
  ALC=/tmp/alc/AtlasLootClassic-master/AtlasLootClassic_DungeonsAndRaids/data.lua
fi
$LJ build_journal.lua "$ALC" "$Q" ../Evergreen_Journal/Journal_Data.lua forever_dungeons.lua

echo "== optimize"
$LJ export_route.lua "$Q" ../Evergreen_Guide forsaken 1 3 forsaken_b1-3.json
python route_optimizer.py forsaken_b1-3.json --out ../Evergreen_Guide/Routes_Forsaken_Opt.lua --iters "$ITERS" --seeds 4 | grep -vE "^  seed"

echo "== test"
fails=0; runs=0
run() { runs=$((runs+1)); out=$(FACTION=$4 MISSED=1 $LJ test_harness.lua ../Evergreen $1 $2 $3 30 2>&1)
  if ! echo "$out" | grep -q "^OK" || echo "$out" | grep "missed:" | grep -vq optional; then fails=$((fails+1)); echo "FAIL $1 $2 $3"; echo "$out" | tail -5; fi; }
for c in WARRIOR ROGUE PRIEST MAGE WARLOCK PALADIN; do run Scourge $c auto; run Scourge $c forsaken-opt; done
for c in WARRIOR HUNTER ROGUE SHAMAN WARLOCK MAGE; do run Orc $c auto; done
for c in WARRIOR HUNTER ROGUE PRIEST SHAMAN MAGE WARLOCK; do run Troll $c auto; done
for c in WARRIOR HUNTER SHAMAN DRUID; do run Tauren $c auto; done
for c in WARRIOR HUNTER ROGUE DRUID SHAMAN; do run Skyborne $c auto Horde; done
for c in WARRIOR PALADIN ROGUE PRIEST MAGE WARLOCK HUNTER; do run Human $c auto; done
for c in WARRIOR PALADIN HUNTER ROGUE PRIEST SHAMAN; do run Dwarf $c auto; done
for c in WARRIOR ROGUE MAGE WARLOCK PRIEST; do run Gnome $c auto; done
for c in WARRIOR HUNTER ROGUE PRIEST DRUID; do run NightElf $c auto; done
for c in WARRIOR HUNTER ROGUE DRUID MAGE; do run Skyborne $c auto Alliance; done
runs=$((runs+1)); if ! BUFFS=1 JOURNAL=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN | grep -q "^OK journal"; then fails=$((fails+1)); echo "FAIL journal"; fi
runs=$((runs+1)); if ! BUFFS=1 EVERPANEL=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN | grep -q "^OK everpanel"; then fails=$((fails+1)); echo "FAIL everpanel"; fi
runs=$((runs+1)); if ! TRACKER=1 $LJ test_harness.lua ../Evergreen Scourge PALADIN | grep -q "^OK tracker"; then fails=$((fails+1)); echo "FAIL tracker"; fi
runs=$((runs+1)); if ! $LJ test_everror.lua | grep -q "0 failed"; then fails=$((fails+1)); echo "FAIL everror"; fi
echo "test runs: $runs, failures: $fails"
[ "$fails" = 0 ] || exit 1

if [ "$1" = "--deploy" ]; then
  if tasklist 2>/dev/null | grep -qi "WowB.exe"; then echo "== deploy: beta client is running; files copied, restart the game to load new files"; fi
  # the core and every module addon, each replaced whole (settings live in WTF, not here)
  for d in ../Evergreen ../Evergreen_*/; do
    d="${d%/}"; name="$(basename "$d")"
    rm -rf "$ADDONS_DIR/$name"
    cp -r "$d" "$ADDONS_DIR/$name"
  done
  echo "== deployed Evergreen and its modules to $ADDONS_DIR"
  mkdir -p "$ADDONS_DIR/!Everror" && cp ../'!Everror'/*.toc ../'!Everror'/*.lua "$ADDONS_DIR/!Everror/"
  echo "== deployed !Everror"
fi
