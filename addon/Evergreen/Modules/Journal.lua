-- Journal module: an in-game dungeon journal for WoW Forever / Classic Era.
--
-- Every dungeon and raid with its bosses and their loot (real item tooltips; shift-click links,
-- ctrl-click tries it on), and every quest that belongs to it: who gives it and where, level,
-- the chain before it, rewards, and whether this character has done it. "Go" buttons point the
-- Evergreen arrow (or TomTom / the game's own waypoint) at a quest giver or a dungeon entrance.
-- The world map shows dungeon quest givers and dungeon entrances for the zone you are looking at.
--
-- Data: Modules/Journal_Data.lua (generated from AtlasLootClassic + Questie, see tools/build_journal.lua).
-- /ej opens it; /ej <name> jumps to a dungeon; /ej pins toggles the world map markers.

local ADDON, ns = ...

local HEX = { ink = "|cffe8e4d8", muted = "|cffa39e93", green = "|cff40c040", gold = "|cffffd100", red = "|cffff4040", white = "|cffffffff", violet = "|cffb48cff" }
local C = {
  bg = { 0.07, 0.08, 0.075, 0.96 }, panel = { 0.10, 0.12, 0.11, 1 }, line = { 0.20, 0.22, 0.20, 1 },
  sel = { 0.50, 0.83, 0.37, 0.18 }, hover = { 1, 1, 1, 0.06 },
}
local FONT_DISPLAY, FONT_BODY = "Fonts\\FRIZQT__.TTF", "Fonts\\FRIZQT__.TTF"
local W, H, LIST_W = 840, 560, 240

-- Forever-only dungeon quests that the Classic sources do not know (Wowhead Forever database).
local FOREVER_EXTRA = {
  { dungeons = { "The Deadmines", "Shadowfang Keep", "Blackfathom Deeps" },
    q = { id = 95036, name = "A Moon-Kissed Blade", lvl = 25, req = 20, fac = "H", cls = 2, forever = true,
          g = { 1421, 43.2, 40.8, "Lumina Windsinger" }, r = { 1421, 43.4, 41.0, "Trevan Rol" },
          txt = "Forsaken Paladin: Whitestone Oak Lumber (Goblin Woodcarvers, Deadmines), Enchanted Silver Ingot (beside Arugal, Shadowfang Keep), Purified Kor Gem (Seeking the Kor Gem, Blackfathom Deeps)." } },
  { dungeons = { "Blackfathom Deeps" },
    q = { id = 95042, name = "Seeking the Kor Gem", lvl = 25, req = 20, cls = 2, forever = true,
          g = { 1440, 11.8, 34.4, "Ulric Frostveil" }, r = { 1440, 11.8, 34.4, "Ulric Frostveil" },
          txt = "Paladin (Forever version): a Corrupted Kor Gem from the Blackfathom Tide Priestesses and Oracles outside the instance." } },
}

local ZONE_NAMES = {
  [1411]="Durotar", [1412]="Mulgore", [1413]="The Barrens", [1416]="Alterac Mountains", [1417]="Arathi Highlands",
  [1418]="Badlands", [1419]="Blasted Lands", [1420]="Tirisfal Glades", [1421]="Silverpine Forest", [1422]="Western Plaguelands",
  [1423]="Eastern Plaguelands", [1424]="Hillsbrad Foothills", [1425]="The Hinterlands", [1426]="Dun Morogh", [1427]="Searing Gorge",
  [1428]="Burning Steppes", [1429]="Elwynn Forest", [1430]="Deadwind Pass", [1431]="Duskwood", [1432]="Loch Modan",
  [1433]="Redridge Mountains", [1434]="Stranglethorn Vale", [1435]="Swamp of Sorrows", [1436]="Westfall", [1437]="Wetlands",
  [1438]="Teldrassil", [1439]="Darkshore", [1440]="Ashenvale", [1441]="Thousand Needles", [1442]="Stonetalon Mountains",
  [1443]="Desolace", [1444]="Feralas", [1445]="Dustwallow Marsh", [1446]="Tanaris", [1447]="Azshara", [1448]="Felwood",
  [1449]="Un'Goro Crater", [1450]="Moonglade", [1451]="Silithus", [1452]="Winterspring", [1453]="Stormwind City",
  [1454]="Orgrimmar", [1455]="Ironforge", [1456]="Thunder Bluff", [1457]="Darnassus", [1458]="Undercity",
  [1459]="Alterac Valley", [1460]="Warsong Gulch",
}
local CLASS_BIT = { WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16, SHAMAN = 64, MAGE = 128, WARLOCK = 256, DRUID = 1024 }
local QUALITY_HEX = { [0] = "ff9d9d9d", "ffffffff", "ff1eff00", "ff0070dd", "ffa335ee", "ffff8000", "ffe6cc80" }

local DB
local J = {}          -- widgets and state
ns.Journal = J

-- ------------------------------------------------------------------ helpers
local function say(msg) print("|cff7fd35eEvergreen Journal:|r " .. msg) end

local function Text(parent, size, font, justify)
  local t = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  t:SetFont(font or FONT_BODY, size or 12, "")
  t:SetShadowOffset(1, -1); t:SetShadowColor(0, 0, 0, 1)
  t:SetJustifyH(justify or "LEFT")
  t:SetTextColor(0.91, 0.89, 0.85)
  return t
end

local function ItemInfo(id)
  local name, link, quality, _, _, _, _, _, equipLoc, icon
  local getter = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if getter then name, link, quality, _, _, _, _, _, equipLoc, icon = getter(id) end
  if not icon then
    local gi = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    if gi then icon = gi(id) end
  end
  if not name and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
  return name, link, quality, icon or "Interface\\Icons\\INV_Misc_QuestionMark", equipLoc
end

local function PlayerClassBit()
  local _, cls = UnitClass("player")
  return CLASS_BIT[cls or ""] or 0
end
local function PlayerFaction()
  local f = UnitFactionGroup("player")
  return f == "Alliance" and "A" or f == "Horde" and "H" or nil
end

local function QuestDone(id)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    local ok, r = pcall(C_QuestLog.IsQuestFlaggedCompleted, id)
    if ok then return r end
  end
  return false
end

local logIDs = {}
local function ScanLog()
  wipe(logIDs)
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    for i = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
      local info = C_QuestLog.GetInfo(i)
      if info and info.questID and not info.isHeader then logIDs[info.questID] = true end
    end
  end
  if next(logIDs) == nil and GetNumQuestLogEntries and GetQuestLogTitle then
    for i = 1, GetNumQuestLogEntries() do
      local _, _, _, isHeader, _, _, _, id = GetQuestLogTitle(i)
      if id and not isHeader then logIDs[id] = true end
    end
  end
end

-- quests this character could take: faction and class fit
local function QuestFits(q)
  local fac = PlayerFaction()
  if q.fac and fac and q.fac ~= fac then return false end
  if q.cls and bit and bit.band then
    if bit.band(q.cls, PlayerClassBit()) == 0 then return false end
  end
  return true
end

local function LevelColor(minL, maxL)
  local lvl = UnitLevel("player") or 1
  if not minL then return HEX.muted end
  if lvl < minL - 2 then return HEX.red end
  if lvl < minL then return HEX.gold end
  if maxL and lvl > maxL then return HEX.muted end
  return HEX.green
end

local function Waypoint(map, x, y, title)
  if not map or map == 0 or not x or (x == 0 and y == 0) then say("no map position for " .. (title or "that") .. "."); return end
  if ns.SetExternalTarget and ns.ModuleEnabled and ns.ModuleEnabled("guide") and EvergreenCharDB then
    ns.SetExternalTarget(map, x, y, title)
  else
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint then
      pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x / 100, y / 100))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
      end)
    end
    if TomTom and TomTom.AddWaypoint then pcall(TomTom.AddWaypoint, TomTom, map, x / 100, y / 100, { title = title }) end
  end
  say("waypoint: " .. HEX.ink .. (title or "") .. "|r, " .. (ZONE_NAMES[map] or ("map " .. map)) .. string.format(" %.1f, %.1f", x, y))
end

-- ------------------------------------------------------------------ data prep
local instances = {}
local function Prepare()
  instances = ns.JournalData or {}
  local byName = {}
  for _, d in ipairs(instances) do byName[d.name] = d end
  for _, e in ipairs(FOREVER_EXTRA) do
    for _, n in ipairs(e.dungeons) do
      local d = byName[n]
      if d then
        d.quests = d.quests and { unpack(d.quests) } or {}
        table.insert(d.quests, e.q)
      end
    end
  end
  -- quest name lookup for prerequisite chains
  J.questName = {}
  for _, d in ipairs(instances) do for _, q in ipairs(d.quests or {}) do J.questName[q.id] = q.name end end
end

-- ------------------------------------------------------------------ window
-- Built from Blizzard's templates via ns.Skin (see Modules.lua): on WoW Forever it wears the same
-- metal frame, portrait, red buttons and bottom tabs as the character sheet and quest log.
local function MakeButton(parent, text, w)
  local b = ns.Skin.Button(parent, text, w or 80, 22)
  return b
end

local TABS = { "Loot", "Quests" }

local function Build()
  local f = ns.Skin.Window("EvergreenJournalFrame", W, H, "Dungeon Journal", "Interface\\Icons\\INV_Misc_Book_09",
    function(s) local p, _, rp, x, y = s:GetPoint(1); DB.pos = { p, rp, x, y } end)
  if DB.pos then f:ClearAllPoints(); f:SetPoint(DB.pos[1], UIParent, DB.pos[2], DB.pos[3], DB.pos[4]) end
  f:Hide()
  J.frame = f
  local top = f.contentTop

  -- search, top left beside the portrait
  local search = ns.Skin.Search(f, LIST_W - f.portraitW + 4, "Search dungeon, boss or item")
  search:SetPoint("TOPLEFT", f.portraitW + 6, top - 8)
  search:HookScript("OnTextChanged", function(s) J.filter = (s:GetText() or ""):lower(); J.RefreshList() end)
  search:HookScript("OnEscapePressed", function(s) s:ClearFocus() end)
  J.search = search

  -- instance list in an inset (fixed rows, mouse wheel scrolls)
  local list = ns.Skin.Inset(f)
  list:SetPoint("TOPLEFT", 10, top - 36)
  list:SetPoint("BOTTOMLEFT", 10, 10)
  list:SetWidth(LIST_W)
  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function(_, d) J.listOffset = math.max(0, (J.listOffset or 0) - d * 3); J.RefreshList() end)
  J.list = list
  J.rows = {}
  local ROW_H = 20
  J.ROWS = math.floor((H + top - 36 - 10 - 8) / ROW_H)
  for i = 1, J.ROWS do
    local r = CreateFrame("Button", nil, list)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 4, -4 - (i - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", -4, -4 - (i - 1) * ROW_H)
    r.sel = r:CreateTexture(nil, "BACKGROUND")
    r.sel:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    r.sel:SetBlendMode("ADD"); r.sel:SetAllPoints(); r.sel:SetVertexColor(1, 0.82, 0, 0.55); r.sel:Hide()
    ns.Skin.RowHighlight(r)
    r.name = ns.Skin.Text(r, "GameFontNormal"); r.name:SetPoint("LEFT", 6, 0); r.name:SetPoint("RIGHT", -52, 0); r.name:SetWordWrap(false)
    r.lv = ns.Skin.Text(r, "GameFontHighlightSmall", "RIGHT"); r.lv:SetPoint("RIGHT", -6, 0)
    r:SetScript("OnClick", function(s) if s.inst then J.Select(s.inst) end end)
    J.rows[i] = r
  end

  -- right side: header
  local right = CreateFrame("Frame", nil, f)
  right:SetPoint("TOPLEFT", list, "TOPRIGHT", 10, 30)
  right:SetPoint("BOTTOMRIGHT", -10, 10)
  J.right = right
  J.hName = ns.Skin.Text(right, "GameFontNormalLarge"); J.hName:SetPoint("TOPLEFT", 2, -2)
  J.hSub = ns.Skin.Text(right, "GameFontHighlightSmall"); J.hSub:SetPoint("TOPLEFT", J.hName, "BOTTOMLEFT", 0, -4); J.hSub:SetPoint("RIGHT", right, "RIGHT", -100, 0)
  J.entranceBtn = MakeButton(right, "Entrance", 90)
  J.entranceBtn:SetPoint("TOPRIGHT", 0, 0)
  J.entranceBtn:SetScript("OnClick", function()
    local d = J.current
    local e = d and d.entrances and d.entrances[J.entranceIdx or 1]
    if e then Waypoint(e[1], e[2], e[3], d.name .. " entrance") end
    if d and d.entrances and #d.entrances > 1 then J.entranceIdx = ((J.entranceIdx or 1) % #d.entrances) + 1 end
  end)
  J.optHide = MakeButton(right, "Hide done", 100)
  J.optHide:SetPoint("TOPRIGHT", 0, -44)
  J.optHide:SetScript("OnClick", function() DB.hideDone = not DB.hideDone; J.RefreshContent() end)
  J.optFac = MakeButton(right, "My quests", 100)
  J.optFac:SetPoint("RIGHT", J.optHide, "LEFT", -4, 0)
  J.optFac:SetScript("OnClick", function() DB.allQuests = not DB.allQuests; J.RefreshContent() end)

  -- bottom tabs, like the character sheet
  J.tabs = {}
  local tabs = ns.Skin.Tabs(f, TABS, function(i) J.tab = TABS[i]; DB.tab = TABS[i]; J.RefreshContent() end)
  for i, name in ipairs(TABS) do J.tabs[name] = tabs[i] end

  -- scrolling content in an inset
  local body = ns.Skin.Inset(right)
  body:SetPoint("TOPLEFT", 0, -70)
  body:SetPoint("BOTTOMRIGHT", 0, 0)
  local sf = CreateFrame("ScrollFrame", nil, body, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 6, -6)
  sf:SetPoint("BOTTOMRIGHT", -28, 6)
  local child = CreateFrame("Frame", nil, sf)
  child:SetSize(W - LIST_W - 70, 10)
  sf:SetScrollChild(child)
  J.scroll, J.child = sf, child
  J.pool = { text = {}, item = {}, btn = {} }
  J.used = { text = 0, item = 0, btn = 0 }

  f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  f:RegisterEvent("QUEST_LOG_UPDATE")
  f:RegisterEvent("QUEST_TURNED_IN")
  f:SetScript("OnEvent", function()
    if f:IsShown() and not J.pending then
      J.pending = true
      C_Timer.After(0.3, function() J.pending = false; if f:IsShown() then J.RefreshContent() end end)
    end
  end)
  f:SetScript("OnShow", function() ScanLog(); J.RefreshList(); J.RefreshContent() end)
end

-- ------------------------------------------------------------------ list
local function Matches(d, filter)
  if not filter or filter == "" then return true end
  if d.name:lower():find(filter, 1, true) then return true end
  for _, b in ipairs(d.bosses or {}) do
    if b.name and b.name:lower():find(filter, 1, true) then return true end
    for _, it in ipairs(b.items) do
      local name = ItemInfo(it[1])
      if name and name:lower():find(filter, 1, true) then return true end
    end
  end
  return false
end

function J.RefreshList()
  if not J.rows then return end
  local shown = {}
  local lastRaid
  for _, d in ipairs(instances) do
    if Matches(d, J.filter) then
      if lastRaid ~= d.raid then table.insert(shown, { header = d.raid and "Raids" or "Dungeons" }); lastRaid = d.raid end
      table.insert(shown, d)
    end
  end
  local off = math.min(J.listOffset or 0, math.max(0, #shown - J.ROWS))
  J.listOffset = off
  for i, r in ipairs(J.rows) do
    local e = shown[i + off]
    r.inst = nil
    r.sel:Hide()
    if not e then
      r:Hide()
    else
      r:Show()
      if e.header then
        r.name:SetText(HEX.white .. e.header .. "|r"); r.lv:SetText("")
      else
        r.inst = e
        local l = e.levels or {}
        r.name:SetText((e.forever and HEX.violet or HEX.gold) .. e.name .. "|r")
        r.lv:SetText(LevelColor(l[1], l[3]) .. (l[1] and (l[1] .. "-" .. (l[3] or "")) or "") .. "|r")
        if e == J.current then r.sel:Show() end
      end
    end
  end
end

-- ------------------------------------------------------------------ content (pooled widgets)
local function ResetPool()
  for kind, list in pairs(J.pool) do for _, w in ipairs(list) do w:Hide() end; J.used[kind] = 0 end
end
local function GetText()
  J.used.text = J.used.text + 1
  local t = J.pool.text[J.used.text]
  if not t then
    t = Text(J.child, 12)
    t:SetWidth(J.child:GetWidth() - 8)
    t:SetWordWrap(true)
    J.pool.text[J.used.text] = t
  end
  t:ClearAllPoints(); t:SetFont(FONT_BODY, 12, ""); t:Show()
  return t
end
local function GetItemButton(size)
  J.used.item = J.used.item + 1
  local b = J.pool.item[J.used.item]
  if not b then
    b = CreateFrame("Button", nil, J.child)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.border = b:CreateTexture(nil, "OVERLAY")
    b.border:SetTexture("Interface\\Common\\WhiteIconFrame")
    b.border:SetAllPoints()
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b.label = Text(b, 11)
    b.label:SetPoint("LEFT", b, "RIGHT", 6, 0)
    b:SetScript("OnEnter", function(s)
      GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
      if GameTooltip.SetItemByID then GameTooltip:SetItemByID(s.itemID) else GameTooltip:SetHyperlink("item:" .. s.itemID) end
      if s.note then GameTooltip:AddLine(s.note, 0.56, 0.58, 0.54, true) end
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function(s)
      local _, link = ItemInfo(s.itemID)
      if not link then return end
      if IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then ChatEdit_InsertLink(link)
      elseif IsModifiedClick and IsModifiedClick("DRESSUP") and DressUpItemLink then DressUpItemLink(link) end
    end)
    J.pool.item[J.used.item] = b
  end
  b:SetSize(size, size)
  b:ClearAllPoints(); b.label:SetText(""); b.note = nil; b:Show()
  return b
end
local function GetSmallButton(text)
  J.used.btn = J.used.btn + 1
  local b = J.pool.btn[J.used.btn]
  if not b then b = ns.Skin.Button(J.child, text, 40, 20); J.pool.btn[J.used.btn] = b end
  b:SetLabel(text); b:ClearAllPoints(); b:Show()
  return b
end

local function SetItem(b, id, showName)
  local name, _, quality, icon = ItemInfo(id)
  b.itemID = id
  b.icon:SetTexture(icon)
  local hex = QUALITY_HEX[quality or 1] or "ffffffff"
  local r, g, bl = tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, tonumber(hex:sub(7, 8), 16) / 255
  b.border:SetVertexColor(r, g, bl, 1)
  if showName then b.label:SetText("|c" .. hex .. (name or ("item " .. id)) .. "|r") end
end

local function DrawLoot(d, y)
  local fac = PlayerFaction()
  local colW = (J.child:GetWidth() - 8) / 2
  for _, boss in ipairs(d.bosses or {}) do
    local t = GetText()
    t:SetPoint("TOPLEFT", 4, y)
    t:SetFont(FONT_BODY, 14, "")
    t:SetText(HEX.gold .. (boss.name or "?") .. "|r" .. (boss.rare and (HEX.muted .. "  rare|r") or "") .. (boss.level and (HEX.muted .. "  level " .. boss.level .. "|r") or ""))
    y = y - 22
    if boss.desc then
      local dsc = GetText()
      dsc:SetPoint("TOPLEFT", 4, y)
      dsc:SetFont(FONT_BODY, 11, "")
      dsc:SetText(HEX.muted .. boss.desc .. "|r")
      y = y - dsc:GetStringHeight() - 4
    end
    local col = 0
    local shown = 0
    for _, it in ipairs(boss.items) do
      if not it[2] or not fac or it[2] == fac then
        local b = GetItemButton(24)
        b:SetPoint("TOPLEFT", 4 + col * colW, y)
        SetItem(b, it[1], true)
        b.label:SetWidth(colW - 36)
        col = col + 1
        shown = shown + 1
        if col == 2 then col = 0; y = y - 28 end
      end
    end
    if col ~= 0 then y = y - 28 end
    if shown == 0 then
      local n = GetText(); n:SetPoint("TOPLEFT", 4, y); n:SetText(HEX.muted .. (d.forever and "Loot not known yet." or "No loot listed.") .. "|r"); y = y - 18
    end
    y = y - 8
  end
  return y
end

local function StatusOf(q)
  if QuestDone(q.id) then return "done" end
  if logIDs[q.id] then return "log" end
  return nil
end

local function DrawQuests(d, y)
  local lvl = UnitLevel("player") or 1
  local any = false
  local hidden = 0
  for _, q in ipairs(d.quests or {}) do
    local fits = QuestFits(q)
    local status = StatusOf(q)
    if (fits or DB.allQuests) and not (DB.hideDone and status == "done") then
      any = true
      local t = GetText()
      t:SetPoint("TOPLEFT", 4, y)
      t:SetWidth(J.child:GetWidth() - 60)
      local lc = (q.req and lvl < q.req) and HEX.red or ((q.lvl and lvl > q.lvl + 7) and HEX.muted or HEX.green)
      local tag = status == "done" and (HEX.muted .. "  done|r") or status == "log" and (HEX.gold .. "  in your log|r") or ""
      local fac = q.fac == "H" and (HEX.red .. " H|r") or q.fac == "A" and ("|cff6f9dff A|r") or ""
      local fv = q.forever and (HEX.violet .. "  Forever|r") or ""
      t:SetText(lc .. "[" .. (q.lvl or "?") .. "]|r " .. (status == "done" and HEX.muted or HEX.white) .. q.name .. "|r" .. fac .. tag .. fv
        .. (not fits and (HEX.muted .. "  (not for you)|r") or ""))
      local go = GetSmallButton("Go")
      go:SetPoint("TOPRIGHT", J.child, "TOPRIGHT", -4, y + 1)
      go:SetScript("OnClick", function()
        local p = (status == "log" and q.r) or q.g
        if p and p[1] == 0 then p = q.r end   -- item-started quests: go to whoever takes it
        if p then Waypoint(p[1], p[2], p[3], (p[4] or "") .. ": " .. q.name) end
      end)
      y = y - 16
      local lines = {}
      if q.g then
        lines[#lines + 1] = HEX.muted .. "From|r " .. HEX.ink .. (q.g[4] or "?") .. "|r" .. (q.g[1] ~= 0 and (HEX.muted .. ", " .. (ZONE_NAMES[q.g[1]] or q.g[1]) .. string.format(" %.0f,%.0f", q.g[2], q.g[3]) .. "|r") or "")
      end
      if q.r and q.g and q.r[4] ~= q.g[4] then
        lines[#lines + 1] = HEX.muted .. "To|r " .. HEX.ink .. (q.r[4] or "?") .. "|r" .. (q.r[1] ~= 0 and (HEX.muted .. ", " .. (ZONE_NAMES[q.r[1]] or q.r[1]) .. "|r") or "")
      end
      if q.pre and #q.pre > 0 then
        local names = {}
        for _, p in ipairs(q.pre) do
          local n = J.questName[p] or ("quest " .. p)
          names[#names + 1] = (QuestDone(p) and HEX.muted or HEX.gold) .. n .. "|r"
        end
        lines[#lines + 1] = HEX.muted .. "After|r " .. table.concat(names, HEX.muted .. " or |r")
      end
      if q.req then lines[#lines + 1] = HEX.muted .. "Requires level " .. q.req .. "|r" end
      local body = GetText()
      body:SetPoint("TOPLEFT", 18, y)
      body:SetWidth(J.child:GetWidth() - 30)
      body:SetFont(FONT_BODY, 11, "")
      body:SetText(table.concat(lines, "\n"))
      y = y - body:GetStringHeight() - 2
      if q.txt then
        local tx = GetText()
        tx:SetPoint("TOPLEFT", 18, y)
        tx:SetWidth(J.child:GetWidth() - 30)
        tx:SetFont(FONT_BODY, 11, "")
        tx:SetText(HEX.muted .. q.txt .. "|r")
        y = y - tx:GetStringHeight() - 2
      end
      if q.rew then
        local x = 18
        for _, id in ipairs(q.rew) do
          local b = GetItemButton(22)
          b:SetPoint("TOPLEFT", x, y)
          SetItem(b, id, false)
          b.note = "Quest reward: " .. q.name
          x = x + 26
          if x > J.child:GetWidth() - 30 then x = 18; y = y - 26 end
        end
        y = y - 26
      end
      y = y - 8
    else
      hidden = hidden + 1
    end
  end
  if not any then
    local t = GetText(); t:SetPoint("TOPLEFT", 4, y)
    t:SetText(HEX.muted .. ((d.quests and #d.quests > 0) and "Nothing to show with the current filters." or "No quests known for this instance.") .. "|r")
    y = y - 20
  end
  if hidden > 0 then
    local t = GetText(); t:SetPoint("TOPLEFT", 4, y - 4)
    t:SetText(HEX.muted .. hidden .. " quest" .. (hidden == 1 and "" or "s") .. " hidden (other faction or class, or done).|r")
    y = y - 24
  end
  return y
end

function J.RefreshContent()
  if not J.frame then return end
  local d = J.current
  ResetPool()
  for i, name in ipairs(TABS) do if name == J.tab then ns.Skin.SelectTab(J.frame, i) end end
  J.optHide:SetLabel(DB.hideDone and "Show done" or "Hide done")
  J.optFac:SetLabel(DB.allQuests and "All quests" or "My quests")
  J.optHide:SetShown(J.tab == "Quests"); J.optFac:SetShown(J.tab == "Quests")
  if not d then
    J.hName:SetText("Pick a dungeon"); J.hSub:SetText(""); J.entranceBtn:Hide()
    return
  end
  local l = d.levels or {}
  J.hName:SetText(d.name)
  local ent = d.entrances and d.entrances[1]
  J.hSub:SetText((d.raid and "Raid" or "Dungeon") .. HEX.muted .. "  ·  levels " .. LevelColor(l[1], l[3]) .. (l[1] or "?") .. "-" .. (l[3] or "?") .. "|r"
    .. (l[2] and (HEX.muted .. " (best " .. l[2] .. ")|r") or "")
    .. (ent and (HEX.muted .. "  ·  entrance in " .. HEX.ink .. (ZONE_NAMES[ent[1]] or "?") .. string.format(" %.0f,%.0f|r", ent[2], ent[3])) or ""))
  J.entranceBtn:SetShown(ent ~= nil)
  local y = -4
  if d.forever or d.note then
    local t = GetText()
    t:SetPoint("TOPLEFT", 4, y)
    t:SetText(HEX.violet .. "WoW Forever|r" .. HEX.muted .. (d.note and ("  " .. d.note) or "  new in Forever; data from the beta, check in game") .. "|r")
    y = y - t:GetStringHeight() - 8
  end
  if J.tab == "Quests" then y = DrawQuests(d, y) else y = DrawLoot(d, y) end
  J.child:SetHeight(math.max(10, -y + 10))
end

function J.Select(d)
  J.current = d
  J.entranceIdx = 1
  DB.last = d.key
  J.scroll:SetVerticalScroll(0)
  J.RefreshList()
  J.RefreshContent()
end

function J.Toggle(query)
  if not J.frame then Build() end
  if query and query ~= "" then
    local qq = query:lower()
    for _, d in ipairs(instances) do
      if d.name:lower():find(qq, 1, true) or d.key:lower():find(qq, 1, true) then J.frame:Show(); J.Select(d); return end
    end
    say("no dungeon matches '" .. query .. "'.")
    return
  end
  if J.frame:IsShown() then J.frame:Hide() else J.frame:Show() end
end

function J.Open(d, tab)
  if not J.frame then Build() end
  J.frame:Show()
  if tab then J.tab = tab end
  J.Select(d)
end

-- ------------------------------------------------------------------ world map markers
-- Dungeon entrances and dungeon quest givers for the zone the world map shows.
local pins, pinOwner = {}, nil
local function PinScale()
  local sc = WorldMapFrame and WorldMapFrame.ScrollContainer
  if sc and sc.GetCanvasScale then local ok, s = pcall(sc.GetCanvasScale, sc); if ok and s and s > 0 then return 1 / s end end
  return 1
end

local function GetPin(i, canvas)
  local p = pins[i]
  if not p then
    p = CreateFrame("Button", nil, canvas)
    p:SetSize(20, 20)
    p.tex = p:CreateTexture(nil, "OVERLAY")
    p.tex:SetAllPoints()
    p:SetScript("OnEnter", function(s)
      GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
      GameTooltip:AddLine(s.title, 1, 1, 1)
      for _, l in ipairs(s.lines or {}) do GameTooltip:AddLine(l, 0.85, 0.86, 0.81, true) end
      GameTooltip:AddLine("Click: open the journal", 0.56, 0.58, 0.54)
      GameTooltip:Show()
    end)
    p:SetScript("OnLeave", function() GameTooltip:Hide() end)
    p:SetScript("OnClick", function(s) if s.inst then J.Open(s.inst, s.tab) end end)
    pins[i] = p
  end
  return p
end

local function RefreshPins()
  for _, p in ipairs(pins) do p:Hide() end
  if not DB or DB.pins == false or not WorldMapFrame or not WorldMapFrame:IsShown() then return end
  local canvas = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
  local mapID = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
  if not canvas or not mapID then return end
  local w, h = canvas:GetSize()
  if not w or w == 0 then return end
  local scale = PinScale()
  local lvl = UnitLevel("player") or 1
  local n = 0
  -- entrances
  for _, d in ipairs(instances) do
    for _, e in ipairs(d.entrances or {}) do
      if e[1] == mapID then
        n = n + 1
        local p = GetPin(n, canvas)
        p.tex:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
        p:SetSize(22, 22); p:SetScale(scale)
        p:ClearAllPoints(); p:SetPoint("CENTER", canvas, "TOPLEFT", e[2] / 100 * w / scale, -e[3] / 100 * h / scale)
        local l = d.levels or {}
        p.title = d.name
        p.lines = { (d.raid and "Raid" or "Dungeon") .. ", levels " .. (l[1] or "?") .. "-" .. (l[3] or "?"), (d.quests and #d.quests or 0) .. " quests, " .. #(d.bosses or {}) .. " bosses" }
        p.inst, p.tab = d, "Loot"
        p:SetFrameLevel(canvas:GetFrameLevel() + 20)
        p:Show()
      end
    end
  end
  -- quest givers: quests you can take now or soon, not done, grouped per spot
  local spots = {}
  for _, d in ipairs(instances) do
    for _, q in ipairs(d.quests or {}) do
      if q.g and q.g[1] == mapID and QuestFits(q) and not QuestDone(q.id) and not logIDs[q.id]
         and (not q.req or q.req <= lvl + 3) and (not q.lvl or q.lvl >= lvl - 8) then
        local k = string.format("%.0f:%.0f", q.g[2], q.g[3])
        spots[k] = spots[k] or { x = q.g[2], y = q.g[3], npc = q.g[4], quests = {}, inst = d }
        table.insert(spots[k].quests, q)
      end
    end
  end
  for _, s in pairs(spots) do
    n = n + 1
    local p = GetPin(n, canvas)
    p.tex:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    p:SetSize(16, 16); p:SetScale(scale)
    p:ClearAllPoints(); p:SetPoint("CENTER", canvas, "TOPLEFT", s.x / 100 * w / scale, -s.y / 100 * h / scale)
    p.title = s.npc or "Quest giver"
    p.lines = {}
    for _, q in ipairs(s.quests) do
      local req = q.req and q.req > lvl and ("|cffe08a7a (level " .. q.req .. ")|r") or ""
      table.insert(p.lines, "[" .. (q.lvl or "?") .. "] " .. q.name .. req)
    end
    table.insert(p.lines, "|cff8f958aDungeon quests: " .. s.inst.name .. "|r")
    p.inst, p.tab = s.inst, "Quests"
    p:SetFrameLevel(canvas:GetFrameLevel() + 21)
    p:Show()
  end
end
J.RefreshPins = RefreshPins

local function HookMap()
  if pinOwner or not WorldMapFrame then return end
  pinOwner = true
  WorldMapFrame:HookScript("OnShow", function() ScanLog(); RefreshPins() end)
  if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", RefreshPins) end
  -- the canvas zooms: keep pins the same size on screen
  local last, acc = 0, 0
  WorldMapFrame:HookScript("OnUpdate", function(_, e)
    acc = acc + e
    if acc < 0.2 then return end
    acc = 0
    local s = PinScale()
    if math.abs(s - last) > 0.01 then last = s; RefreshPins() end
  end)
end

-- ------------------------------------------------------------------ boot
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, name)
  if event == "ADDON_LOADED" and name == ADDON then
    if not ns.ModuleEnabled("journal") then ns.Journal = nil; self:UnregisterAllEvents(); return end
    EvergreenDB.journal = EvergreenDB.journal or { pins = true, tab = "Loot" }
    DB = EvergreenDB.journal
    J.tab = DB.tab or "Loot"
    Prepare()
  end
  if not DB then return end
  if event == "PLAYER_LOGIN" or name == "Blizzard_WorldMap" then HookMap() end
end)

function J.Slash(rest)
  rest = rest or ""
  if rest == "pins" then
    DB.pins = not DB.pins
    say("world map markers " .. (DB.pins and "on" or "off") .. ".")
    RefreshPins()
    return
  elseif rest == "clear" then
    if ns.ClearExternalTarget then ns.ClearExternalTarget() end
    say("waypoint cleared; the arrow follows the guide again.")
    return
  elseif rest == "help" then
    say("/ej (toggle), /ej <dungeon> (open it), /ej pins (world map markers), /ej clear (drop the journal waypoint)")
    return
  end
  if not J.frame then Build() end
  if rest == "" and not J.current and DB.last then
    for _, d in ipairs(instances) do if d.key == DB.last then J.current = d end end
  end
  J.Toggle(rest)
end

SLASH_EVERGREENJOURNAL1 = "/ej"
SLASH_EVERGREENJOURNAL2 = "/journal"
SlashCmdList["EVERGREENJOURNAL"] = function(msg)
  if not ns.Journal then print(HEX.green .. "Evergreen:|r Journal module is off. /eg module journal on, then /reload."); return end
  J.Slash(strtrim and strtrim(msg or "") or (msg or ""))
end
