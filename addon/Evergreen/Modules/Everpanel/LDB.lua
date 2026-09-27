-- Everpanel: other addons' LibDataBroker plugins (Questie and others publish them). Off by
-- default; "Show other addons' plugins" in the right-click menu turns it on.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

local function Bridge(name, obj)
  local id = "ldb:" .. name
  if EP.byId[id] then return end
  EP.Add{ id = id, label = obj.label or name, side = "right", icon = obj.icon,
    visible = function() return EP.db and EP.db.ldb end,
    text = function() return tostring(obj.text or obj.label or name) end,
    tooltip = obj.OnTooltipShow and function(tt) obj.OnTooltipShow(tt) end or nil,
    onClick = obj.OnClick and function(btn) obj.OnClick(EP.buttons[id], btn) end or nil,
    rightClick = obj.OnClick ~= nil,
  }
end

function EP.ScanLDB()
  local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
  if not ldb then return 0 end
  local n = 0
  for name, obj in ldb:DataObjectIterator() do Bridge(name, obj); n = n + 1 end
  if not EP.ldbHooked then
    EP.ldbHooked = true
    ldb.RegisterCallback(EP, "LibDataBroker_DataObjectCreated", function(_, name, obj) Bridge(name, obj) end)
    ldb.RegisterCallback(EP, "LibDataBroker_AttributeChanged", function(_, name) EP.Update("ldb:" .. name) end)
  end
  return n
end
