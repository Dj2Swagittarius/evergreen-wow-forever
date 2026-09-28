-- Reveal module: removes the fog on the world map, so every zone shows its unexplored areas.
--
-- The world map draws explored areas as overlay textures listed by
-- C_MapExplorationInfo.GetExploredMapTextures. The client never hands out the
-- unexplored ones, so ns.RevealData (Reveal_Data.lua, generated from the WoW Forever
-- beta client's WorldMapOverlay/WorldMapOverlayTile tables) lists every overlay per
-- uiMapArtID. After Blizzard's MapExplorationPin draws the explored overlays, this
-- draws the rest from the same texture pool, with the same tiling math, optionally tinted
-- so unexplored ground still stands out. Nothing is written to the server; exploration
-- progress (and its XP) is untouched.

local ADDON, ns = ...

local HEX = { green = "|cff7fd35e", muted = "|cff8f958a" }
local TINT = { 0.55, 0.75, 1.0 }   -- unexplored overlays, when tint is on

local DB
local hookedPins = {}

-- Refreshing before the map has set up its zoom levels errors inside
-- Blizzard's MapCanvas (ipairs on nil zoomLevels), so wait until it has.
local function mapReady()
  local sc = WorldMapFrame and WorldMapFrame.ScrollContainer
  return sc and sc.zoomLevels ~= nil
end

local function refreshAll()
  if not WorldMapFrame or not WorldMapFrame.EnumeratePinsByTemplate or not mapReady() then return end
  for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
    pin:RefreshOverlays(true)
  end
end

local function nextPow2(n)
  local f = 16
  while f < n do f = f * 2 end
  return f
end

-- Runs right after MapExplorationPinMixin.RefreshOverlays, which has just released the
-- pool and drawn the explored overlays.
local function drawUnexplored(pin, fullUpdate)
  if not DB.on or not ns.RevealData then return end
  local map = pin:GetMap()
  local mapID = map and map:GetMapID()
  if not mapID then return end
  local artID = C_Map.GetMapArtID(mapID)
  local overlays = artID and ns.RevealData[artID]
  if not overlays then return end

  local explored = {}
  for _, info in ipairs(C_MapExplorationInfo.GetExploredMapTextures(mapID) or {}) do
    explored[info.textureWidth .. ":" .. info.textureHeight .. ":" .. info.offsetX .. ":" .. info.offsetY] = true
  end

  local layers = C_Map.GetMapArtLayers(mapID)
  local layerIndex = map:GetCanvasContainer():GetCurrentLayerIndex()
  local layer = layers and layers[layerIndex or 1]
  if not layer then return end
  local tileW, tileH = layer.tileWidth, layer.tileHeight

  for _, entry in ipairs(overlays) do
    local w, h, ox, oy, files = strsplit(":", entry)
    if not explored[w .. ":" .. h .. ":" .. ox .. ":" .. oy] then
      w, h, ox, oy = tonumber(w), tonumber(h), tonumber(ox), tonumber(oy)
      local ids = { strsplit(",", files) }
      local wide, tall = math.ceil(w / tileW), math.ceil(h / tileH)
      for j = 1, tall do
        local pxH, fileH = tileH, tileH
        if j == tall then
          pxH = h % tileH
          if pxH == 0 then pxH = tileH end
          fileH = nextPow2(pxH)
        end
        for k = 1, wide do
          local pxW, fileW = tileW, tileW
          if k == wide then
            pxW = w % tileW
            if pxW == 0 then pxW = tileW end
            fileW = nextPow2(pxW)
          end
          local fid = tonumber(ids[(j - 1) * wide + k])
          if fid then
            local tex = pin.overlayTexturePool:Acquire()
            tex:SetSize(pxW, pxH)
            tex:SetTexCoord(0, pxW / fileW, 0, pxH / fileH)
            tex:SetPoint("TOPLEFT", ox + tileW * (k - 1), -(oy + tileH * (j - 1)))
            tex:SetTexture(fid, nil, nil, "TRILINEAR")
            tex:SetDrawLayer("ARTWORK", -1)
            if DB.tint then tex:SetVertexColor(TINT[1], TINT[2], TINT[3]) else tex:SetVertexColor(1, 1, 1) end
            tex:Show()
            if fullUpdate and pin.textureLoadGroup then pin.textureLoadGroup:AddTexture(tex) end
          end
        end
      end
    end
  end
end

-- Pool textures are reused for explored overlays too, so undo any tint Blizzard would not.
local function resetTint(pin)
  if not pin.overlayTexturePool then return end
  for tex in pin.overlayTexturePool:EnumerateActive() do tex:SetVertexColor(1, 1, 1) end
end

local function hookPin(pin)
  if hookedPins[pin] then return end
  hookedPins[pin] = true
  hooksecurefunc(pin, "RefreshOverlays", function(self, fullUpdate)
    resetTint(self)
    local ok, err = pcall(drawUnexplored, self, fullUpdate)
    if not ok and not DB.errored then
      DB.errored = true
      print(HEX.green .. "Evergreen Reveal:|r " .. tostring(err))
    end
  end)
end

local function setup()
  if not WorldMapFrame or not WorldMapFrame.EnumeratePinsByTemplate then return false end
  for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do hookPin(pin) end
  -- the exploration pin can be (re)acquired after this point; catch it on every map change
  if not hookedPins.map and WorldMapFrame.OnMapChanged then
    hookedPins.map = true
    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
      for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        if not hookedPins[pin] then hookPin(pin); if mapReady() then pin:RefreshOverlays(true) end end
      end
    end)
  end
  refreshAll()
  return true
end

local function countData()
  local maps, overlays = 0, 0
  for _, list in pairs(ns.RevealData or {}) do maps = maps + 1; overlays = overlays + #list end
  return maps, overlays
end

ns.Reveal = {}
function ns.Reveal.Slash(rest)
  rest = rest or ""
  if rest == "" then
    DB.on = not DB.on
    print(HEX.green .. "Evergreen:|r world map reveal " .. (DB.on and "on" or "off") .. ".")
  elseif rest == "tint" then
    DB.tint = not DB.tint
    print(HEX.green .. "Evergreen:|r unexplored areas " .. (DB.tint and "tinted blue" or "shown in normal colours") .. ".")
  elseif rest == "info" then
    local maps, overlays = countData()
    local mapID = WorldMapFrame and WorldMapFrame:GetMapID()
    local art = mapID and C_Map.GetMapArtID(mapID)
    local here = art and ns.RevealData[art]
    local explored = mapID and C_MapExplorationInfo.GetExploredMapTextures(mapID)
    print(HEX.green .. "Evergreen Reveal:|r " .. (DB.on and "on" or "off") .. ", tint " .. (DB.tint and "on" or "off") ..
      ". Data: " .. maps .. " maps, " .. overlays .. " areas.")
    if mapID then
      print(string.format("  world map shows uiMapID %d (art %s): %d areas known, %d explored by this character.",
        mapID, tostring(art), here and #here or 0, explored and #explored or 0))
    end
    return
  else
    print(HEX.green .. "Evergreen Reveal|r: /eg reveal (toggle), /eg reveal tint, /eg reveal info")
    return
  end
  refreshAll()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, name)
  if event == "ADDON_LOADED" and name == ADDON then
    if not ns.ModuleEnabled("reveal") then ns.Reveal = nil; self:UnregisterAllEvents(); return end
    EvergreenDB.reveal = EvergreenDB.reveal or { on = true, tint = false }
    DB = EvergreenDB.reveal
    DB.errored = nil
  end
  if not DB then return end
  -- The world map lives in Blizzard_WorldMap; hook it whenever it is there.
  if (event == "PLAYER_LOGIN" or name == "Blizzard_WorldMap") and setup() then
    self:UnregisterAllEvents()
  end
end)
