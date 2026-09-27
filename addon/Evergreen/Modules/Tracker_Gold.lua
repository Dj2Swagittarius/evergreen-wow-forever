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
local MATCH_S = 1   -- seconds within which a chat line / quest event belongs to a money change

function G.Reset()
  G.net = T.NewStat()
  G.inc, G.out = {}, {}
  for _, k in ipairs(IN) do G.inc[k] = 0 end
  for _, k in ipairs(OUT) do G.out[k] = 0 end
  G.lastOther = nil
end
G.Reset()

function G.Classify(delta, now)
  now = now or GetTime()
  local c = G.ctx
  if delta > 0 and (c.questMoney or 0) > 0 then c.questMoney = math.max(0, c.questMoney - delta); return "quests" end
  if delta > 0 and c.lootAt and now - c.lootAt <= MATCH_S then c.lootAt = nil; return "loot" end
  if delta < 0 and c.repair then c.repair = nil; return "repairs" end
  if delta < 0 and c.trainer then return "training" end
  if c.merchant then return delta > 0 and "vendor" or "purchases" end
  if delta > 0 and c.mail then return "auction" end
  if delta < 0 and c.auction then return "auction" end
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

function G.OnLootChat(now)
  now = now or GetTime()
  if not Reclaim("loot", nil, now) then G.ctx.lootAt = now end
end

function G.OnQuestMoney(amount, now)
  now = now or GetTime()
  amount = tonumber(amount) or 0
  if amount <= 0 then return end
  if not Reclaim("quests", amount, now) then G.ctx.questMoney = (G.ctx.questMoney or 0) + amount end
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
    for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_MONEY", "CHAT_MSG_MONEY", "QUEST_TURNED_IN" }) do pcall(self.RegisterEvent, self, e) end
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
  elseif event == "PLAYER_MONEY" then
    G.OnMoney((GetMoney and GetMoney()) or 0)
    T.Refresh()
  elseif event == "CHAT_MSG_MONEY" then
    G.OnLootChat()
  elseif event == "QUEST_TURNED_IN" then
    G.OnQuestMoney(a3)
  elseif CONTEXT[event] then
    G.ctx[CONTEXT[event][1]] = CONTEXT[event][2]
    if event == "MERCHANT_CLOSED" then G.ctx.repair = nil end
  end
end)
