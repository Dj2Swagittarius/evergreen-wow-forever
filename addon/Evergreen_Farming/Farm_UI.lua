-- Farming window: the routes per category (bottom tabs), filtered to where you are, and the picked
-- route's details with Follow / Stop / Prev / Next. Built from Blizzard's templates through ns.Skin,
-- like every Evergreen window (gold headings, white body, muted secondary text, list in an inset).

local ADDON, ns = ...
local F = ns.Farm
if not F then return end
local Skin = ns.Skin
local HEX = Skin.HEX

local W, H, LIST_W, ROW_H = 640, 470, 300, 30
local FILTERS = { "zone", "continent", "all" }
local FILTER_LABEL = { zone = "This zone", continent = "This continent", all = "All zones" }
local CONTINENT = { [1414] = "Kalimdor", [1415] = "Eastern Kingdoms" }
local ICONS = { Ore = "Interface\\Icons\\INV_Pick_02", Herbs = "Interface\\Icons\\INV_Misc_Flower_02", Leather = "Interface\\Icons\\INV_Misc_LeatherScrap_02" }

local UI = {}
F.UI = UI

local function DB() return F.db end

-- ------------------------------------------------------------------ list contents
local function PlayerWhere()
  local map = F.PlayerPos()
  if not map and C_Map and C_Map.GetBestMapForUnit then map = C_Map.GetBestMapForUnit("player") end
  return map, map and F.ContinentOf(map)
end

-- the zone the player is in, as one of the route zones (subzones / cities walk up to their zone)
local function PlayerZoneMap(map)
  local guard = 0
  while map and guard < 6 do
    for _, r in ipairs(F.routes) do if r.map == map then return map end end
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(map)
    map = info and info.parentMapID
    guard = guard + 1
  end
  return nil
end

function UI.Visible()
  local cat = F.CATEGORIES[DB().tab or 1] or "Ore"
  local filter = DB().filter or "continent"
  local q = (UI.search and UI.search:GetText() or ""):lower()
  local map, cont = PlayerWhere()
  local zoneMap = PlayerZoneMap(map)
  local out, lastCont, lastZone = {}, nil, nil
  for _, r in ipairs(F.routes) do
    local ok = r.category == cat
    if ok and filter == "zone" then ok = zoneMap == r.map end
    if ok and filter == "continent" and cont then ok = r.continent == cont end
    if ok and q ~= "" then
      local hay = (r.zone .. " " .. r.name .. " " .. table.concat(r.materials or {}, " ")):lower()
      ok = hay:find(q, 1, true) ~= nil
    end
    if ok then
      if r.continent ~= lastCont then out[#out + 1] = { header = CONTINENT[r.continent] or "Other" }; lastCont = r.continent end
      out[#out + 1] = r
    end
  end
  return out
end

-- ------------------------------------------------------------------ build
local function Build()
  local f = Skin.Window("EvergreenFarmFrame", W, H, "Farming Routes", ICONS.Ore,
    function(s) local p, _, rp, x, y = s:GetPoint(1); DB().pos = { p, rp, x, y } end)
  if DB().pos then f:ClearAllPoints(); f:SetPoint(DB().pos[1], UIParent, DB().pos[2], DB().pos[3], DB().pos[4]) end
  f:Hide()
  UI.frame = f
  local top = f.contentTop

  local search = Skin.Search(f, LIST_W - f.portraitW + 4, "Search zone or material")
  search:SetPoint("TOPLEFT", f.portraitW + 6, top - 8)
  search:HookScript("OnTextChanged", function() UI.offset = 0; UI.RefreshList() end)
  search:HookScript("OnEscapePressed", function(s) s:ClearFocus() end)
  UI.search = search

  UI.filterBtn = Skin.Button(f, FILTER_LABEL.continent, 120, 22)
  UI.filterBtn:SetPoint("TOPRIGHT", -10, top - 6)
  UI.filterBtn:SetScript("OnClick", function()
    local cur = DB().filter or "continent"
    for i, k in ipairs(FILTERS) do if k == cur then DB().filter = FILTERS[i % #FILTERS + 1] break end end
    UI.offset = 0
    UI.Refresh()
  end)
  UI.filterBtn:SetScript("OnEnter", function(s)
    GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Show routes in", 1, 0.82, 0)
    GameTooltip:AddLine("This zone / this continent / all zones", 1, 1, 1)
    GameTooltip:Show()
  end)
  UI.filterBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- the list: fixed rows in an inset, the mouse wheel scrolls
  local list = Skin.Inset(f)
  list:SetPoint("TOPLEFT", 10, top - 36)
  list:SetPoint("BOTTOMLEFT", 10, 10)
  list:SetWidth(LIST_W)
  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function(_, d) UI.offset = math.max(0, (UI.offset or 0) - d * 3); UI.RefreshList() end)
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
    r.zone = Skin.Text(r, "GameFontNormal"); r.zone:SetPoint("TOPLEFT", 6, -2); r.zone:SetPoint("RIGHT", -70, 0); r.zone:SetWordWrap(false)
    r.sub = Skin.Text(r, "GameFontHighlightSmall"); r.sub:SetPoint("TOPLEFT", r.zone, "BOTTOMLEFT", 0, -2); r.sub:SetPoint("RIGHT", -70, 0); r.sub:SetWordWrap(false)
    r.range = Skin.Text(r, "GameFontHighlightSmall", "RIGHT"); r.range:SetPoint("TOPRIGHT", -6, -3)
    r.range:SetWidth(80); if r.range.SetWordWrap then r.range:SetWordWrap(false) end
    r.pts = Skin.Text(r, "GameFontDisableSmall", "RIGHT"); r.pts:SetPoint("TOPRIGHT", r.range, "BOTTOMRIGHT", 0, -2)
    r:SetScript("OnClick", function(s) if s.route then UI.selected = s.route; UI.Refresh() end end)
    r:SetScript("OnDoubleClick", function(s) if s.route then F.Activate(s.route.id) end end)
    UI.rows[i] = r
  end
  UI.empty = Skin.Text(list, "GameFontHighlightSmall")
  UI.empty:SetPoint("TOPLEFT", 10, -10); UI.empty:SetPoint("RIGHT", -10, 0)

  -- details on the right
  local right = CreateFrame("Frame", nil, f)
  right:SetPoint("TOPLEFT", list, "TOPRIGHT", 10, 0)
  right:SetPoint("BOTTOMRIGHT", -10, 10)
  UI.right = right
  UI.title = Skin.Text(right, "GameFontNormalLarge"); UI.title:SetPoint("TOPLEFT", 2, -2); UI.title:SetPoint("RIGHT", -2, 0)
  UI.sub = Skin.Text(right, "GameFontHighlight"); UI.sub:SetPoint("TOPLEFT", UI.title, "BOTTOMLEFT", 0, -4); UI.sub:SetPoint("RIGHT", -2, 0)
  UI.meta = Skin.Text(right, "GameFontHighlightSmall"); UI.meta:SetPoint("TOPLEFT", UI.sub, "BOTTOMLEFT", 0, -6); UI.meta:SetPoint("RIGHT", -2, 0)
  UI.meta:SetSpacing(2)

  local body = Skin.Inset(right)
  body:SetPoint("TOPLEFT", 0, -92)
  body:SetPoint("BOTTOMRIGHT", 0, 92)
  UI.notes = Skin.Text(body, "GameFontHighlightSmall")
  UI.notes:SetPoint("TOPLEFT", 8, -8); UI.notes:SetPoint("BOTTOMRIGHT", -8, 8)
  UI.notes:SetSpacing(2)

  -- the active route
  UI.status = Skin.Text(right, "GameFontHighlightSmall")
  UI.status:SetPoint("BOTTOMLEFT", 2, 60); UI.status:SetPoint("RIGHT", -2, 0)
  UI.follow = Skin.Button(right, "Follow", 96, 22)
  UI.follow:SetPoint("BOTTOMLEFT", 0, 30)
  UI.follow:SetScript("OnClick", function() if UI.selected then F.Activate(UI.selected.id) end end)
  UI.stop = Skin.Button(right, "Stop", 70, 22)
  UI.stop:SetPoint("LEFT", UI.follow, "RIGHT", 4, 0)
  UI.stop:SetScript("OnClick", function() F.Stop() end)
  UI.arrowBtn = Skin.Button(right, "Hide arrow", 96, 22)
  UI.arrowBtn:SetPoint("LEFT", UI.stop, "RIGHT", 4, 0)
  UI.arrowBtn:SetScript("OnClick", function()
    DB().arrowHidden = not DB().arrowHidden
    F.UpdateTarget()
    UI.Refresh()
  end)
  UI.prev = Skin.Button(right, "< Prev", 80, 22)
  UI.prev:SetPoint("BOTTOMLEFT", 0, 4)
  UI.prev:SetScript("OnClick", function() F.Prev() end)
  UI.nextB = Skin.Button(right, "Next >", 80, 22)
  UI.nextB:SetPoint("LEFT", UI.prev, "RIGHT", 4, 0)
  UI.nextB:SetScript("OnClick", function() F.Next() end)
  UI.nearest = Skin.Button(right, "Nearest", 86, 22)
  UI.nearest:SetPoint("LEFT", UI.nextB, "RIGHT", 4, 0)
  UI.nearest:SetScript("OnClick", function()
    local r = F.Active()
    local i = r and F.NearestIndex(r)
    if i then F.SetIndex(i) end
  end)

  UI.tabs = Skin.Tabs(f, F.CATEGORIES, function(i) DB().tab = i; UI.offset = 0; UI.selected = nil; UI.Refresh() end)
  f:SetScript("OnShow", function() UI.Refresh() end)
end

-- No "open the map there" button: on this client C_Map.OpenWorldMap is restricted and
-- WorldMapFrame:SetMapID from addon code taints the map. The route shows when you open the map on
-- its zone (or its continent) yourself.

-- ------------------------------------------------------------------ refresh
function UI.RefreshList()
  if not UI.rows then return end
  local shown = UI.Visible()
  UI.shown = shown
  local off = math.min(UI.offset or 0, math.max(0, #shown - UI.ROWS))
  UI.offset = off
  local active = F.Active()
  for i, row in ipairs(UI.rows) do
    local e = shown[i + off]
    row.route = nil
    row.sel:Hide()
    if not e then
      row:Hide()
    else
      row:Show()
      if e.header then
        row.zone:SetText(HEX.white .. e.header .. "|r"); row.sub:SetText(""); row.range:SetText(""); row.pts:SetText("")
      else
        row.route = e
        row.zone:SetText(HEX.gold .. e.zone .. "|r" .. (e == active and (HEX.green .. "  (following)|r") or ""))
        row.sub:SetText(HEX.body .. e.name .. "|r" .. (e.approx and (HEX.muted .. "  approx.|r") or ""))
        row.range:SetText(HEX.white .. F.RangeText(e) .. "|r")
        row.pts:SetText(#e.points .. " pts")
        if e == UI.selected then row.sel:Show() end
      end
    end
  end
  if not F.HasData() then
    UI.empty:SetText(HEX.red .. "No routes installed.|r\n\n" .. HEX.muted .. "Run tools/import_wowprof_farming.py (it builds Evergreen_Farming/Farm_Data.lua from WoW-Professions' guides), then /reload.|r")
    UI.empty:Show()
  elseif #shown == 0 then
    UI.empty:SetText(HEX.muted .. "No " .. (F.CATEGORIES[DB().tab or 1] or "") .. " routes here. Try the button at the top right (zone / continent / all).|r")
    UI.empty:Show()
  else
    UI.empty:Hide()
  end
end

function UI.RefreshDetail()
  local r = UI.selected or F.Active()
  local active, idx = F.Active()
  if not r then
    UI.title:SetText(HEX.gold .. "Farming routes|r")
    UI.sub:SetText(HEX.muted .. "Pick a route on the left, then Follow.|r")
    UI.meta:SetText("")
    UI.notes:SetText(HEX.muted .. "Routes from WoW-Professions.com's classic farming guides, placed on GatherMate2's node spawns. " ..
      "The route shows on your world map and minimap; the arrow leads to the next point and moves on when you get within " ..
      F.ARRIVE_YARDS .. " yards.|r")
  else
    UI.title:SetText(HEX.gold .. r.zone .. "|r")
    UI.sub:SetText(HEX.white .. r.name .. "|r")
    local meta = {}
    meta[#meta + 1] = HEX.muted .. "Materials:|r " .. HEX.body .. table.concat(r.materials or {}, ", ") .. "|r"
    local range = r.skill and ("skill " .. r.skill[1] .. "-" .. r.skill[2]) or (r.level and ("mob level " .. r.level)) or nil
    meta[#meta + 1] = HEX.muted .. (range and (range .. ",  ") or "") .. #r.points .. " points (" .. F.NodeCount(r) .. " nodes)" ..
      (r.loop and ", loop" or "") .. (r.approx and ",  " .. HEX.red .. "approximate|r" or "") .. "|r"
    meta[#meta + 1] = HEX.muted .. "Source: " .. (r.source or "WoW-Professions") .. "|r"
    UI.meta:SetText(table.concat(meta, "\n"))
    UI.notes:SetText(HEX.body .. ((r.notes and r.notes ~= "") and r.notes or "No notes for this route.") .. "|r")
  end
  if active then
    local d = F.lastDist
    local where = d and F.FormatDist(d) or (F.lastMode == "continent" and "other continent" or F.lastMode == "zone" and ("in " .. active.zone) or "")
    UI.status:SetText(HEX.green .. "Following|r " .. HEX.gold .. active.zone .. "|r " .. HEX.white .. active.name .. "|r\n" ..
      HEX.muted .. "Next: " .. F.TargetTitle() .. "  " .. where .. "|r")
  else
    UI.status:SetText(HEX.muted .. "Not following a route.|r")
  end
  local canFollow = r and r ~= active
  if UI.follow.SetEnabled then UI.follow:SetEnabled(canFollow and true or false) end
  for _, b in ipairs({ UI.stop, UI.prev, UI.nextB, UI.nearest }) do
    if b.SetEnabled then b:SetEnabled(active and true or false) end
  end
end

function UI.Refresh()
  if not UI.frame then return end
  if UI.filterBtn then UI.filterBtn:SetLabel(FILTER_LABEL[DB().filter or "continent"]) end
  if UI.arrowBtn then UI.arrowBtn:SetLabel(DB().arrowHidden and "Show arrow" or "Hide arrow") end
  Skin.SelectTab(UI.frame, DB().tab or 1)
  -- the portrait keeps the Evergreen medallion (Grove theme), not a per-tab icon
  UI.RefreshList()
  UI.RefreshDetail()
end

function F.Toggle()
  if not UI.frame then Build() end
  if UI.frame:IsShown() then UI.frame:Hide() else
    if not UI.selected then
      local r = F.Active()
      if r then UI.selected = r; for i, c in ipairs(F.CATEGORIES) do if c == r.category then DB().tab = i end end end
    end
    UI.frame:Show()
    UI.Refresh()
  end
end

-- keep the window current while open
local acc = 0
F.On(function(what)
  if what == "login" then
    Skin.MinimapButton("farming", ICONS.Ore, 250,
      function(b) if b == "RightButton" then if F.Active() then F.Next() else F.Toggle() end else F.Toggle() end end,
      function(tt)
        tt:AddLine("Evergreen: farming routes", 1, 0.82, 0)
        local r = F.Active()
        if r then tt:AddLine("Following " .. r.zone .. ": " .. r.name, 1, 1, 1); tt:AddLine("Next: " .. F.TargetTitle(), 0.9, 0.9, 0.9) end
        tt:AddLine("Left-click: routes window", 0.9, 0.9, 0.9)
        tt:AddLine("Right-click: next point", 0.9, 0.9, 0.9)
      end)
    return
  end
  if not (UI.frame and UI.frame:IsShown()) then return end
  if what == "tick" then
    acc = acc + 1
    if acc < 5 then return end
    acc = 0
    UI.RefreshDetail()
  else
    UI.Refresh()
  end
end)
