-- Everpanel plugins: clock, performance, location, bag space.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

local function ServerTime()
  if GetGameTime then
    local h, m = GetGameTime()
    if h then return string.format("%02d:%02d", h, m) end
  end
  return "--:--"
end
local function LocalTime() return date("%H:%M") end

EP.Add{ id = "clock", label = "Clock", side = "right", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", interval = 1,
  text = function() return (EP.db and EP.db.clockServer) and ServerTime() or LocalTime() end,
  tooltip = function(tt)
    tt:AddDoubleLine("Local time", LocalTime(), 0.9, 0.9, 0.9, 1, 1, 1)
    tt:AddDoubleLine("Server time", ServerTime(), 0.9, 0.9, 0.9, 1, 1, 1)
    tt:AddLine("Click: show " .. ((EP.db and EP.db.clockServer) and "local" or "server") .. " time on the bar", 0.6, 0.6, 0.6)
  end,
  onClick = function() if EP.db then EP.db.clockServer = not EP.db.clockServer end end,
}

local function Latency()
  if not GetNetStats then return 0, 0 end
  local _, _, home, world = GetNetStats()
  return home or 0, world or 0
end
EP.Add{ id = "perf", label = "Performance", side = "right", icon = "Interface\\Icons\\Trade_Engineering", interval = 2,
  text = function()
    local fps = (GetFramerate and GetFramerate()) or 0
    local home, world = Latency()
    return string.format("%dfps %dms", math.floor(fps + 0.5), math.max(home, world))
  end,
  tooltip = function(tt)
    local home, world = Latency()
    tt:AddDoubleLine("Home latency", home .. " ms", 0.9, 0.9, 0.9, 1, 1, 1)
    tt:AddDoubleLine("World latency", world .. " ms", 0.9, 0.9, 0.9, 1, 1, 1)
  end,
}

local function Coords()
  local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return nil end
  local x, y = pos:GetXY()
  if not x or (x == 0 and y == 0) then return nil end
  return x * 100, y * 100
end
EP.Add{ id = "location", label = "Location", side = "left", icon = "Interface\\Icons\\INV_Misc_Map_01", interval = 0.5,
  events = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" },
  text = function()
    local zone = (GetZoneText and GetZoneText()) or ""
    local x, y = Coords()
    return x and string.format("%s %.1f, %.1f", zone, x, y) or zone
  end,
  tooltip = function(tt)
    tt:AddLine((GetZoneText and GetZoneText()) or "", 1, 1, 1)
    local sub = GetSubZoneText and GetSubZoneText()
    if sub and sub ~= "" then tt:AddLine(sub, 0.9, 0.9, 0.9) end
    tt:AddLine("Click: world map", 0.6, 0.6, 0.6)
  end,
  onClick = function() if ToggleWorldMap then ToggleWorldMap() end end,
}

local function BagSlots(bag)
  local C = C_Container
  local free = (C and C.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
  local total = (C and C.GetContainerNumSlots) or GetContainerNumSlots
  if not (free and total) then return 0, 0 end
  return free(bag) or 0, total(bag) or 0
end
EP.Add{ id = "bags", label = "Bags", side = "right", icon = "Interface\\Icons\\INV_Misc_Bag_08",
  events = { "BAG_UPDATE", "PLAYER_ENTERING_WORLD" },
  text = function()
    local f, t = 0, 0
    for bag = 0, 4 do local a, b = BagSlots(bag); f, t = f + a, t + b end
    return f .. "/" .. t
  end,
  tooltip = function(tt)
    for bag = 0, 4 do
      local a, b = BagSlots(bag)
      if b > 0 then tt:AddDoubleLine(bag == 0 and "Backpack" or ("Bag " .. bag), a .. " free of " .. b, 0.9, 0.9, 0.9, 1, 1, 1) end
    end
    tt:AddLine("Click: open bags", 0.6, 0.6, 0.6)
  end,
  onClick = function() if ToggleAllBags then ToggleAllBags() end end,
}
