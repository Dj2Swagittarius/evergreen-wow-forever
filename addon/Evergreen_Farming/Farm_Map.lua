-- Farming on the world map and the minimap.
--
-- World map: a MapCanvas data provider with Farming's own pin template (Farm_Map.xml): one pin the
-- size of the map canvas that draws the active route (lines, points, numbers, the next point
-- highlighted). Nothing of Blizzard's is acquired, replaced or refreshed: on the WoW Forever client
-- Blizzard's map code calls SetPassThroughButtons on pins, which is blocked for addon code, so this
-- pin's mixin turns that call into a no-op for itself only (as Evergreen does for GatherMate2's
-- pins), and it takes no mouse. The provider is refreshed by the map itself (map open, map change)
-- and by Farming when you pick or stop a route; a new point only redraws Farming's own pin.
-- Shows on the route's zone map and on any map that contains it (the continent).
--
-- Minimap: Farming's own textures on a layer over the minimap, placed from the player's world
-- position, the minimap's zoom (yards across) and rotation. The next point sits on the rim when it
-- is out of range.

local ADDON, ns = ...
local F = ns.Farm
if not F then return end

local TEMPLATE = "EvergreenFarmRoutePinTemplate"
local DOT = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"   -- a white disc
local C = {
  line = { 1.00, 0.86, 0.40, 0.90 }, lineDone = { 0.75, 0.72, 0.62, 0.45 }, edge = { 0, 0, 0, 0.85 },
  Ore = { 0.95, 0.58, 0.22 }, Herbs = { 0.42, 0.90, 0.32 }, Leather = { 0.90, 0.32, 0.25 },
  path = { 0.96, 0.93, 0.78 }, next = { 0.25, 1.00, 0.45 },
}
local M = {}
F.Map = M

-- ------------------------------------------------------------------ route geometry on a map
-- Route point i as a fraction (0..1) of map `mapID`, or nil when the route is not on that map.
local rectCache = {}
function M.Transform(r, mapID)
  if not r or not mapID then return nil end
  if mapID == r.map then return 0, 1, 0, 1 end
  local key = r.map .. ":" .. mapID
  local rect = rectCache[key]
  if rect == nil then
    rect = false
    if C_Map and C_Map.GetMapRectOnMap then
      local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, r.map, mapID)
      if ok and minX and maxX and maxX > minX and maxY > minY then rect = { minX, maxX - minX, minY, maxY - minY } end
    end
    rectCache[key] = rect
  end
  if not rect then return nil end
  return rect[1], rect[2], rect[3], rect[4]
end

-- pool helpers: parent:CreateTexture / CreateLine / CreateFontString, reused across redraws
local function Pool(parent, kind, layer, sub)
  return { parent = parent, kind = kind, layer = layer, sub = sub, items = {}, used = 0 }
end
local function Get(pool)
  pool.used = pool.used + 1
  local it = pool.items[pool.used]
  if not it then
    if pool.kind == "line" then it = pool.parent:CreateLine(nil, pool.layer, nil, pool.sub)
    elseif pool.kind == "text" then it = ns.Skin.Text(pool.parent, "GameFontHighlightSmall", "CENTER", pool.layer)
    else it = pool.parent:CreateTexture(nil, pool.layer, nil, pool.sub) end
    pool.items[pool.used] = it
  end
  it:Show()
  return it
end
local function Reset(pool) for i = 1, #pool.items do pool.items[i]:Hide() end; pool.used = 0 end

-- Draw route r into `layer` (a frame w x h, in screen-sized units), as seen on map mapID.
-- big = on the route's own map (bigger dots, numbers); small = on a containing map.
function M.Draw(layer, r, index, mapID, w, h)
  layer.lines = layer.lines or Pool(layer, "line", "ARTWORK", 1)
  layer.dots = layer.dots or Pool(layer, "tex", "OVERLAY", 1)
  layer.edges = layer.edges or Pool(layer, "tex", "OVERLAY", 0)
  layer.labels = layer.labels or Pool(layer, "text", "OVERLAY")
  Reset(layer.lines); Reset(layer.dots); Reset(layer.edges); Reset(layer.labels)
  local x0, sx, y0, sy = M.Transform(r, mapID)
  if not x0 then return 0 end
  local own = mapID == r.map
  local n = #r.points
  local pts = {}
  for i, p in ipairs(r.points) do
    pts[i] = { (x0 + p[1] / 100 * sx) * w, (y0 + p[2] / 100 * sy) * h }
  end
  -- lines, the stretch already walked this lap dimmer
  local thick = own and 3 or 2
  local last = r.loop and n or n - 1
  for i = 1, last do
    local a, b = pts[i], pts[i % n + 1]
    local ln = Get(layer.lines)
    ln:SetThickness(thick)
    local col = (index and i < index) and C.lineDone or C.line
    ln:SetColorTexture(col[1], col[2], col[3], col[4])
    ln:SetStartPoint("TOPLEFT", layer, a[1], -a[2])
    ln:SetEndPoint("TOPLEFT", layer, b[1], -b[2])
  end
  -- points
  local step = math.max(1, math.ceil(n / (own and 30 or 10)))
  for i, q in ipairs(pts) do
    local p = r.points[i]
    local isNext = (i == index)
    local size = isNext and (own and 16 or 11) or (p[3] and (own and 9 or 5)) or (own and 6 or 4)
    local col = isNext and C.next or (p[3] and C[r.category]) or (p[4] and C.Leather) or C.path
    local e = Get(layer.edges)
    e:SetTexture(DOT); e:SetVertexColor(C.edge[1], C.edge[2], C.edge[3], C.edge[4])
    e:SetSize(size + 3, size + 3); e:ClearAllPoints(); e:SetPoint("CENTER", layer, "TOPLEFT", q[1], -q[2])
    local d = Get(layer.dots)
    d:SetTexture(DOT); d:SetVertexColor(col[1], col[2], col[3], 1)
    d:SetSize(size, size); d:ClearAllPoints(); d:SetPoint("CENTER", layer, "TOPLEFT", q[1], -q[2])
    if own and (i == 1 or isNext or i % step == 0) then
      local t = Get(layer.labels)
      t:SetText((isNext and ns.Skin.HEX.green or ns.Skin.HEX.gold) .. i .. "|r")
      t:ClearAllPoints(); t:SetPoint("BOTTOM", layer, "TOPLEFT", q[1], -q[2] + size / 2 + 1)
    end
  end
  return n
end

-- ------------------------------------------------------------------ world map pin
-- The template's mixin; the MapCanvasPinMixin basics are copied in when the map is there.
EvergreenFarmRoutePinMixin = EvergreenFarmRoutePinMixin or {}
local Pin = EvergreenFarmRoutePinMixin

function Pin:SetPassThroughButtons() end          -- blocked for addon code on Forever; a mouse-less pin needs none
function Pin:CheckMouseButtonPassthrough() end
function Pin:OnLoad()
  self:EnableMouse(false)
  if self.SetIgnoreGlobalPinScale then self:SetIgnoreGlobalPinScale(true) end
  if self.UseFrameLevelType then self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI") end
  self.layer = CreateFrame("Frame", nil, self)
  self.layer:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
end
function Pin:OnAcquired(provider)
  self.provider = provider
  self:Layout()
end
function Pin:OnReleased()
  if MapCanvasPinMixin and MapCanvasPinMixin.OnReleased then MapCanvasPinMixin.OnReleased(self) end
  self.provider = nil
end
function Pin:OnCanvasScaleChanged() self:Layout() end
function Pin:OnCanvasSizeChanged() self:Layout() end
function Pin:Layout()
  local map = self:GetMap()
  if not map then return end
  local canvas = map:GetCanvas()
  local w, h = canvas:GetSize()
  if not w or w <= 0 then return end
  self:SetSize(w, h)
  self:SetPosition(0.5, 0.5)
  -- the layer counters the canvas zoom so lines and dots keep their size on screen
  local scale = map:GetCanvasScale() or 1
  if scale <= 0 then scale = 1 end
  self.layer:SetScale(1 / scale)
  self.layer:SetSize(w * scale, h * scale)
  local r, i = F.Active()
  self.drawn = r and M.Draw(self.layer, r, i, map:GetMapID(), w * scale, h * scale) or 0
end

-- the data provider
local Provider = {}
M.provider = Provider
function Provider:Shows(mapID)
  local r = F.Active()
  return r and F.db and F.db.worldmap and M.Transform(r, mapID) ~= nil
end
function Provider:RemoveAllData()
  local map = self:GetMap()
  if map then map:RemoveAllPinsByTemplate(TEMPLATE) end
  self.pin = nil
end
function Provider:RefreshAllData()
  self:RemoveAllData()
  local map = self:GetMap()
  if map and self:Shows(map:GetMapID()) then self.pin = map:AcquirePin(TEMPLATE, self) end
end
function Provider:OnMapChanged() self:RefreshAllData() end

local hooked
function M.HookWorldMap()
  if hooked then return true end
  local wm = WorldMapFrame
  if not (wm and wm.AddDataProvider and MapCanvasDataProviderMixin and MapCanvasPinMixin) then return false end
  hooked = true
  for k, v in pairs(MapCanvasPinMixin) do if Pin[k] == nil then Pin[k] = v end end
  for k, v in pairs(MapCanvasDataProviderMixin) do if Provider[k] == nil then Provider[k] = v end end
  wm:AddDataProvider(Provider)
  return true
end

-- route picked / stopped / options: rebuild the pin; next point: redraw it
function M.RefreshWorldMap(what)
  if not hooked then return end
  local map = Provider:GetMap()
  if not map or not map:IsShown() then return end
  if what == "index" and Provider.pin then Provider.pin:Layout() else Provider:RefreshAllData() end
end

-- ------------------------------------------------------------------ minimap
-- Yards across the minimap: C_Minimap.GetViewRadius on modern clients, else per zoom level
-- (outdoors / indoors) as HereBeDragons-Pins has them.
M.MINIMAP_YARDS = {
  outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 6, 200, 133 + 1 / 3 },
  indoor = { [0] = 300, 240, 180, 120, 80, 50 },
}

function M.MinimapYards()
  if C_Minimap and C_Minimap.GetViewRadius then
    local ok, r = pcall(C_Minimap.GetViewRadius)
    if ok and r and r > 0 then return r * 2 end
  end
  local zoom = Minimap.GetZoom and Minimap:GetZoom() or 0
  local t = (IsIndoors and IsIndoors()) and M.MINIMAP_YARDS.indoor or M.MINIMAP_YARDS.outdoor
  return t[zoom] or t[0]
end

local mm
local function BuildMinimap()
  if mm or not Minimap then return mm end
  mm = CreateFrame("Frame", nil, Minimap)
  mm:SetAllPoints(Minimap)
  mm:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 4)
  mm:EnableMouse(false)
  mm.lines = Pool(mm, "line", "ARTWORK", 1)
  mm.dots = Pool(mm, "tex", "OVERLAY", 1)
  mm.edges = Pool(mm, "tex", "OVERLAY", 0)
  M.minimapLayer = mm
  return mm
end

-- place point i on the minimap: x, y (pixels from the centre), inside (bool), or nil
local function MinimapPoint(r, i, pc, pwx, pwy, ppy, rot)
  local w = F.PointWorld(r, i)
  if not w or w[1] ~= pc then return nil end
  local e, n = -(w[3] - pwy), w[2] - pwx           -- yards east, north
  if rot then
    local c, s = math.cos(rot), math.sin(rot)
    e, n = e * c + n * s, -e * s + n * c
  end
  return e * ppy, n * ppy
end

function M.UpdateMinimap()
  local layer = BuildMinimap()
  if not layer then return end
  Reset(layer.lines); Reset(layer.dots); Reset(layer.edges)
  M.minimapShown = 0
  local r, index = F.Active()
  if not r or not (F.db and F.db.minimap) or not Minimap:IsVisible() then return end
  local pm, px, py = F.PlayerPos()
  if not pm then return end
  local pc, pwx, pwy = F.WorldPos(pm, px, py)
  if not pc then return end
  local size = Minimap:GetWidth()
  if not size or size <= 0 then return end
  local radius = size / 2 - 3
  local ppy = size / M.MinimapYards()
  local rotating = GetCVar and GetCVar("rotateMinimap") == "1"
  if rotating and C_Minimap and C_Minimap.IsRotateMinimapIgnored and C_Minimap.IsRotateMinimapIgnored() then rotating = false end
  local rot = (rotating and GetPlayerFacing) and GetPlayerFacing() or nil
  local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
  local function inside(x, y)
    if square then return math.abs(x) <= radius and math.abs(y) <= radius end
    return x * x + y * y <= radius * radius
  end
  local n = #r.points
  local pos = {}
  for i = 1, n do
    local x, y = MinimapPoint(r, i, pc, pwx, pwy, ppy, rot)
    if x and math.abs(x) < size * 2 and math.abs(y) < size * 2 then pos[i] = { x, y, inside(x, y) } end
  end
  local last = r.loop and n or n - 1
  for i = 1, last do
    local a, b = pos[i], pos[i % n + 1]
    if a and b and a[3] and b[3] then
      local ln = Get(layer.lines)
      ln:SetThickness(2)
      ln:SetColorTexture(C.line[1], C.line[2], C.line[3], 0.75)
      ln:SetStartPoint("CENTER", layer, a[1], a[2])
      ln:SetEndPoint("CENTER", layer, b[1], b[2])
    end
  end
  for i = 1, n do
    local q = pos[i]
    local isNext = i == index
    if q and (q[3] or isNext) then
      local x, y = q[1], q[2]
      if not q[3] then   -- the next point beyond the rim: on the rim
        local d = math.sqrt(x * x + y * y)
        if square then d = math.max(math.abs(x), math.abs(y)) end
        x, y = x * radius / d, y * radius / d
      end
      local p = r.points[i]
      local s = isNext and 10 or (p[3] and 6 or 4)
      local col = isNext and C.next or (p[3] and C[r.category]) or C.path
      local e = Get(layer.edges)
      e:SetTexture(DOT); e:SetVertexColor(0, 0, 0, 0.8); e:SetSize(s + 2, s + 2)
      e:ClearAllPoints(); e:SetPoint("CENTER", layer, "CENTER", x, y)
      local dt = Get(layer.dots)
      dt:SetTexture(DOT); dt:SetVertexColor(col[1], col[2], col[3], q[3] and 1 or 0.7); dt:SetSize(s, s)
      dt:ClearAllPoints(); dt:SetPoint("CENTER", layer, "CENTER", x, y)
      M.minimapShown = M.minimapShown + 1
      if isNext then M.minimapNext = { x, y, q[3] } end
    end
  end
end

-- ------------------------------------------------------------------ wiring
local acc = 0
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, e)
  acc = acc + e
  if acc < 0.08 then return end
  acc = 0
  if F.Active() or (M.minimapLayer and M.minimapShown and M.minimapShown > 0) then M.UpdateMinimap() end
end)

F.On(function(what)
  if what == "route" or what == "options" or what == "index" then
    M.RefreshWorldMap(what)
    M.UpdateMinimap()
  elseif what == "login" then
    M.HookWorldMap()
  end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, _, name)
  if name == "Blizzard_WorldMap" and ns.Farm and M.HookWorldMap() then self:UnregisterAllEvents() end
end)
