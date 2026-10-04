-- Evertaxi game side: the window, posting the advert to chosen chats, and watching chat for people
-- who want a warlock summon to where you are (warlocks) or a portal to your cities (mages).
local ADDON, ns = ...
local C = ns.Core

local PURPLE = "|cffb080ff"
local function say(text) print(PURPLE .. "Evertaxi:|r " .. text) end
ns.Say = say

local function usable(v)
  return v ~= nil and not (issecretvalue and issecretvalue(v))
end

local MAX_REQUESTS = 30
local POST_COOLDOWN = 30
local SHOWN_REQUESTS = 6

local db, texts
local win
local placeBoxes, channelBoxes, requestRows, castButtons = {}, {}, {}, {}
local requests = {} -- newest first: { name, msg, t, where, place, channel }
local lastPost = 0

---------------------------------------------------------------------------
-- Class mode, spells
---------------------------------------------------------------------------
-- "summon" for warlocks, "portal" for mages; /taxi mode can switch it (for trying it out).
function ns.Mode()
  if db and db.mode then return db.mode end
  local _, class = UnitClass("player")
  return class == "MAGE" and "portal" or "summon"
end

local function spellInfo(id)
  if C_Spell and C_Spell.GetSpellInfo then
    local i = C_Spell.GetSpellInfo(id)
    if i then return i.name, i.iconID end
  end
  if GetSpellInfo then
    local name, _, icon = GetSpellInfo(id)
    return name, icon
  end
end

local function knows(id)
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  if IsSpellKnown and IsSpellKnown(id) then return true end
  if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id) then return true end
  return false
end

-- A portal by its ID, or else by its name ("Portal: Orgrimmar"), in case Forever numbers it
-- differently. Returns true, the spell ID found by name, or false.
local function portalKnown(id, city)
  if knows(id) then return true end
  local name, rid = "Portal: " .. city, nil
  if C_Spell and C_Spell.GetSpellInfo then
    local i = C_Spell.GetSpellInfo(name)
    rid = i and i.spellID
  elseif GetSpellInfo then
    rid = select(7, GetSpellInfo(name))
  end
  if rid and knows(rid) then return rid end
  return false
end

---------------------------------------------------------------------------
-- Where we are, and the places we serve
---------------------------------------------------------------------------
local function zone()
  local z = GetRealZoneText and GetRealZoneText() or GetZoneText()
  return (z and z ~= "") and z or "?"
end

local function subzone()
  local s = GetSubZoneText and GetSubZoneText()
  return (s and s ~= "") and s or nil
end

-- Warlock: this zone's names plus the player's own. Mage: the faction's portal cities.
local function allPlaces()
  if ns.Mode() == "portal" then return C.PortalPlaces(UnitFactionGroup("player"), portalKnown) end
  local z = zone()
  local list = C.PlacesFor(z, subzone())
  local seen = {}
  for _, p in ipairs(list) do seen[p.label] = true end
  for _, w in ipairs(db.extra[z] or {}) do
    if not seen[w] then seen[w] = true; list[#list + 1] = { label = w, words = { w } } end
  end
  return list
end

local function isOn(p) return p.known ~= false and not db.off[p.label] end

local function activePlaces()
  local out = {}
  for _, p in ipairs(allPlaces()) do if isOn(p) then out[#out + 1] = p end end
  return out
end

local function vars()
  local labels = {}
  for _, p in ipairs(activePlaces()) do labels[#labels + 1] = p.label end
  return {
    zone = subzone() and (subzone() .. ", " .. zone()) or zone(), price = db.price, name = UnitName("player"),
    places = #labels > 0 and table.concat(labels, ", ") or "?",
  }
end

---------------------------------------------------------------------------
-- Chats to post in: say, yell, guild and every joined channel
---------------------------------------------------------------------------
local function chatTargets()
  local out = { { key = "SAY", label = "Say" }, { key = "YELL", label = "Yell" } }
  if IsInGuild and IsInGuild() then out[#out + 1] = { key = "GUILD", label = "Guild" } end
  local list = { GetChannelList() }
  for i = 1, #list, 3 do
    local id, name, disabled = list[i], list[i + 1], list[i + 2]
    if id and name and not disabled then
      out[#out + 1] = { key = "CHANNEL:" .. name, label = id .. ". " .. name, name = name }
    end
  end
  return out
end

function ns.Post()
  local left = POST_COOLDOWN - (time() - lastPost)
  if left > 0 then say(("wait %ds before posting again (so the chats don't get spammed)."):format(left)); return end
  local text = C.Fill(texts().ad, vars()):sub(1, 255)
  if text:match("^%s*$") then say("write your advert first."); return end
  local sent = {}
  for _, t in ipairs(chatTargets()) do
    if db.chats[t.key] then
      if t.name then
        -- channel numbers can change; look the name up again
        local id = GetChannelName(t.name)
        if id and id > 0 then SendChatMessage(text, "CHANNEL", nil, id); sent[#sent + 1] = t.name end
      else
        SendChatMessage(text, t.key); sent[#sent + 1] = t.label
      end
    end
  end
  if #sent == 0 then say("tick at least one chat to post in."); return end
  lastPost = time()
  say("posted to " .. table.concat(sent, ", ") .. ".")
end

---------------------------------------------------------------------------
-- Requests
---------------------------------------------------------------------------
function ns.Reply(r)
  local text = C.Fill(texts().reply, vars())
  if r.place and ns.Mode() == "portal" then text = text:gsub("port you", "port you to " .. r.place, 1) end
  SendChatMessage(text:sub(1, 255), "WHISPER", nil, r.name)
  r.replied = true
  ns.Refresh()
end

function ns.Invite(r)
  if C_PartyInfo and C_PartyInfo.InviteUnit then C_PartyInfo.InviteUnit(r.name) else InviteUnit(r.name) end
  r.invited = true
  ns.Refresh()
end

local function addRequest(r)
  -- same person again within a few minutes: replace their line
  for i, old in ipairs(requests) do
    if old.name == r.name and r.t - old.t < 300 then table.remove(requests, i); break end
  end
  table.insert(requests, 1, r)
  while #requests > MAX_REQUESTS do table.remove(requests) end
  ns.Refresh()
end

local WHISPER_WORDS = { "sum", "summ", "summon", "summons", "inv", "invite", "port", "portal", "lock", "mage" }

function ns.OnChat(event, msg, author, _, _, _, _, _, _, channelName)
  if not db.open or not usable(msg) or not usable(author) then return end
  local short = author:match("^([^%-]+)") or author
  if short == UnitName("player") then return end
  local where, place = C.Classify(msg, activePlaces(), ns.Mode())
  if event == "CHAT_MSG_WHISPER" then
    -- a whisper is someone answering our advert
    if not where then
      for _, w in ipairs(WHISPER_WORDS) do if C.HasWord(msg, w) then where = "here" break end end
    elseif where == "elsewhere" and ns.Mode() == "summon" then
      where = "here"
    end
  end
  if not where or (where == "elsewhere" and not db.showElsewhere) then return end
  local chan = event == "CHAT_MSG_CHANNEL" and usable(channelName) and channelName or event:gsub("CHAT_MSG_", ""):lower()
  local r = { name = author, msg = msg, t = time(), where = where, place = place, channel = chan }
  addRequest(r)
  if where == "here" then
    PlaySound(SOUNDKIT and SOUNDKIT.READY_CHECK or 8960)
    say(("|Hplayer:%s|h[%s]|h wants a %s%s: %s"):format(author, short, ns.Mode(), place and (" (" .. place .. ")") or "", msg))
    if db.autoReply and event == "CHAT_MSG_WHISPER" then ns.Reply(r) end
  end
end

---------------------------------------------------------------------------
-- Cast buttons (Ritual of Summoning / each portal). Secure, so they live on UIParent: a protected
-- child would stop the window itself from opening or closing in combat.
---------------------------------------------------------------------------
local RITUAL = 698

local function castSpells()
  if ns.Mode() == "portal" then
    local out = {}
    for _, p in ipairs(C.PortalPlaces(UnitFactionGroup("player"), portalKnown)) do
      if p.known then out[#out + 1] = p.spell end
    end
    return out
  end
  return { RITUAL }
end

local function syncCastButtons()
  if InCombatLockdown() then ns.castPending = true; return end
  ns.castPending = nil
  local spells = win and win:IsShown() and castSpells() or {}
  for i = 1, math.max(#spells, #castButtons) do
    local id = spells[i]
    local b = castButtons[i]
    if id and not b then
      b = CreateFrame("Button", "EvertaxiCast" .. i, UIParent, "SecureActionButtonTemplate")
      b:SetSize(32, 32)
      b:SetFrameStrata("DIALOG")
      b:SetFrameLevel(win:GetFrameLevel() + 20)
      b:RegisterForClicks("AnyUp", "AnyDown")
      b.Icon = b:CreateTexture(nil, "ARTWORK")
      b.Icon:SetAllPoints()
      b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(self.spellName or "?")
        if self.spellID == RITUAL then GameTooltip:AddLine("Target the party member to summon, then click.", 1, 1, 1) end
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave", function() GameTooltip:Hide() end)
      castButtons[i] = b
    end
    if b then
      if id then
        local name, icon = spellInfo(id)
        b.spellID, b.spellName = id, name
        b:SetAttribute("type", "spell")
        b:SetAttribute("spell", name or id)
        b.Icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        b:ClearAllPoints()
        b:SetPoint("TOPRIGHT", win, "TOPRIGHT", -14 - (i - 1) * 36, win.top - 8)
        b:Show()
      else
        b:Hide()
      end
    end
  end
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local Skin = ns.Skin
local W = 428 -- content width
local check = Skin.Check

local function button(parent, label, w, h, onClick) return Skin.Button(parent, label, w, h, onClick) end

local function heading(text, anchor, y)
  local fs = Skin.Text(win, "GameFontNormal", text)
  fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y or -10)
  return fs
end

local function grid(container, boxes, items, cols, colW, setup)
  for _, b in ipairs(boxes) do b:Hide() end
  for i, item in ipairs(items) do
    local b = boxes[i]
    if not b then
      b = check(container, "", function(self) self.onToggle(self:GetChecked() and true or false) end)
      b.Label:SetWidth(colW - 26)
      if b.Label.SetWordWrap then b.Label:SetWordWrap(false) end
      boxes[i] = b
    end
    setup(b, item)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", ((i - 1) % cols) * colW, -math.floor((i - 1) / cols) * 22)
    b:Show()
  end
  container:SetHeight(math.max(22, math.ceil(#items / cols) * 22))
end

local function ago(t)
  local s = time() - t
  if s < 60 then return s .. "s" end
  if s < 3600 then return math.floor(s / 60) .. "m" end
  return math.floor(s / 3600) .. "h"
end

function ns.Refresh()
  if not win or not win:IsShown() then return end
  local portal = ns.Mode() == "portal"
  local H = Skin.HEX
  win.Sub:SetText(portal and "|cff69ccf0Mage|r portal service" or (PURPLE .. "Warlock|r summoning service"))
  win.Open:SetText(db.open and (H.green .. "Open for business|r") or "Closed - click to open")
  win.OpenGlow:SetShown(db.open)
  local places = allPlaces()
  local unknown = false
  for _, p in ipairs(places) do if p.known == false then unknown = true end end
  local here = ("You are in %s%s|r%s."):format(H.white, zone(), subzone() and (" (" .. H.white .. subzone() .. "|r)") or "")
  win.Where:SetText(here .. (portal and " Portals to:" or " Listening for:")
    .. (unknown and (" " .. H.muted .. "(grey = not learned yet)|r") or ""))
  grid(win.Places, placeBoxes, places, portal and 3 or 4, W / (portal and 3 or 4), function(b, p)
    b.Label:SetText(p.known == false and (H.muted .. p.label .. "|r") or p.label)
    b:SetChecked(isOn(p))
    b:SetEnabled(p.known ~= false)
    b.onToggle = function(on) db.off[p.label] = not on or nil end
  end)
  win.AddPlace:SetShown(not portal)
  win.AddPlaceButton:SetShown(not portal)
  win.Elsewhere:ClearAllPoints()
  win.Elsewhere:SetPoint("TOPLEFT", portal and win.Places or win.AddPlace, "BOTTOMLEFT", portal and -2 or -8, -2)
  grid(win.Chats, channelBoxes, chatTargets(), 3, W / 3, function(b, t)
    b.Label:SetText(t.label)
    b:SetChecked(db.chats[t.key] and true or false)
    b.onToggle = function(on) db.chats[t.key] = on or nil end
  end)
  local left = POST_COOLDOWN - (time() - lastPost)
  win.Post:SetText(left > 0 and ("Post (%ds)"):format(left) or "Post advert")
  win.Preview:SetText(H.muted .. "Preview:|r " .. C.Fill(texts().ad, vars()))
  win.Hint:SetText(portal and "{zone} = where you are, {places} = ticked cities, {price} = price box"
    or "{zone} = where you are, {price} = the price box, {name} = you")
  for i, row in ipairs(requestRows) do
    local r = requests[i]
    row.req = r
    row:SetShown(r ~= nil)
    if r then
      local color = r.where == "here" and H.white or H.muted
      row.Text:SetText(("%s%s|r %s%s ago, %s:|r %s%s|r"):format(color, r.name:match("^([^%-]+)") or r.name,
        H.muted, ago(r.t), r.channel or "?", color, r.msg))
      row.Reply:SetText(r.replied and "Sent" or "Reply")
      row.Invite:SetText(r.invited and "Sent" or "Invite")
    end
  end
  win.NoRequests:SetShown(#requests == 0)
end

local function buildWindow()
  win = Skin.Window("EvertaxiFrame", 460, 660, "Evertaxi")
  -- the cast buttons are anchored here; moving them is not allowed in combat
  win:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
  local x0 = 16

  -- the player, beside the round portrait
  win.Name = Skin.Text(win, "GameFontNormalLarge")
  win.Name:SetPoint("TOPLEFT", win.portraitW + 12, win.top - 8)
  win.Sub = Skin.Text(win, "GameFontHighlightSmall")
  win.Sub:SetPoint("TOPLEFT", win.Name, "BOTTOMLEFT", 0, -4)

  -- open for business
  win.Open = button(win, "", W, 30, function()
    db.open = not db.open
    say(db.open and "open for business - watching chat for requests." or "closed.")
    ns.Refresh()
  end)
  win.Open:SetPoint("TOPLEFT", x0, win.top - 50)
  win.OpenGlow = win.Open:CreateTexture(nil, "BACKGROUND")
  win.OpenGlow:SetPoint("TOPLEFT", -3, 3)
  win.OpenGlow:SetPoint("BOTTOMRIGHT", 3, -3)
  win.OpenGlow:SetColorTexture(0.25, 0.75, 0.25, 0.45)

  -- where
  win.Where = Skin.Text(win, "GameFontHighlightSmall")
  win.Where:SetPoint("TOPLEFT", win.Open, "BOTTOMLEFT", 0, -10)
  win.Places = CreateFrame("Frame", nil, win)
  win.Places:SetSize(W, 22)
  win.Places:SetPoint("TOPLEFT", win.Where, "BOTTOMLEFT", 0, -4)
  win.AddPlace = Skin.Edit(win, 150, 20)
  win.AddPlace:SetPoint("TOPLEFT", win.Places, "BOTTOMLEFT", 6, -4)
  local function add()
    local p = win.AddPlace.Edit:GetText():lower():gsub("^%s+", ""):gsub("%s+$", "")
    if p ~= "" then
      local z = zone()
      db.extra[z] = db.extra[z] or {}
      table.insert(db.extra[z], p)
      db.off[p] = nil
    end
    win.AddPlace.Edit:SetText("")
    win.AddPlace.Edit:ClearFocus()
    ns.Refresh()
  end
  win.AddPlace.Edit:SetScript("OnEnterPressed", add)
  win.AddPlaceButton = button(win, "Add place", 90, 22, add)
  win.AddPlaceButton:SetPoint("LEFT", win.AddPlace, "RIGHT", 6, 0)
  win.Elsewhere = check(win, "Also list requests for other places", function(self)
    db.showElsewhere = self:GetChecked() and true or false
  end)
  win.Elsewhere:SetPoint("TOPLEFT", win.AddPlace, "BOTTOMLEFT", -8, -2)

  -- advert
  local adHead = heading("Advert", win.Elsewhere, -8)
  win.Price = Skin.Edit(win, 120, 20)
  win.Price:SetPoint("RIGHT", win, "LEFT", x0 + W, 0)
  win.Price:SetPoint("BOTTOM", adHead, "BOTTOM", 0, -3)
  local priceLabel = Skin.Text(win, "GameFontHighlightSmall", "Price {price}:")
  priceLabel:SetPoint("RIGHT", win.Price, "LEFT", -10, 0)
  win.Price.Edit:SetScript("OnTextChanged", function(self, user) if user then db.price = self:GetText(); ns.Refresh() end end)
  win.Ad = Skin.Edit(win, W, 52, true)
  win.Ad:SetPoint("TOPLEFT", adHead, "BOTTOMLEFT", 0, -6)
  win.Ad.Edit:SetScript("OnTextChanged", function(self, user) if user then texts().ad = self:GetText(); ns.Refresh() end end)
  win.Preview = Skin.Text(win, "GameFontHighlightSmall")
  win.Preview:SetPoint("TOPLEFT", win.Ad, "BOTTOMLEFT", 2, -4)
  win.Preview:SetWidth(W - 4)
  win.Hint = Skin.Text(win, "GameFontDisableSmall")
  win.Hint:SetPoint("TOPLEFT", win.Preview, "BOTTOMLEFT", 0, -2)

  -- chats
  local chatHead = heading("Post in", win.Hint, -10)
  win.Chats = CreateFrame("Frame", nil, win)
  win.Chats:SetSize(W, 22)
  win.Chats:SetPoint("TOPLEFT", chatHead, "BOTTOMLEFT", 0, -4)
  win.Post = button(win, "Post advert", 140, 24, function() ns.Post(); ns.Refresh() end)
  win.Post:SetPoint("TOPLEFT", win.Chats, "BOTTOMLEFT", 0, -6)

  -- requests: an inset list, like the quest log
  local reqHead = heading("Requests", win.Post, -12)
  win.Auto = check(win, "Auto-reply to whispers", function(self) db.autoReply = self:GetChecked() and true or false end)
  win.Auto:SetPoint("LEFT", win, "LEFT", x0 + W - 160, 0)
  win.Auto:SetPoint("BOTTOM", reqHead, "BOTTOM", 0, -5)
  local replyLabel = Skin.Text(win, "GameFontHighlightSmall", "Reply:")
  replyLabel:SetPoint("TOPLEFT", reqHead, "BOTTOMLEFT", 0, -10)
  win.ReplyText = Skin.Edit(win, W - 50, 20)
  win.ReplyText:SetPoint("LEFT", replyLabel, "RIGHT", 12, 0)
  win.ReplyText.Edit:SetScript("OnTextChanged", function(self, user) if user then texts().reply = self:GetText() end end)
  local list = Skin.Inset(win)
  list:SetPoint("TOPLEFT", replyLabel, "BOTTOMLEFT", 0, -10)
  list:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 12)
  local prev
  for i = 1, SHOWN_REQUESTS do
    local row = CreateFrame("Frame", nil, list)
    row:SetHeight(22)
    if prev then row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, 0) else row:SetPoint("TOPLEFT", 4, -4) end
    row:SetPoint("RIGHT", list, "RIGHT", -4, 0)
    Skin.RowHighlight(row)
    row.Invite = button(row, "Invite", 56, 20, function() if row.req then ns.Invite(row.req) end end)
    row.Invite:SetPoint("RIGHT", 0, 0)
    row.Reply = button(row, "Reply", 56, 20, function() if row.req then ns.Reply(row.req) end end)
    row.Reply:SetPoint("RIGHT", row.Invite, "LEFT", -2, 0)
    row.Text = Skin.Text(row, "GameFontHighlightSmall")
    row.Text:SetPoint("LEFT", 4, 0)
    row.Text:SetPoint("RIGHT", row.Reply, "LEFT", -4, 0)
    if row.Text.SetWordWrap then row.Text:SetWordWrap(false) end
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
      if not self.req then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.req.name)
      GameTooltip:AddLine(self.req.msg, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    requestRows[i] = row
    prev = row
  end
  win.NoRequests = Skin.Text(list, "GameFontDisable", "Nobody yet. Requests show up here while you are open for business.")
  win.NoRequests:SetPoint("TOPLEFT", 10, -10)
  win.NoRequests:SetPoint("RIGHT", -10, 0)

  win:SetScript("OnShow", function()
    win.Name:SetText(UnitName("player"))
    win.Ad.Edit:SetText(texts().ad)
    win.Price.Edit:SetText(db.price)
    win.ReplyText.Edit:SetText(texts().reply)
    win.Elsewhere:SetChecked(db.showElsewhere)
    win.Auto:SetChecked(db.autoReply)
    syncCastButtons()
    ns.Refresh()
  end)
  win:SetScript("OnHide", syncCastButtons)
  -- keep ages and the post cooldown ticking
  local tick = 0
  win:SetScript("OnUpdate", function(_, e)
    tick = tick + e
    if tick > 1 then tick = 0; ns.Refresh() end
  end)
end

function ns.Toggle()
  if not win then buildWindow() end
  win:SetShown(not win:IsShown())
end

---------------------------------------------------------------------------
-- Events and /taxi
---------------------------------------------------------------------------
-- The advert and reply are kept per mode, so a mage alt and a warlock main each keep their own.
texts = function()
  local m = ns.Mode()
  db.texts[m] = db.texts[m] or {}
  local t = db.texts[m]
  t.ad = t.ad or C.DEFAULTS[m].ad
  t.reply = t.reply or C.DEFAULTS[m].reply
  return t
end

local CHAT = { "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_GUILD" }

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
for _, e in ipairs({ "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "CHANNEL_UI_UPDATE", "PLAYER_REGEN_ENABLED",
  "SPELLS_CHANGED" }) do
  pcall(f.RegisterEvent, f, e)
end
for _, e in ipairs(CHAT) do f:RegisterEvent(e) end
f:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if ... ~= ADDON then return end
    EvertaxiDB = EvertaxiDB or {}
    db = EvertaxiDB
    db.off = db.off or {}
    db.extra = db.extra or {}
    db.texts = db.texts or {}
    db.chats = db.chats or { ["CHANNEL:Trade"] = true, ["CHANNEL:General"] = true }
    db.price = db.price or "tips welcome"
    db.open = false -- always start closed; opening is a choice each session
    ns.db = db
    return
  end
  if not db then return end
  if event:find("^CHAT_MSG_") then return ns.OnChat(event, ...) end
  if event == "PLAYER_REGEN_ENABLED" then
    if ns.castPending then syncCastButtons() end
  elseif event == "SPELLS_CHANGED" then
    if win and win:IsShown() then syncCastButtons() end
  end
  ns.Refresh()
end)

SLASH_EVERTAXI1, SLASH_EVERTAXI2, SLASH_EVERTAXI3, SLASH_EVERTAXI4 = "/taxi", "/evertaxi", "/summon", "/portal"
SlashCmdList.EVERTAXI = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  local cmd, arg = msg:match("^(%S*)%s*(.*)$")
  if cmd == "" then ns.Toggle()
  elseif cmd == "open" or cmd == "on" then db.open = true; say("open for business."); ns.Refresh()
  elseif cmd == "close" or cmd == "off" then db.open = false; say("closed."); ns.Refresh()
  elseif cmd == "post" then ns.Post()
  elseif cmd == "mode" then
    db.mode = (arg == "summon" or arg == "portal") and arg or nil
    say("mode: " .. ns.Mode() .. (db.mode and "" or " (from your class)") .. ".")
    if win and win:IsShown() then win:Hide(); win:Show() end
  else
    say("/taxi - window  |  /taxi open, /taxi close  |  /taxi post - post the advert  |  /taxi mode summon|portal|class")
  end
end
