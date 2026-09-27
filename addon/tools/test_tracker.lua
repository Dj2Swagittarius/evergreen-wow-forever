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

for _, l in ipairs(X.Lines()) do assert(type(l) == "string", "XP line not a string") end
assert(ns.Everpanel.byId.xp, "no XP plugin on Everpanel")
assert(type(ns.Everpanel.byId.xp.text()) == "string", "XP plugin text")

-- (gold checks are added by Task 5 here)

io.write(string.format("OK tracker: %d sections, %d chat lines\n", #T.sections, #printed))
