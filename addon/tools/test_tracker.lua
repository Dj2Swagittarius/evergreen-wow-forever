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

-- (XP and gold checks are added by Tasks 4 and 5 here)

io.write(string.format("OK tracker: %d sections, %d chat lines\n", #T.sections, #printed))
