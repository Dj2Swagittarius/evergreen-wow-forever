-- Gold tracker: net gold per hour (session and last 15 minutes), income by source (loot, vendor,
-- quests, auction, other) and spending (repairs, training, purchases, auction, other).
-- Each money change is sorted by what is going on at that moment (merchant, trainer, mailbox, ...).

local ADDON, ns = ...
local T = ns.Tracker
local HEX = ns.Skin.HEX

local G = { ctx = {} }
T.Gold = G
local IN = { "loot", "vendor", "quests", "auction", "other" }
local OUT = { "repairs", "training", "purchases", "auction", "other" }
local MATCH_S = 1        -- seconds within which a chat line / quest event belongs to a money change
local QUEST_WINDOW = 3   -- seconds a quest's reward money stays claimable before it expires (gold cap,
                          -- a dropped PLAYER_MONEY, ...) so it never reclassifies later unrelated income

function G.Reset()
  G.net = T.NewStat()
  G.inc, G.out = {}, {}
  for _, k in ipairs(IN) do G.inc[k] = 0 end
  for _, k in ipairs(OUT) do G.out[k] = 0 end
  G.lastOther = nil
  -- one-shot pending state only; the merchant/trainer/mail/auction window flags survive a reset
  -- (they track whatever Blizzard frame is actually open right now)
  local c = G.ctx
  c.questMoney, c.questAt, c.lootAt, c.lootAmount, c.repair = nil, nil, nil, nil, nil
end
G.Reset()

-- "%d Gold" (client format string) -> a Lua pattern capturing the amount; falls back to English
-- when the global isn't available (e.g. headless tests).
local function AmountPattern(fmt)
  local p = (fmt or ""):gsub("%%d", "\1")
  p = p:gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
  return p:gsub("\1", "(%%d+)")
end
local GOLD_P = AmountPattern(GOLD_AMOUNT or "%d Gold")
local SILVER_P = AmountPattern(SILVER_AMOUNT or "%d Silver")
local COPPER_P = AmountPattern(COPPER_AMOUNT or "%d Copper")

-- Parses copper out of a CHAT_MSG_MONEY line ("You loot 5 Silver, 23 Copper", or in a group "Your
-- share of the loot is ..." - the same three amount patterns cover both). Returns nil when none of
-- the patterns match (unrecognized locale), so the caller falls back to timing-only matching.
local function ParseCopper(msg)
  if not msg then return nil end
  local g, s, c = msg:match(GOLD_P), msg:match(SILVER_P), msg:match(COPPER_P)
  if not (g or s or c) then return nil end
  return (tonumber(g) or 0) * 10000 + (tonumber(s) or 0) * 100 + (tonumber(c) or 0)
end

-- A window flag (merchant/trainer/mail/auction) sticks if its *_CLOSED event is missed. Trust it
-- only while the matching Blizzard frame is actually shown, when that frame exists; if the frame
-- exists and is hidden, the flag is stale, so clear it. If no such frame global exists, there is
-- nothing to check against, so keep trusting the event-driven flag.
local FRAME_NAMES = {
  merchant = { "MerchantFrame" },
  trainer = { "ClassTrainerFrame" },
  mail = { "MailFrame" },
  auction = { "AuctionHouseFrame", "AuctionFrame" },
}
local function WindowOpen(key)
  local c = G.ctx
  if not c[key] then return false end
  for _, name in ipairs(FRAME_NAMES[key] or {}) do
    local f = _G[name]
    if f then
      if f:IsShown() then return true end
      c[key] = nil
      return false
    end
  end
  return true
end

function G.Classify(delta, now)
  now = now or GetTime()
  local c = G.ctx
  if delta > 0 and (c.questMoney or 0) > 0 then
    if c.questAt and now - c.questAt <= QUEST_WINDOW then
      c.questMoney = math.max(0, c.questMoney - delta)
      return "quests"
    end
    c.questMoney, c.questAt = nil, nil   -- expired: never claimed by a matching money change
  end
  if delta > 0 and c.lootAt and now - c.lootAt <= MATCH_S then
    if not c.lootAmount or c.lootAmount == delta then
      c.lootAt, c.lootAmount = nil, nil
      return "loot"
    end
  end
  if delta < 0 and c.repair then c.repair = nil; return "repairs" end
  if delta < 0 and WindowOpen("trainer") then return "training" end
  if WindowOpen("merchant") then return delta > 0 and "vendor" or "purchases" end
  if delta > 0 and WindowOpen("mail") then return "auction" end
  if delta < 0 and WindowOpen("auction") then return "auction" end
  return "other"
end

function G.OnMoney(money, now)
  now = now or GetTime()
  local delta = money - (G.last or money)
  G.last = money
  if delta == 0 then return nil end
  local cat = G.Classify(delta, now)
  if delta > 0 then G.inc[cat] = G.inc[cat] + delta else G.out[cat] = G.out[cat] - delta end
  T.Add(G.net, delta, now)
  G.lastOther = (cat == "other" and delta > 0) and { amount = delta, at = now } or nil
  return cat
end

-- The loot chat line and the quest event can each arrive before or after the money change.
local function Reclaim(cat, amount, now)
  local o = G.lastOther
  if o and now - o.at <= MATCH_S and (not amount or o.amount == amount) then
    G.inc.other = G.inc.other - o.amount
    G.inc[cat] = G.inc[cat] + o.amount
    G.lastOther = nil
    return true
  end
end

function G.OnLootChat(msg, now)
  now = now or GetTime()
  local amount = ParseCopper(msg)
  if not Reclaim("loot", amount, now) then
    G.ctx.lootAt = now
    G.ctx.lootAmount = amount   -- nil when unparsed: Classify then matches on timing alone
  end
end

function G.OnQuestMoney(amount, now)
  now = now or GetTime()
  amount = tonumber(amount) or 0
  if amount <= 0 then return end
  if not Reclaim("quests", amount, now) then
    G.ctx.questMoney = (G.ctx.questMoney or 0) + amount
    G.ctx.questAt = now
  end
end

local function List(t, keys)
  local parts = {}
  for _, k in ipairs(keys) do if t[k] > 0 then parts[#parts + 1] = k .. " " .. T.FmtMoney(t[k], true) end end
  return #parts > 0 and table.concat(parts, "  ·  ") or (HEX.muted .. "none|r")
end

function G.Lines()
  return {
    "net  " .. T.FmtMoney(G.net.total, true, true) .. HEX.muted .. "  this session|r",
    "per hour  session " .. T.FmtMoney(T.SessionRate(G.net), true, true) .. "  ·  last 15m " .. T.FmtMoney(T.RecentRate(G.net), true, true),
    "in   " .. List(G.inc, IN),
    "out  " .. List(G.out, OUT),
  }
end

function G.BarText()
  return T.FmtMoney((GetMoney and GetMoney()) or 0, true) .. " · " .. T.FmtMoney(T.BestRate(G.net), true, true) .. "/h"
end

local CONTEXT = {
  MERCHANT_SHOW = { "merchant", true }, MERCHANT_CLOSED = { "merchant", nil },
  TRAINER_SHOW = { "trainer", true }, TRAINER_CLOSED = { "trainer", nil },
  MAIL_SHOW = { "mail", true }, MAIL_CLOSED = { "mail", nil },
  AUCTION_HOUSE_SHOW = { "auction", true }, AUCTION_HOUSE_CLOSED = { "auction", nil },
}

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, event, a1, a2, a3)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    if not ns.ModuleEnabled("gold") then self:UnregisterAllEvents(); return end
    for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_MONEY", "CHAT_MSG_MONEY", "QUEST_TURNED_IN" }) do
      pcall(self.RegisterEvent, self, e)
    end
    for e in pairs(CONTEXT) do pcall(self.RegisterEvent, self, e) end
    if hooksecurefunc and RepairAllItems then hooksecurefunc("RepairAllItems", function() G.ctx.repair = true end) end
    T.AddSection{ id = "gold", title = "Gold", lines = G.Lines, reset = G.Reset,
      summary = function() return { money = G.net.total } end }
    if ns.Everpanel then
      ns.Everpanel.Add{ id = "gold", label = "Gold", side = "right", icon = "Interface\\Icons\\INV_Misc_Coin_01",
        events = { "PLAYER_MONEY" }, interval = 5, text = G.BarText,
        tooltip = function(tt)
          for _, l in ipairs(G.Lines()) do tt:AddLine(l, 1, 1, 1) end
          tt:AddLine("Click: tracker panel", 0.6, 0.6, 0.6)
        end,
        onClick = function() T.Toggle() end }
    end
  elseif event == "PLAYER_LOGIN" then
    G.last = (GetMoney and GetMoney()) or 0
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- a missed *_CLOSED event would otherwise strand an open window flag across zone loads
    local c = G.ctx
    c.merchant, c.trainer, c.mail, c.auction = nil, nil, nil, nil
  elseif event == "PLAYER_MONEY" then
    G.OnMoney((GetMoney and GetMoney()) or 0)
    T.Refresh()
  elseif event == "CHAT_MSG_MONEY" then
    G.OnLootChat(a1)
  elseif event == "QUEST_TURNED_IN" then
    G.OnQuestMoney(a3)
  elseif CONTEXT[event] then
    G.ctx[CONTEXT[event][1]] = CONTEXT[event][2]
    if event == "MERCHANT_CLOSED" then G.ctx.repair = nil end
  end
end)
