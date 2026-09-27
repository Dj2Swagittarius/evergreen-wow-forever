-- Everpanel plugins: durability (lowest equipped item) and ammo / reagents for classes that use them.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

local SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17, 18 }   -- head .. ranged: the slots that wear down

local function Durability()
  local low, items = nil, {}
  if not GetInventoryItemDurability then return nil, items end
  for _, slot in ipairs(SLOTS) do
    local cur, max = GetInventoryItemDurability(slot)
    if cur and max and max > 0 then
      local p = cur / max * 100
      items[#items + 1] = { slot = slot, pct = p }
      if not low or p < low then low = p end
    end
  end
  return low, items
end

local function PctColor(p) if p < 25 then return 1, 0.25, 0.25 elseif p < 60 then return 1, 0.82, 0 end return 0.25, 0.75, 0.25 end

EP.Add{ id = "durability", label = "Durability", side = "right", icon = "Interface\\Icons\\Trade_BlackSmithing",
  events = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD" },
  text = function() local low = Durability(); return low and (math.floor(low + 0.5) .. "%") or "—" end,
  tooltip = function(tt)
    local _, items = Durability()
    for _, it in ipairs(items) do
      local link = GetInventoryItemLink and GetInventoryItemLink("player", it.slot)
      local r, g, b = PctColor(it.pct)
      tt:AddDoubleLine(link or ("slot " .. it.slot), math.floor(it.pct + 0.5) .. "%", 1, 1, 1, r, g, b)
    end
    tt:AddLine("Click: character sheet", 0.6, 0.6, 0.6)
  end,
  onClick = function() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end,
}

-- what each class carries; ammo counts the equipped ammo slot (0)
local REAGENTS = {
  HUNTER  = { { ammo = true, name = "ammo" } },
  WARLOCK = { { id = 6265, name = "Soul Shards" } },
  MAGE    = { { id = 17020, name = "Arcane Powder" }, { id = 17031, name = "Rune of Teleportation" }, { id = 17032, name = "Rune of Portals" } },
  PRIEST  = { { id = 17028, name = "Holy Candle" }, { id = 17029, name = "Sacred Candle" } },
  PALADIN = { { id = 21177, name = "Symbol of Kings" }, { id = 17033, name = "Symbol of Divinity" } },
  SHAMAN  = { { id = 17030, name = "Ankh" } },
  DRUID   = { { id = 17034, name = "Maple Seed" }, { id = 17026, name = "Wild Thornroot" } },
  ROGUE   = { { id = 5140, name = "Flash Powder" }, { id = 5530, name = "Blinding Powder" } },
}
local function List() local _, cls = UnitClass("player"); return REAGENTS[cls or ""] end
local function Count(r)
  if r.ammo then return (GetInventoryItemCount and GetInventoryItemCount("player", 0)) or 0 end
  local f = (C_Item and C_Item.GetItemCount) or GetItemCount
  return (f and f(r.id)) or 0
end
local function Commas(n) local s = tostring(n); while true do local k; s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2"); if k == 0 then return s end end end

EP.Add{ id = "ammo", label = "Reagents", side = "right", icon = "Interface\\Icons\\INV_Misc_Ammo_Arrow_01",
  events = { "BAG_UPDATE", "UNIT_INVENTORY_CHANGED", "PLAYER_ENTERING_WORLD" },
  visible = function() return List() ~= nil end,
  text = function()
    local l = List()
    if not l then return "" end
    return Commas(Count(l[1])) .. " " .. l[1].name:lower()
  end,
  tooltip = function(tt)
    for _, r in ipairs(List() or {}) do tt:AddDoubleLine(r.name, Commas(Count(r)), 0.9, 0.9, 0.9, 1, 1, 1) end
  end,
}
