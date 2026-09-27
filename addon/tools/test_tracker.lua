-- TRACKER=1 mode of test_harness.lua: tracker core, XP and gold accounting with a fake clock.
local ns, fire, printed = ...
local T = assert(ns.Tracker, "tracker module not loaded")
assert(T.enabled and T.panel, "tracker panel not built")
local function eq(a, b, what) assert(a == b, what .. ": expected " .. tostring(b) .. ", got " .. tostring(a)) end
local function near(a, b, what) assert(math.abs(a - b) < 0.01, what .. ": expected " .. b .. ", got " .. a) end

-- formatting
eq(T.FmtMoney(34205), "3g 42s 5c", "FmtMoney")
eq(T.FmtMoney(34205, true), "3g 42s", "FmtMoney short")
eq(T.FmtMoney(-3000, true), "-30s", "FmtMoney negative")
eq(T.FmtMoney(190, false, true), "+1s 90c", "FmtMoney signed")
eq(T.FmtNum(1240), "1,240", "FmtNum")
eq(T.FmtNum(24100), "24.1k", "FmtNum k")
eq(T.FmtTime(14 * 60 + 5), "14m", "FmtTime minutes")
eq(T.FmtTime(3900), "1h 05m", "FmtTime hours")

-- rates with a fake clock
local now = 1000
GetTime = function() return now end
T.Reset()
local s = T.NewStat()
T.Add(s, 600); now = now + 600          -- 600 in the first 10 minutes
near(T.SessionRate(s), 3600, "session rate")
near(T.RecentRate(s), 3600, "recent rate")
now = now + 20 * 60                     -- 20 quiet minutes: recent window empties
eq(T.RecentRate(s), 0, "recent rate after a break")
near(T.BestRate(s), T.SessionRate(s), "best rate falls back to the session rate")

-- the panel opens from /eg track
SlashCmdList.EVERGREEN("track")
assert(T.panel._shown, "/eg track did not open the panel")

-- ---------------------------------------------------------------- XP
local X = assert(T.XP, "XP tracker not loaded")
local xp, max, level = 100, 1000, 10
UnitXP = function() return xp end
UnitXPMax = function() return max end
UnitLevel = function() return level end
GetXPExhaustion = function() return 300 end
RequestTimePlayed = function() end
now = 5000; T.Reset(); X.Snapshot()

local _, amt = ("Gnoll dies, you gain 120 experience."):match(X.KILL)
eq(amt, "120", "kill pattern")
_, amt = ("Gnoll dies, you gain 180 experience. (+60 exp Rested bonus)"):match(X.KILL)
eq(amt, "180", "kill pattern with rested bonus")

for _ = 1, 3 do                           -- three kills of 100, a minute apart
  now = now + 60
  fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold dies, you gain 100 experience.")
  xp = xp + 100; fire("PLAYER_XP_UPDATE", "player")
end
eq(X.kills, 3, "kills"); eq(X.killXP, 300, "kill xp"); eq(X.stat.total, 300, "xp total")
now = now + 30
fire("QUEST_TURNED_IN", 123, 250, 0)      -- 250 xp, no money (gold is checked in Task 5)
xp = xp + 250; fire("PLAYER_XP_UPDATE", "player")
eq(X.questXP, 250, "quest xp")
now = now + 70                            -- level-up: 350 finishes level 10, 40 into level 11
level, xp, max = 11, 40, 1200
fire("PLAYER_XP_UPDATE", "player")
eq(X.stat.total, 300 + 250 + 350 + 40, "xp across a level-up")
near(T.SessionRate(X.stat), 940 / 280 * 3600, "xp per hour")

-- time per level from /played
X.RequestPlayed(); fire("TIME_PLAYED_MSG", 5000, 1200)   -- level 10 began at 3800 s played
fire("PLAYER_LEVEL_UP", 11); fire("TIME_PLAYED_MSG", 6000, 5)
eq(T.History().levelTimes[10], 2195, "time spent at level 10")
eq(X.levels, 1, "levels gained")

-- I1: UnitLevel can still report the old level on the update that drops XP (the wrap); the later
-- update that finally reports the new level must not be counted as a second wrap. Uses synthetic
-- lastXP/lastMax/lastLevel so it doesn't disturb the running totals checked below, then restores them.
do
  local savedStat = { total = X.stat.total, buckets = {} }
  for k, v in pairs(X.stat.buckets) do savedStat.buckets[k] = v end
  local savedLastXP, savedLastMax, savedLastLevel = X.lastXP, X.lastMax, X.lastLevel
  X.lastXP, X.lastMax, X.lastLevel = 900, 1000, 10
  local before = X.stat.total
  X.OnXP(50, 1200, 10)                    -- xp fell to 50 but UnitLevel still says 10: one wrap
  eq(X.lastLevel, 11, "a wrap while UnitLevel lags anticipates the new level")
  X.OnXP(60, 1200, 11)                    -- UnitLevel catches up, plus a small real gain
  eq(X.stat.total - before, (1000 - 900) + 50 + (60 - 50), "xp grew by the real amounts only, not a double wrap")
  X.stat, X.lastXP, X.lastMax, X.lastLevel = savedStat, savedLastXP, savedLastMax, savedLastLevel
end

-- /played: a reply that never comes times out and un-mutes the chat frame
local origDisplay = function() end
ChatFrame_DisplayTimePlayed = origDisplay
X.RequestPlayed()
now = now + 11                             -- past the 10s timeout, still no TIME_PLAYED_MSG
fire("EVERGREEN_TEST_NOOP")               -- flushes the timeout timer
eq(ChatFrame_DisplayTimePlayed, origDisplay, "/played timeout restores ChatFrame_DisplayTimePlayed")

-- /played: a second request while one is pending is queued, not dropped
local requests = 0
RequestTimePlayed = function() requests = requests + 1 end
X.RequestPlayed()                         -- request 1, pending
eq(requests, 1, "first RequestTimePlayed call")
X.RequestPlayed()                         -- overlap: request 2 queued behind request 1
eq(requests, 1, "no second call while one is pending")
fire("TIME_PLAYED_MSG", 7000, 10)         -- reply to request 1; request 2 should follow
eq(requests, 2, "queued request sent after the pending reply")

for _, l in ipairs(X.Lines()) do assert(type(l) == "string", "XP line not a string") end
assert(ns.Everpanel.byId.xp, "no XP plugin on Everpanel")
assert(type(ns.Everpanel.byId.xp.text()) == "string", "XP plugin text")

-- ---------------------------------------------------------------- gold
local G = assert(T.Gold, "gold tracker not loaded")
local money = 50000
GetMoney = function() return money end
G.last = money
local net0 = G.net.total
fire("QUEST_TURNED_IN", 124, 0, 15000); money = money + 15000; fire("PLAYER_MONEY")   -- quest event first
now = now + 10
money = money + 523; fire("PLAYER_MONEY"); fire("CHAT_MSG_MONEY", "You loot 5 Silver, 23 Copper")  -- chat after
now = now + 10
money = money + 7000; fire("PLAYER_MONEY"); fire("QUEST_TURNED_IN", 125, 0, 7000)     -- quest event after
fire("MERCHANT_SHOW")
money = money + 2000; fire("PLAYER_MONEY")
G.ctx.repair, G.ctx.repairAt = true, now              -- what the RepairAllItems hook sets
money = money - 700; fire("PLAYER_MONEY")
money = money - 300; fire("PLAYER_MONEY")
fire("MERCHANT_CLOSED")
money = money - 50; fire("PLAYER_MONEY")
eq(G.inc.quests, 22000, "quest money"); eq(G.inc.loot, 523, "loot"); eq(G.inc.vendor, 2000, "vendor")
eq(G.inc.other, 0, "nothing left in other income")
eq(G.out.repairs, 700, "repairs"); eq(G.out.purchases, 300, "purchases"); eq(G.out.other, 50, "other spending")
eq(G.net.total - net0, 22000 + 523 + 2000 - 700 - 300 - 50, "net money")
for _, l in ipairs(G.Lines()) do assert(type(l) == "string", "gold line not a string") end
assert(type(ns.Everpanel.byId.gold.text()) == "string", "gold plugin text")

-- quest money that never arrives expires: a reward that outlives QUEST_WINDOW no longer reclassifies
-- a later, unrelated gain as "quests"
fire("QUEST_TURNED_IN", 126, 0, 500)
now = now + 10                                          -- past QUEST_WINDOW (3s): the 500 expires
money = money + 200; fire("PLAYER_MONEY")
eq(G.inc.quests, 22000, "expired quest money is not claimed")
eq(G.inc.other, 200, "expired quest money falls to other")

-- a missed MERCHANT_CLOSED sticks the flag; once MerchantFrame exists and is hidden, the flag is
-- verified against it and ignored
fire("MERCHANT_SHOW")
CreateFrame("Frame", "MerchantFrame")
MerchantFrame:Hide()                                    -- the CLOSED event never fired
money = money + 100; fire("PLAYER_MONEY")
eq(G.inc.vendor, 2000, "stuck merchant flag (frame hidden) is not counted as vendor")
eq(G.inc.other, 300, "gain during a stuck-but-hidden merchant flag falls to other")
MerchantFrame = nil

-- loot amount: an "other" gain is only reclaimed as loot when the parsed chat amount matches it
money = money + 300; fire("PLAYER_MONEY")
fire("CHAT_MSG_MONEY", "You loot 2 Silver")             -- 200 copper: does not match the 300 gain
eq(G.inc.loot, 523, "unequal loot chat amount does not reclaim an other gain")
eq(G.inc.other, 600, "mismatched loot amount leaves the gain as other")

-- Minor b: a stale repair flag (e.g. a guild-bank repair, which never touches your money) must not
-- linger and swallow a later, unrelated loss
G.ctx.repair, G.ctx.repairAt = true, now
now = now + 3                                           -- past the 2s repair window
money = money - 400; fire("PLAYER_MONEY")
eq(G.out.repairs, 700, "a stale repair flag must not classify a later loss as a repair")
eq(G.out.other, 450, "the late loss instead falls to other")

-- ---------------------------------------------------------------- I2: reload / relog never split a session
-- Firing a global ADDON_LOADED here would re-run every module's own ADDON_LOADED handler (Everpanel
-- rebuilds its bar, XP/Gold re-register their sections, duplicating T.sections) -- not harmless in a
-- single running Lua state the way a real /reload (a fresh Lua environment) is. So this drives the
-- tracker's own load path directly, ns.Tracker.LoadLive(), the function Tracker.lua's ADDON_LOADED
-- handler calls.
local histCount = #T.History().sessions
local xpTotal, goldTotal = X.stat.total, G.net.total

-- "reload": PLAYER_LOGOUT saves the live session; loading it back restores it in place
local elapsedAtLogout = T.Elapsed()
fire("PLAYER_LOGOUT")
assert(T.History().live, "PLAYER_LOGOUT did not save the live session")
T.LoadLive()
eq(X.stat.total, xpTotal, "xp total survives a reload")
eq(G.net.total, goldTotal, "gold total survives a reload")
near(T.Elapsed(), elapsedAtLogout, "session elapsed survives a reload")
eq(#T.History().sessions, histCount, "a reload must not write a history entry")
assert(not T.History().live, "the live snapshot is consumed once loaded")

-- "relog": the clock advances an hour before the tracker loads; the offline hour must not count
local elapsedBeforeRelog = T.Elapsed()
fire("PLAYER_LOGOUT")
now = now + 3600
T.LoadLive()
eq(X.stat.total, xpTotal, "xp total survives a relog")
eq(G.net.total, goldTotal, "gold total survives a relog")
near(T.Elapsed(), elapsedBeforeRelog, "a relog does not count the offline hour")
eq(#T.History().sessions, histCount, "a relog must not write a history entry either")

-- ---------------------------------------------------------------- history and max level
now = now + 600
T.Reset()
local e = T.History().sessions[1]
assert(e, "session not saved on reset")
eq(e.xp, 940, "saved session xp"); eq(e.levels, 1, "saved session levels")
eq(e.money, 22000 + 523 + 2000 - 700 - 300 - 50 + 200 + 100 + 300 - 400 + net0, "saved session money")
eq(X.stat.total, 0, "xp reset"); eq(G.net.total, 0, "gold reset")
level = 60
assert(X.Lines()[1]:find("max level", 1, true), "max level line")
assert(not ns.Everpanel.Visible("xp"), "XP plugin should hide at max level")
T.showHistory = true; T.Refresh()
assert(T.panel.body:GetText():find("level 10", 1, true), "history shows level times")

io.write(string.format("OK tracker: %d sections, %d chat lines\n", #T.sections, #printed))
