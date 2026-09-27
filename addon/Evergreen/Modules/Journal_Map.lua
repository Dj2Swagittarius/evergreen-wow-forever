-- Journal map: the Map tab of the dungeon journal (Journal.lua).
--
-- Draws the dungeon's own interior map (the client's dungeon uiMaps and their art tiles) inside the
-- journal, with a button per floor. Maps are found at runtime by name; /ej maps reports which
-- journal dungeons found one, so missing names can be added to ALIASES.

local ADDON, ns = ...
local J = ns.Journal
if not J then return end

local DUNGEON_TYPE = (Enum and Enum.UIMapType and Enum.UIMapType.Dungeon) or 4
local MAX_MAP_ID = 3000

-- journal name -> map name, where they differ
local ALIASES = {
  ["Lower Blackrock Spire"] = "Blackrock Spire", ["Upper Blackrock Spire"] = "Blackrock Spire",
  ["Dire Maul East"] = "Dire Maul", ["Dire Maul North"] = "Dire Maul", ["Dire Maul West"] = "Dire Maul",
  ["Temple of Ahn'Qiraj"] = "Ahn'Qiraj",
}

local function norm(s) return ((s or ""):lower():gsub("^the ", ""):gsub("[^%w]", "")) end

local index   -- normalised map name -> { mapID, ... }
local function BuildIndex()
  index = {}
  if not (C_Map and C_Map.GetMapInfo) then return end
  for id = 1, MAX_MAP_ID do
    local info = C_Map.GetMapInfo(id)
    if info and info.name and info.mapType == DUNGEON_TYPE then
      local k = norm(info.name)
      index[k] = index[k] or {}
      table.insert(index[k], id)
    end
  end
end

-- Floors of a journal dungeon: { {id=, name=}, ... } or nil when the client has no map for it.
function J.MapFloors(d)
  if not index then BuildIndex() end
  local base, wing = d.name:match("^(.-) %- (.+)$")
  local ids = index[norm(ALIASES[d.name] or base or d.name)]
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
local function DrawFloor(c, mapID, width)
  for _, t in ipairs(c.tiles) do t:Hide() end
  local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(mapID)
  local L = layers and layers[1]
  local tex = L and C_Map.GetMapArtLayerTextures and C_Map.GetMapArtLayerTextures(mapID, 1)
  if not (L and tex and #tex > 0 and L.layerWidth and L.layerWidth > 0) then return nil end
  local cols = math.ceil(L.layerWidth / L.tileWidth)
  local scale = width / L.layerWidth
  for i, fid in ipairs(tex) do
    local t = c.tiles[i]
    if not t then t = c:CreateTexture(nil, "ARTWORK"); c.tiles[i] = t end
    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
    t:SetTexture(fid)
    t:SetSize(L.tileWidth * scale, L.tileHeight * scale)
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
  local h = DrawFloor(c, floors[idx].id, width)
  if not h then return note("This map has no artwork in this client.") end
  c:ClearAllPoints()
  c:SetPoint("TOPLEFT", 4, y)
  c:Show()
  return y - h - 8
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
