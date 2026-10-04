-- Professions window: built from Blizzard's templates via ns.Skin (Evergreen/Modules.lua), so on WoW
-- Forever it wears the bronze frame, red buttons and bottom tabs like the character sheet.
--   Guide     the step list (left, current step marked) and the selected step (right): recipes with
--             spell tooltips, materials with bag/bank counts, alternatives, notes, places to go
--   Trainers  the next training and every tier's trainers for this faction, starting zone trainers
--   Shopping  the guide's shopping lists with ticks saved per character
--   Recipes   recipes to buy (vendors) and the recipe tables (Auction House drops, Annora...)

local ADDON, ns = ...
local P = ns.Professions
if not P then return end
local UI = P.ui
local HEX = P.HEX
local Skin = ns.Skin

local W, H, LIST_W, ROW_H = 820, 540, 300, 18
local TABS = { "Guide", "Trainers", "Shopping", "Recipes" }
local NO_DATA = "No guide data yet.\n\nThe profession guides come from WoW-Professions.com and are not shipped with the addon. " ..
  "Run this once, then /reload:\n\n" .. HEX.white .. "python addon/tools/import_wowprof_professions.py|r"

local function SpellTip(owner, id)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  local ok = GameTooltip.SetSpellByID and pcall(GameTooltip.SetSpellByID, GameTooltip, id)
  if not ok then pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. id) end
  GameTooltip:Show()
end
local function ItemTip(owner, id)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  local ok = GameTooltip.SetItemByID and pcall(GameTooltip.SetItemByID, GameTooltip, id)
  if not ok then pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. id) end
  GameTooltip:Show()
end
local function HideTip() GameTooltip:Hide() end

-- font objects by name ("GameFontNormal"); the object itself where the client has it
local function setFont(fs, name)
  local obj = _G[name]
  pcall(fs.SetFontObject, fs, type(obj) == "table" and obj or name)
end

-- ------------------------------------------------------------------ scrolling content (pooled)
-- A recessed inset with a scroll frame; Text / Line (clickable row with the quest-log highlight) /
-- Check rows stack from the top. Reset() hides everything for the next draw.
local Content = {}
Content.__index = Content

local function NewContent(parent, width)
  local body = Skin.Inset(parent)
  local sf = CreateFrame("ScrollFrame", nil, body, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 6, -6)
  sf:SetPoint("BOTTOMRIGHT", -28, 6)
  local child = CreateFrame("Frame", nil, sf)
  child:SetSize(width, 10)
  sf:SetScrollChild(child)
  return setmetatable({ body = body, scroll = sf, child = child, width = width, y = 4,
    pool = { text = {}, line = {}, check = {} }, used = { text = 0, line = 0, check = 0 } }, Content)
end

function Content:Reset()
  for kind, list in pairs(self.pool) do
    for _, w in ipairs(list) do w:Hide() end
    self.used[kind] = 0
  end
  self.y = 4
end

local function height(fs, min)
  local h = fs.GetStringHeight and fs:GetStringHeight() or 0
  if type(h) ~= "number" or h < (min or 12) then h = min or 12 end
  return h
end

function Content:Text(str, font, indent, gap)
  self.used.text = self.used.text + 1
  local t = self.pool.text[self.used.text]
  if not t then
    t = Skin.Text(self.child, "GameFontHighlightSmall")
    t:SetWordWrap(true)
    self.pool.text[self.used.text] = t
  end
  indent = indent or 0
  setFont(t, font or "GameFontHighlightSmall")
  t:ClearAllPoints()
  t:SetPoint("TOPLEFT", 4 + indent, -self.y)
  t:SetWidth(self.width - 8 - indent)
  t:SetText(str or "")
  t:Show()
  self.y = self.y + height(t) + (gap or 3)
  return t
end

function Content:Heading(str, gap)
  self.y = self.y + (self.y > 4 and 6 or 0)
  return self:Text(str, "GameFontNormal", 0, gap or 4)
end

-- opts: indent, font, onClick, tip = function(owner), arrow (show a "go" marker)
function Content:Line(str, opts)
  opts = opts or {}
  self.used.line = self.used.line + 1
  local r = self.pool.line[self.used.line]
  if not r then
    r = CreateFrame("Button", nil, self.child)
    Skin.RowHighlight(r)
    r.text = Skin.Text(r, "GameFontHighlightSmall")
    r.text:SetWordWrap(true)
    r.go = Skin.Text(r, "GameFontNormalSmall", "RIGHT")
    r.go:SetPoint("TOPRIGHT", -4, -2)
    r:SetScript("OnEnter", function(s) if s.tip then s.tip(s) end end)
    r:SetScript("OnLeave", HideTip)
    r:SetScript("OnClick", function(s) if s.onClick then s.onClick(s) end end)
    self.pool.line[self.used.line] = r
  end
  local indent = opts.indent or 0
  r:ClearAllPoints()
  r:SetPoint("TOPLEFT", indent, -self.y)
  r:SetWidth(self.width - indent)
  setFont(r.text, opts.font or "GameFontHighlightSmall")
  r.text:ClearAllPoints()
  r.text:SetPoint("TOPLEFT", 4, -2)
  r.text:SetWidth(self.width - indent - (opts.arrow and 40 or 8))
  r.text:SetText(str or "")
  r.go:SetText(opts.arrow and (HEX.gold .. "Go|r") or "")
  r.onClick, r.tip, r.label = opts.onClick, opts.tip, str
  r:EnableMouse(opts.onClick ~= nil or opts.tip ~= nil)
  local h = height(r.text) + 4
  r:SetHeight(h)
  r:Show()
  self.y = self.y + h + 1
  return r
end

function Content:Check(str, checked, onClick, tip)
  self.used.check = self.used.check + 1
  local c = self.pool.check[self.used.check]
  if not c then
    local ok, b = pcall(CreateFrame, "CheckButton", nil, self.child, "UICheckButtonTemplate")
    c = ok and b or CreateFrame("CheckButton", nil, self.child)
    c:SetSize(22, 22)
    c.text = Skin.Text(c, "GameFontHighlightSmall")
    c.text:SetPoint("LEFT", c, "RIGHT", 2, 0)
    c.text:SetWordWrap(false)
    c:SetScript("OnClick", function(s) if s.onToggle then s.onToggle(s:GetChecked() and true or false) end end)
    c:SetScript("OnEnter", function(s) if s.tip then s.tip(s) end end)
    c:SetScript("OnLeave", HideTip)
    self.pool.check[self.used.check] = c
  end
  c:ClearAllPoints()
  c:SetPoint("TOPLEFT", 2, -self.y + 2)
  c.text:SetWidth(self.width - 34)
  c.text:SetText(str or "")
  c:SetChecked(checked and true or false)
  c.onToggle, c.tip, c.label = onClick, tip, str
  c:Show()
  self.y = self.y + 22
  return c
end

function Content:Gap(n) self.y = self.y + (n or 6) end

function Content:Finish()
  self.child:SetHeight(math.max(self.y + 6, 10))
  if self.scroll.UpdateScrollChildRect then self.scroll:UpdateScrollChildRect() end
end

-- ------------------------------------------------------------------ shared pieces
local function npcLine(C, slug, indent, prefix)
  local n = P.NPC(slug)
  local label = (prefix or "") .. P.NPCLabel(slug)
  if n and n.m then
    return C:Line(label, { indent = indent, arrow = true, onClick = function() P.WaypointNPC(slug) end,
      tip = function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:AddLine(n.n, 1, 0.82, 0)
        if n.role then GameTooltip:AddLine(n.role, 0.9, 0.9, 0.9) end
        GameTooltip:AddLine(string.format("%s %.1f, %.1f", n.z or P.ZONES[n.m] or "", n.x, n.y), 0.64, 0.62, 0.58)
        GameTooltip:AddLine("Click: waypoint", 0.25, 0.75, 0.25)
        GameTooltip:Show()
      end })
  end
  return C:Line(label .. HEX.muted .. "  (no position)|r", { indent = indent })
end

-- need: what the rest of the step still uses (defaults to the guide's full amount). Shows have/need,
-- and what the shortfall costs to buy when Everbid has a price.
local function matLine(C, m, indent, need)
  need = need or m.c or 0
  local have = P.Have(m)
  local col = have >= need and HEX.green or HEX.red
  local str = string.format("%s%s|r  %s%d / %d|r", HEX.body, m.n, col, have, need)
  local short = need - have
  if short > 0 then
    local price, src = P.UnitPrice(m.i)
    if price then
      str = str .. string.format("  %sbuy %d: %s%s|r", HEX.muted, short, P.Money(price * short),
        src == "vendor" and " (vendor)" or "")
    elseif P.HasPrices() then
      str = str .. string.format("  %sbuy %d: no price yet|r", HEX.muted, short)
    end
  end
  return C:Line(str, { indent = indent, tip = m.i and function(s)
    ItemTip(s, m.i)
    local price, src = P.UnitPrice(m.i)
    if price then
      GameTooltip:AddLine(string.format("%s each (%s, Everbid)", P.Money(price), src), 0.64, 0.62, 0.58)
      GameTooltip:Show()
    end
  end or nil })
end

local function costLine(C, list, indent, label)
  if not P.HasPrices() then return end
  local total, unpriced = P.BuyCost(list)
  local str
  if total == 0 and unpriced == 0 then
    str = HEX.green .. "You have everything for this.|r"
  else
    str = HEX.gold .. (label or "Cost to finish") .. ":|r " .. HEX.white .. P.Money(total) .. "|r"
    if unpriced > 0 then str = str .. HEX.muted .. "  (+" .. unpriced .. " without a price, scan the AH)|r" end
  end
  C:Line(str, { indent = indent })
end

-- e/skill given: scale to the crafts still left in that step at that skill
local function craftLines(C, c, indent, muted, e, skill)
  local left = e and P.CraftsLeft(e, c, skill)
  local count = c.c and (c.c .. "x ") or ""
  local of = ""
  if left and c.c and left < c.c then count = left .. "x "; of = HEX.muted .. "  (" .. left .. " left of " .. c.c .. ")|r" end
  local name = (muted and HEX.body or HEX.white) .. count .. c.name .. "|r" .. of
  C:Line(name, { indent = indent, font = "GameFontHighlight", tip = c.spell and function(s) SpellTip(s, c.spell) end or nil })
  local cost = {}
  for _, m in ipairs(c.mats or {}) do
    local need = e and P.MatNeed(m, c, left) or nil
    matLine(C, m, (indent or 0) + 14, need)
    cost[#cost + 1] = { mat = m, need = need or m.c or 0 }
  end
  if not muted and #cost > 0 then costLine(C, cost, (indent or 0) + 14) end
  if c.matNote then C:Text(HEX.muted .. c.matNote .. "|r", nil, (indent or 0) + 14) end
  if c.src and c.src ~= "" then
    local shown = 0
    for _, s in ipairs(c.npcs or {}) do
      if P.ForMe(P.NPC(s)) then
        if shown == 0 then C:Text(HEX.muted .. "Recipe from:|r", nil, (indent or 0) + 14) end
        npcLine(C, s, (indent or 0) + 20); shown = shown + 1
      end
    end
    if shown == 0 then C:Text(HEX.muted .. "Recipe: " .. c.src .. "|r", nil, (indent or 0) + 14) end
  end
end

local function placeLines(C, slugs, seen, title)
  local any = false
  for _, s in ipairs(slugs or {}) do
    if not seen[s] and P.ForMe(P.NPC(s)) then
      if not any and title then C:Heading(title) end
      any = true
      seen[s] = true
      npcLine(C, s, 6)
    end
  end
end

local function vendorLines(C, vendors, seen)
  local me = P.Faction()
  for _, v in ipairs(vendors or {}) do
    if not v.fac or not me or v.fac == me then
      C:Heading(v.title or "Vendors")
      for _, r in ipairs(v.rows or {}) do
        local first = r.npcs and r.npcs[1]
        local n = first and P.NPC(first)
        local str = HEX.gold .. (r.zone or "") .. ":|r " .. HEX.body .. (r.text or "") .. "|r"
        for _, s in ipairs(r.npcs or {}) do seen[s] = true end
        if n and n.m then
          C:Line(str, { indent = 6, arrow = true, onClick = function() P.WaypointNPC(first) end })
        else
          C:Line(str, { indent = 6 })
        end
      end
    end
  end
end

-- ------------------------------------------------------------------ the step list
local function entryRange(e)
  if e.from and e.to then return e.from .. "-" .. e.to end
  return nil
end

local function stepLabel(e)
  local c = e.crafts and e.crafts[1]
  if c then
    local s = (c.c and (c.c .. "x ") or "") .. c.name
    if #e.crafts > 1 then s = s .. HEX.muted .. (e.pick == "all" and " + " or " or ") .. (#e.crafts - 1) .. " more|r" end
    return s
  end
  local t = (e.text and e.text[1]) or (e.note and e.note[1]) or ""
  if #t > 46 then t = t:sub(1, 44) .. "..." end
  return t
end

-- list rows: every visible entry except the untitled text blocks (shown with the entry before them)
function UI.ListEntries(g)
  local out = {}
  for i, e in ipairs(g and g.entries or {}) do
    if P.Visible(g, e) and not (e.k == "h" and (e.lvl or 2) >= 5) then out[#out + 1] = i end
  end
  return out
end

function UI.RefreshList()
  local g = P.current
  if not UI.rows then return end
  local list = g and UI.ListEntries(g) or {}
  UI.listed = list
  local off = math.max(0, math.min(UI.listOffset or 0, #list - UI.ROWS))
  UI.listOffset = off
  for i, r in ipairs(UI.rows) do
    local idx = list[i + off]
    local e = idx and g.entries[idx]
    r.index = idx
    r.sel:Hide()
    if not e then
      r:Hide()
    else
      r:Show()
      local range = entryRange(e)
      local skill = P.Skill(e.skill or g.skill)
      local done = skill and e.to and skill >= e.to
      local mark = idx == UI.currentIndex and (HEX.green .. "> |r") or ""
      if e.k == "h" then
        local font = (e.lvl or 2) <= 2 and "GameFontNormal" or "GameFontNormalSmall"
        setFont(r.text, font)
        r.text:SetText(mark .. ((e.lvl or 2) <= 2 and "" or "  ") .. (e.title ~= "" and e.title or "Notes"))
        r.range:SetText((e.lvl or 2) <= 2 and "" or (range and (HEX.muted .. range .. "|r") or ""))
      elseif e.k == "v" then
        setFont(r.text, "GameFontHighlightSmall")
        local cur = e.labels[P.Variant(g, e.g)] or "?"
        r.text:SetText("  " .. HEX.violet .. "Route: " .. cur .. "|r")
        r.range:SetText(HEX.muted .. "switch|r")
      else
        setFont(r.text, "GameFontHighlightSmall")
        r.text:SetText(mark .. "  " .. (done and HEX.muted or HEX.white) .. stepLabel(e) .. "|r")
        r.range:SetText((done and HEX.muted or HEX.gold) .. (range or "") .. "|r")
      end
      if idx == UI.selected then r.sel:Show() end
    end
  end
end

-- ------------------------------------------------------------------ the selected entry
local function followingBlocks(g, i)
  local out = {}
  local j = i + 1
  while g.entries[j] do
    local e = g.entries[j]
    if not (e.k == "h" and (e.lvl or 2) >= 5) then break end
    if P.Visible(g, e) then out[#out + 1] = e end
    j = j + 1
  end
  return out
end

local function headerBody(C, g, e, seen)
  for _, line in ipairs(e.text or {}) do C:Text(HEX.body .. line .. "|r", nil, 0, 4) end
  for _, w in ipairs(e.way or {}) do
    C:Line(HEX.white .. (w.title ~= "" and w.title or "Waypoint") .. "|r" .. HEX.muted ..
      string.format("  %s %.1f, %.1f|r", P.ZONES[w.m] or "", w.x, w.y),
      { indent = 6, arrow = true, onClick = function() P.Waypoint(w.m, w.x, w.y, w.title) end })
  end
  vendorLines(C, e.vendors, seen)
end

function UI.RefreshDetail()
  local C = UI.detail
  if not C then return end
  C:Reset()
  local g = P.current
  if not P.Data() or not g then
    C:Text(NO_DATA, "GameFontHighlight")
    C:Finish()
    return
  end
  local i = UI.selected
  local e = i and g.entries[i]
  if not e then
    C:Text(HEX.muted .. "Pick a step on the left.|r")
    C:Finish()
    return
  end
  local seen = {}
  local range = entryRange(e)
  if e.k == "v" then
    C:Heading("Choose a route")
    C:Text(HEX.body .. "The guide has more than one way through this part. Pick the one that fits (prices, what you have):|r")
    for vi, label in ipairs(e.labels) do
      local on = P.Variant(g, e.g) == vi
      C:Line((on and (HEX.green .. "> ") or "  ") .. label .. "|r", { indent = 6, font = "GameFontHighlight", onClick = function()
        P.SetVariant(g, e.g, vi); UI.Refresh()
      end })
    end
  elseif e.k == "h" then
    C:Text(e.title ~= "" and e.title or "Notes", "GameFontNormalLarge", 0, 2)
    if range then C:Text(HEX.muted .. (e.skill or g.skill) .. " " .. range .. "|r", nil, 0, 6) end
    for _, t in ipairs(g.tiers or {}) do
      if (e.lvl or 2) == 2 and t.title == e.title then
        if t.train then C:Text(HEX.gold .. t.train .. "|r", nil, 0, 4) end
        local list = P.TrainersFor(t)
        if #list > 0 then C:Heading("Trainers") end
        for _, x in ipairs(list) do seen[x.npc] = true; npcLine(C, x.npc, 6, x.city and (HEX.muted .. x.city .. ":|r ") or nil) end
      end
    end
    headerBody(C, g, e, seen)
    placeLines(C, e.npcs, seen, "Places")
  else
    local status = ""
    local skill = P.Skill(e.skill or g.skill)
    if i == UI.currentIndex then status = HEX.green .. "  (you are here)|r"
    elseif skill and e.to and skill >= e.to then status = HEX.muted .. "  (done)|r" end
    C:Text((e.skill or g.skill) .. " " .. (range or "") .. status, "GameFontNormalLarge", 0, 6)
    if e.lead and e.lead ~= "" then C:Text(HEX.body .. e.lead .. "|r", nil, 0, 4) end
    if e.crafts and #e.crafts > 1 then
      C:Text(HEX.gold .. (e.pick == "all" and "Make all of these, in this order:" or "Make one of these:") .. "|r", nil, 0, 3)
    end
    for _, c in ipairs(e.crafts or {}) do craftLines(C, c, 0, nil, e, skill) end
    for _, line in ipairs(e.text or {}) do C:Text(HEX.body .. line .. "|r", nil, 0, 4) end
    if e.crafts and #e.crafts > 1 and e.pick == "all" then
      C:Heading("All materials")
      local cost = {}
      for _, m in ipairs(P.StepMats(e, skill)) do
        matLine(C, m, 6, m.need)
        cost[#cost + 1] = { mat = m, need = m.need }
      end
      costLine(C, cost, 6, "Cost to finish the step")
    end
    if e.alts and #e.alts > 0 then
      C:Heading("Alternatives")
      for _, c in ipairs(e.alts) do craftLines(C, c, 6, true) end
    end
    if e.recipes and #e.recipes > 0 then
      C:Heading("Recipes")
      for _, r in ipairs(e.recipes) do
        C:Line(HEX.white .. r.n .. "|r", { indent = 6, tip = r.i and function(s) ItemTip(s, r.i) end or nil })
        for _, s in ipairs(r.npcs or {}) do
          if P.ForMe(P.NPC(s)) then seen[s] = true; npcLine(C, s, 18) end
        end
      end
    end
    if e.note and #e.note > 0 then
      C:Heading("Notes")
      for _, line in ipairs(e.note) do C:Text(HEX.body .. line .. "|r", nil, 0, 4) end
    end
    vendorLines(C, e.vendors, seen)
    placeLines(C, e.npcs, seen, "Places")
  end
  for _, b in ipairs(followingBlocks(g, i)) do
    C:Gap(4)
    headerBody(C, g, b, seen)
    placeLines(C, b.npcs, seen, nil)
  end
  C:Finish()
end

-- ------------------------------------------------------------------ the other tabs
local function trainersPage(C, g)
  local rank, max = P.Skill(g.skill)
  C:Text(g.skill .. ": " .. (rank and (HEX.white .. rank .. (max and (" / " .. max) or "") .. "|r") or (HEX.muted .. "not learned|r")),
    "GameFontNormalLarge", 0, 6)
  local nextTier = P.NextTier(g)
  if nextTier then
    C:Heading("Next: " .. nextTier.title)
    if nextTier.train then C:Text(HEX.gold .. nextTier.train .. "|r", nil, 0, 4) end
    for _, x in ipairs(P.TrainersFor(nextTier)) do npcLine(C, x.npc, 6, x.city and (HEX.muted .. x.city .. ":|r ") or nil) end
  end
  for _, t in ipairs(g.tiers or {}) do
    if t ~= nextTier then
      C:Heading(t.title)
      if t.train then C:Text(HEX.muted .. t.train .. "|r", nil, 0, 4) end
      local list = P.TrainersFor(t)
      if #list == 0 then C:Text(HEX.muted .. "See the guide text for where to learn it.|r", nil, 6) end
      for _, x in ipairs(list) do npcLine(C, x.npc, 6, x.city and (HEX.muted .. x.city .. ":|r ") or nil) end
    end
  end
  local caps = P.TrainersFor({ trainers = g.trainers })
  if #(g.tiers or {}) == 0 and #caps > 0 then
    C:Heading("Capital city trainers")
    for _, x in ipairs(caps) do npcLine(C, x.npc, 6, x.city and (HEX.muted .. x.city .. ":|r ") or nil) end
  end
  if g.startZones and #g.startZones > 0 then
    C:Heading("Starting zones")
    local race = P.plain(UnitRace and select(1, UnitRace("player")))
    for _, z in ipairs(g.startZones) do
      local mine = type(race) == "string" and z.races:find(race, 1, true)
      local first
      for _, s in ipairs(z.npcs or {}) do local n = P.NPC(s); if n and n.m and P.ForMe(n) then first = s; break end end
      local str = (mine and HEX.green or HEX.gold) .. z.races .. "|r " .. HEX.muted .. "(" .. z.zone .. ")|r  " .. HEX.body .. z.text .. "|r"
      if first then C:Line(str, { indent = 6, arrow = true, onClick = function() P.WaypointNPC(first) end })
      else C:Line(str, { indent = 6 }) end
    end
  end
  for _, line in ipairs(g.intro or {}) do C:Text(HEX.muted .. line .. "|r", nil, 0, 3) end
end

local function shoppingPage(C, g)
  if not g.shopping or #g.shopping == 0 then
    C:Text(HEX.muted .. "This guide has no shopping list; the Guide tab lists the materials of every step.|r")
    return
  end
  for _, line in ipairs(g.shopIntro or {}) do C:Text(HEX.muted .. line .. "|r", nil, 0, 3) end
  C:Line(HEX.gold .. "Untick all|r", { onClick = function()
    for li, l in ipairs(g.shopping) do for ri in ipairs(l.rows) do P.SetShopChecked(g, li, ri, false) end end
    UI.Refresh()
  end })
  for li, l in ipairs(g.shopping) do
    C:Heading(l.title)
    for _, n in ipairs(l.note or {}) do C:Text(HEX.muted .. n .. "|r", nil, 0, 3) end
    for ri, row in ipairs(l.rows) do
      local parts = {}
      local done = P.ShopChecked(g, li, ri)
      for _, m in ipairs(row.mats) do
        local have = P.Have(m)
        parts[#parts + 1] = string.format("%s%dx %s|r %s(%d)|r", done and HEX.muted or HEX.white, m.c, m.n,
          have >= m.c and HEX.green or HEX.muted, have)
      end
      local first = row.mats[1]
      C:Check(table.concat(parts, " + "), done, function(on) P.SetShopChecked(g, li, ri, on); UI.Refresh() end,
        first and first.i and function(s) ItemTip(s, first.i) end or nil)
      if row.alt and #row.alt > 0 then
        local alt = {}
        for _, m in ipairs(row.alt) do alt[#alt + 1] = m.c .. "x " .. m.n end
        C:Text(HEX.muted .. "or: " .. table.concat(alt, " + ") .. "|r", nil, 30, 3)
      end
    end
  end
end

local function recipesPage(C, g)
  local any, seenItem = false, {}
  for _, e in ipairs(g.entries or {}) do
    if e.recipes and P.Visible(g, e) then
      for _, r in ipairs(e.recipes) do
        if not seenItem[r.i or r.n] then
          seenItem[r.i or r.n] = true
          if not any then C:Heading("Recipes to buy"); any = true end
          C:Line(HEX.white .. r.n .. "|r" .. HEX.muted .. "  (" .. entryRange(e) .. ")|r",
            { indent = 0, tip = r.i and function(s) ItemTip(s, r.i) end or nil })
          for _, s in ipairs(r.npcs or {}) do if P.ForMe(P.NPC(s)) then npcLine(C, s, 14) end end
        end
      end
    end
  end
  for _, t in ipairs(g.recipeTables or {}) do
    any = true
    C:Heading(t.title)
    for _, r in ipairs(t.rows or {}) do
      local nums = {}
      if r.learn then nums[#nums + 1] = "learn " .. r.learn end
      if r.yellow then nums[#nums + 1] = "yellow " .. r.yellow end
      if r.grey then nums[#nums + 1] = "grey " .. r.grey end
      if r.cost then nums[#nums + 1] = "cost " .. r.cost end
      C:Line(HEX.white .. r.name .. "|r  " .. HEX.muted .. table.concat(nums, ", ") .. "|r" ..
        (r.mats and ("\n" .. HEX.body .. r.mats .. "|r") or ""),
        { tip = r.spell and function(s) SpellTip(s, r.spell) end or nil })
    end
  end
  if not any then C:Text(HEX.muted .. "This guide names no recipes to buy.|r") end
end

-- ------------------------------------------------------------------ window
local function ShowTab(name)
  UI.tab = name
  if P.db then P.db.tab = name end
  local guide = name == "Guide"
  UI.list:SetShown(guide)
  UI.detail.body:SetShown(guide)
  UI.page.body:SetShown(not guide)
  UI.Refresh()
end

function UI.Build()
  if UI.frame then return UI.frame end
  local f = Skin.Window("EvergreenProfessionsFrame", W, H, "Professions", "Interface\\Icons\\Trade_BlackSmithing",
    function(s) local p, _, rp, x, y = s:GetPoint(1); if P.db then P.db.pos = { p, rp, x, y } end end)
  if P.db and P.db.pos then f:ClearAllPoints(); f:SetPoint(P.db.pos[1], UIParent, P.db.pos[2], P.db.pos[3], P.db.pos[4]) end
  f:Hide()
  UI.frame = f
  local top = f.contentTop or -26

  -- profession picker: a button that opens a list of every guide, learned ones first
  local pick = Skin.Button(f, "Profession", 170, 22)
  pick:SetPoint("TOPLEFT", (f.portraitW or 8) + 6, top - 6)
  pick:SetScript("OnClick", function() UI.ToggleMenu() end)
  UI.pick = pick
  UI.skillText = Skin.Text(f, "GameFontHighlight")
  UI.skillText:SetPoint("LEFT", pick, "RIGHT", 10, 0)
  UI.source = Skin.Text(f, "GameFontDisableSmall", "RIGHT")
  UI.source:SetPoint("TOPRIGHT", -14, top - 10)
  UI.source:SetText(HEX.muted .. "Guides: WoW-Professions.com|r")

  local menu = Skin.Inset(f)
  menu:SetFrameStrata("DIALOG")
  menu:SetPoint("TOPLEFT", pick, "BOTTOMLEFT", 0, -2)
  menu:SetSize(230, 12 * ROW_H + 10)
  menu:Hide()
  menu.rows = {}
  for i = 1, 12 do
    local r = CreateFrame("Button", nil, menu)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 4, -5 - (i - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", -4, -5 - (i - 1) * ROW_H)
    Skin.RowHighlight(r)
    r.text = Skin.Text(r, "GameFontHighlightSmall")
    r.text:SetPoint("LEFT", 6, 0)
    r.rank = Skin.Text(r, "GameFontHighlightSmall", "RIGHT")
    r.rank:SetPoint("RIGHT", -6, 0)
    r:SetScript("OnClick", function(s) menu:Hide(); if s.key then P.Select(s.key); UI.SelectCurrent() end end)
    menu.rows[i] = r
  end
  UI.menu = menu

  -- step list (left) and the selected step (right)
  local list = Skin.Inset(f)
  list:SetPoint("TOPLEFT", 10, top - 36)
  list:SetPoint("BOTTOMLEFT", 10, 10)
  list:SetWidth(LIST_W)
  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function(_, d) UI.listOffset = math.max(0, (UI.listOffset or 0) - d * 3); UI.RefreshList() end)
  UI.list = list
  UI.rows = {}
  UI.ROWS = math.floor((H + top - 36 - 10 - 8) / ROW_H)
  for i = 1, UI.ROWS do
    local r = CreateFrame("Button", nil, list)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 4, -4 - (i - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", -4, -4 - (i - 1) * ROW_H)
    r.sel = r:CreateTexture(nil, "BACKGROUND")
    r.sel:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    r.sel:SetBlendMode("ADD"); r.sel:SetAllPoints(); r.sel:SetVertexColor(1, 0.82, 0, 0.55); r.sel:Hide()
    Skin.RowHighlight(r)
    r.text = Skin.Text(r, "GameFontHighlightSmall")
    r.text:SetPoint("LEFT", 4, 0); r.text:SetPoint("RIGHT", -54, 0); r.text:SetWordWrap(false)
    r.range = Skin.Text(r, "GameFontHighlightSmall", "RIGHT")
    r.range:SetPoint("RIGHT", -4, 0)
    r:SetScript("OnClick", function(s) if s.index then UI.Click(s.index) end end)
    r:SetScript("OnEnter", function(s)
      local g = P.current
      local e = g and s.index and g.entries[s.index]
      local c = e and e.k == "s" and e.crafts and e.crafts[1]
      if c and c.spell then SpellTip(s, c.spell) end
    end)
    r:SetScript("OnLeave", HideTip)
    UI.rows[i] = r
  end

  local right = CreateFrame("Frame", nil, f)
  right:SetPoint("TOPLEFT", list, "TOPRIGHT", 8, 0)
  right:SetPoint("BOTTOMRIGHT", -10, 10)
  UI.detail = NewContent(right, W - LIST_W - 70)
  UI.detail.body:SetAllPoints(right)

  -- the other tabs share one full-width page
  local pageHolder = CreateFrame("Frame", nil, f)
  pageHolder:SetPoint("TOPLEFT", 10, top - 36)
  pageHolder:SetPoint("BOTTOMRIGHT", -10, 10)
  UI.page = NewContent(pageHolder, W - 60)
  UI.page.body:SetAllPoints(pageHolder)

  Skin.Tabs(f, TABS, function(i) ShowTab(TABS[i]) end)

  f:SetScript("OnShow", function() P.ScanSkills(); UI.Refresh() end)
  f:SetScript("OnHide", function() menu:Hide() end)
  local tab = (P.db and P.db.tab) or "Guide"
  local ti = 1
  for i, n in ipairs(TABS) do if n == tab then ti = i end end
  Skin.SelectTab(f, ti)
  UI.tab = TABS[ti]
  list:SetShown(UI.tab == "Guide"); UI.detail.body:SetShown(UI.tab == "Guide"); UI.page.body:SetShown(UI.tab ~= "Guide")
  return f
end

function UI.ToggleMenu()
  local menu = UI.menu
  if menu:IsShown() then menu:Hide(); return end
  local order, seen = {}, {}
  for _, g in ipairs(P.Learned()) do order[#order + 1] = g; seen[g] = true end
  for _, g in ipairs(P.Guides()) do if not seen[g] then order[#order + 1] = g end end
  for i, r in ipairs(menu.rows) do
    local g = order[i]
    r.key = g and g.key
    if g then
      local rank, max = P.Skill(g.skill)
      r.text:SetText((g == P.current and HEX.gold or HEX.white) .. g.name .. "|r")
      r.rank:SetText(rank and (HEX.green .. rank .. (max and ("/" .. max) or "") .. "|r") or (HEX.muted .. "not learned|r"))
      r:Show()
    else
      r:Hide()
    end
  end
  menu:SetHeight(math.max(1, #order) * ROW_H + 10)
  menu:Show()
end

-- select the current step and scroll the list to it
function UI.SelectCurrent()
  local g = P.current
  if not g then return end
  UI.currentIndex = P.CurrentIndex(g)
  UI.selected = UI.currentIndex or (UI.ListEntries(g)[1])
  local list = UI.ListEntries(g)
  for pos, idx in ipairs(list) do
    if idx == UI.selected then UI.listOffset = math.max(0, pos - 4) end
  end
  UI.Refresh()
end

function UI.Click(index)
  local g = P.current
  local e = g and g.entries[index]
  if not e then return end
  if e.k == "v" and UI.selected == index then
    -- a second click on a route row switches to the next route
    P.SetVariant(g, e.g, (P.Variant(g, e.g) % #e.labels) + 1)
  end
  UI.selected = index
  UI.Refresh()
end

function UI.Refresh()
  if not UI.frame then return end
  local g = P.current
  if not g and P.Data() then g = P.DefaultGuide(); P.current = g end
  if g then
    UI.currentIndex = P.CurrentIndex(g)
    UI.pick:SetLabel(g.name .. "  v")
    local rank, max = P.Skill(g.skill)
    local s = rank and (HEX.white .. g.skill .. " " .. rank .. (max and (" / " .. max) or "") .. "|r") or (HEX.muted .. g.skill .. ": not learned|r")
    if g.key == "fishing-and-cooking" then
      local cr = P.Skill("Cooking")
      s = s .. HEX.muted .. "   Cooking " .. (cr or "-") .. "|r"
    end
    UI.skillText:SetText(s)
    if UI.selected and not g.entries[UI.selected] then UI.selected = nil end
    if not UI.selected then UI.selected = UI.currentIndex or UI.ListEntries(g)[1] end
  else
    UI.pick:SetLabel("Professions")
    UI.skillText:SetText(HEX.muted .. "no guide data|r")
  end
  if UI.tab == "Guide" then
    UI.RefreshList()
    UI.RefreshDetail()
  else
    local C = UI.page
    C:Reset()
    if not g then C:Text(NO_DATA, "GameFontHighlight")
    elseif UI.tab == "Trainers" then trainersPage(C, g)
    elseif UI.tab == "Shopping" then shoppingPage(C, g)
    else recipesPage(C, g) end
    C:Finish()
  end
end

function UI.Open(key)
  UI.Build()
  if key then P.Select(key) end
  UI.frame:Show()
  UI.SelectCurrent()
end

function UI.Toggle()
  UI.Build()
  if UI.frame:IsShown() then UI.frame:Hide(); return end
  if not P.current then P.current = P.DefaultGuide() end
  UI.frame:Show()
  UI.SelectCurrent()
end
