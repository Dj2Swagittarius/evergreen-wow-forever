-- Journal map: the Map tab of the dungeon journal (Journal.lua).
--
-- Draws the dungeon's interior map inside the journal, with a button per floor. The WoW Forever
-- client has no dungeon uiMaps, but it still ships the classic map artwork: Journal_MapData.lua
-- (tools/build_maps.py) lists those tiles per dungeon. Clients that do have dungeon uiMaps are
-- looked up at runtime by name as a fallback. /ej maps reports which dungeons have a map.

local ADDON, ns = ...
local J = ns.Journal
if not J then return end

local DUNGEON_TYPE = (Enum and Enum.UIMapType and Enum.UIMapType.Dungeon) or 4
local MAX_MAP_ID = 5000
-- UIMapType: 0 cosmic, 1 world, 2 continent, 3 zone, 4 dungeon, 5 micro, 6 orphan. Dungeon floors are
-- normally type 4, but accept micro/orphan maps too when no dungeon-type map carries the name.
local FALLBACK_TYPES = { [5] = true, [6] = true }

-- journal name -> map name, where they differ
local ALIASES = {
  ["Lower Blackrock Spire"] = "Blackrock Spire", ["Upper Blackrock Spire"] = "Blackrock Spire",
  ["Dire Maul East"] = "Dire Maul", ["Dire Maul North"] = "Dire Maul", ["Dire Maul West"] = "Dire Maul",
  ["Temple of Ahn'Qiraj"] = "Ahn'Qiraj",
}

local function norm(s) return ((s or ""):lower():gsub("^the ", ""):gsub("[^%w]", "")) end

local index, fallback   -- normalised map name -> { mapID, ... } (dungeon maps; micro / orphan maps)
local function BuildIndex()
  index, fallback = {}, {}
  if not (C_Map and C_Map.GetMapInfo) then return end
  for id = 1, MAX_MAP_ID do
    local info = C_Map.GetMapInfo(id)
    if info and info.name then
      local t = info.mapType == DUNGEON_TYPE and index or FALLBACK_TYPES[info.mapType] and fallback
      if t then
        local k = norm(info.name)
        t[k] = t[k] or {}
        table.insert(t[k], id)
      end
    end
  end
end

-- shipped classic artwork: 4 x 3 tiles of 256 px, 1002 x 668 used
local SHIPPED_LAYER = { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 }

-- New Forever dungeons have no map in the client: fan-made maps shipped as addon textures
-- (tools/convert_map_images.py). 1024x1024 files with the map in the top w x h pixels.
local FAN_CREDIT = "Map: recreation by Santiago Reyes, Atlas de Azeroth Forever"
local SHIPPED_IMAGES = {
  HallOfThanes = { { name = "Map", file = "Interface\\AddOns\\Evergreen\\Maps\\HallOfThanes", w = 1024, h = 683, credit = FAN_CREDIT } },
  RuinsOfLordaeron = { { name = "Map", file = "Interface\\AddOns\\Evergreen\\Maps\\RuinsOfLordaeron", w = 1024, h = 683, credit = FAN_CREDIT } },
}
local IMAGE_SIZE = 1024

-- Floors of a journal dungeon: { {name=, tiles={fileIDs}} or {name=, file=, w=, h=} or
-- {name=, id=uiMapID}, ... }, or nil when there is no map for it.
function J.MapFloors(d)
  local shipped = SHIPPED_IMAGES[d.key] or (ns.DungeonMaps and ns.DungeonMaps[d.key])
  if shipped then return shipped end
  if not index then BuildIndex() end
  local base, wing = d.name:match("^(.-) %- (.+)$")
  local key = norm(ALIASES[d.name] or base or d.name)
  local ids = index[key] or fallback[key]
  if not ids then return nil end
  local floors = {}
  local g = C_Map.GetMapGroupID and C_Map.GetMapGroupID(ids[1])
  local members = g and C_Map.GetMapGroupMembersInfo and C_Map.GetMapGroupMembersInfo(g)
  if members and #members > 0 then
    table.sort(members, function(a, b) return (a.relativeHeightIndex or 0) < (b.relativeHeightIndex or 0) end)
    for _, m in ipairs(members) do floors[#floors + 1] = { id = m.mapID, name = m.name } end
  else
    for _, id in ipairs(ids) do floors[#floors + 1] = { id = id, name = (C_Map.GetMapInfo(id) or {}).name } end
  end
  -- Scarlet Monastery style wings: show the wing's own floor when one carries its name
  if wing then
    for _, f in ipairs(floors) do if norm(f.name) == norm(wing) then return { f } end end
  end
  return floors
end

local function Canvas()
  if J.mapCanvas then return J.mapCanvas end
  local c = CreateFrame("Frame", nil, J.child)
  c.tiles = {}
  J.mapCanvas = c
  table.insert(J.extras, c)
  return c
end

-- Draw one floor's art tiles scaled to width; returns the drawn height, or nil without art.
local function DrawFloor(c, floor, width)
  for _, t in ipairs(c.tiles) do t:Hide() end
  if floor.file then
    local t = c.tiles[1]
    if not t then t = c:CreateTexture(nil, "ARTWORK"); c.tiles[1] = t end
    local h = width * floor.h / floor.w
    t:SetTexture(floor.file)
    t:SetTexCoord(0, floor.w / IMAGE_SIZE, 0, floor.h / IMAGE_SIZE)
    t:SetSize(width, h)
    t:ClearAllPoints(); t:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
    t:Show()
    c:SetSize(width, h)
    return h
  end
  local L, tex
  if floor.tiles then
    L, tex = SHIPPED_LAYER, floor.tiles
  else
    local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(floor.id)
    L = layers and layers[1]
    tex = L and C_Map.GetMapArtLayerTextures and C_Map.GetMapArtLayerTextures(floor.id, 1)
  end
  if not (L and tex and #tex > 0 and L.layerWidth and L.layerWidth > 0) then return nil end
  local cols = math.ceil(L.layerWidth / L.tileWidth)
  local scale = width / L.layerWidth
  for i, fid in ipairs(tex) do
    local t = c.tiles[i]
    if not t then t = c:CreateTexture(nil, "ARTWORK"); c.tiles[i] = t end
    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
    -- edge tiles are only partly used: crop them to the layer size
    local tw = math.min(L.tileWidth, L.layerWidth - col * L.tileWidth)
    local th = math.min(L.tileHeight, L.layerHeight - row * L.tileHeight)
    t:SetTexture(fid)
    t:SetTexCoord(0, tw / L.tileWidth, 0, th / L.tileHeight)
    t:SetSize(tw * scale, th * scale)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", c, "TOPLEFT", col * L.tileWidth * scale, -row * L.tileHeight * scale)
    t:Show()
  end
  local h = L.layerHeight * scale
  c:SetSize(width, h)
  return h
end

function J.DrawMap(d, y)
  local HEX = J.HEX
  local floors = J.MapFloors(d)
  local function note(s) local t = J.GetText(); t:SetPoint("TOPLEFT", 4, y); t:SetText(HEX.muted .. s .. "|r"); return y - 18 end
  if not floors or #floors == 0 then return note("No map for this dungeon in this client yet.") end
  local idx = math.min(J.floorIdx or 1, #floors)
  J.floorIdx = idx
  if #floors > 1 then
    local x, maxW = 4, J.child:GetWidth() - 8
    for i, f in ipairs(floors) do
      local label = f.name or ("Floor " .. i)
      local b = J.GetSmallButton(label)
      local w = math.max(60, #label * 7 + 20)
      b:SetWidth(w)
      if x > 4 and x + w > maxW then x = 4; y = y - 24 end
      b:SetPoint("TOPLEFT", x, y)
      if i == idx then b:LockHighlight() else b:UnlockHighlight() end
      b:SetScript("OnClick", function() J.floorIdx = i; J.RefreshContent() end)
      x = x + w + 4
    end
    y = y - 30
  end
  local c = Canvas()
  local width = J.child:GetWidth() - 8
  if width <= 0 then width = 520 end
  local h = DrawFloor(c, floors[idx], width)
  if not h then return note("This map has no artwork in this client.") end
  c:ClearAllPoints()
  c:SetPoint("TOPLEFT", 4, y)
  c:Show()
  y = y - h - 6
  if floors[idx].credit then
    local t = J.GetText(); t:SetPoint("TOPLEFT", 4, y); t:SetText(HEX.muted .. floors[idx].credit .. "|r")
    y = y - 16
  end
  return y - 4
end

-- /ej maps <text>: every map whose name contains <text>, with id and type (to see what the client has)
function J.ProbeMaps(text, say)
  text = text:lower()
  local hits, n = {}, 0
  for id = 1, MAX_MAP_ID do
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(id)
    if info and info.name and info.name:lower():find(text, 1, true) then
      n = n + 1
      if n <= 20 then hits[#hits + 1] = id .. "=" .. info.name .. " (type " .. tostring(info.mapType) .. ")" end
    end
  end
  say(n .. " maps match '" .. text .. "'" .. (n > 0 and (": " .. table.concat(hits, ", ")) or "") .. (n > 20 and " ..." or ""))
end

-- /ej maps: which journal dungeons found a map (to fix ALIASES after checking in game)
function J.ReportMaps(instances, say)
  local found, missing = 0, {}
  for _, d in ipairs(instances) do
    local f = J.MapFloors(d)
    if f then found = found + 1 else missing[#missing + 1] = d.name end
  end
  say(found .. " dungeons have a map. " .. (#missing > 0 and ("No map: " .. table.concat(missing, ", ") .. ".") or ""))
end
