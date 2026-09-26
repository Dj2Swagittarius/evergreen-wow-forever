-- Evergreen module registry. Loaded first (see Evergreen.toc).
--
-- Evergreen is one addon made of modules: the leveling guide, Everbuff (buff button),
-- EverMove (window mover) and Reveal (world map fog removal). Each module checks
-- ns.ModuleEnabled(id) when the addon loads and stays dormant when switched off, so
-- turning one on or off takes effect after a /reload. Settings: EvergreenDB.modules.

local ADDON, ns = ...

local HEX = { green = "|cff7fd35e", muted = "|cff8f958a", red = "|cffe08a7a", ink = "|cffd9dccf" }

ns.MODULES = {
  { id = "guide",  name = "Guide",  slash = "/eg",    desc = "Leveling route, waypoint arrow, quest tracking" },
  { id = "buffs",  name = "Buffs",  slash = "/eb",    desc = "Scans nearby players for missing buffs; one button casts the next" },
  { id = "move",   name = "Move",   slash = "/emove", desc = "Drag the map, character sheet, bags and other windows anywhere" },
  { id = "reveal", name = "Reveal", slash = "/eg reveal", desc = "Shows unexplored areas on the world map (WoW Forever map data)" },
  { id = "journal", name = "Journal", slash = "/ej", desc = "Dungeon journal: bosses, loot, dungeon quests, entrances, map markers" },
}

local byId = {}
for _, m in ipairs(ns.MODULES) do byId[m.id] = m end

function ns.ModuleEnabled(id)
  local db = EvergreenDB and EvergreenDB.modules
  if db and db[id] ~= nil then return db[id] end
  return true   -- every module is on unless switched off
end

local function listModules()
  print(HEX.green .. "Evergreen modules:|r")
  for _, m in ipairs(ns.MODULES) do
    local on = ns.ModuleEnabled(m.id)
    print(string.format("  %s%-6s|r %s  %s%s|r  %s", on and HEX.green or HEX.red, on and "on" or "off",
      m.id, HEX.muted, m.slash, m.desc))
  end
  print(HEX.muted .. "  /eg module <id> on|off, then /reload.|r")
end

local function setModule(id, state)
  local m = byId[id or ""]
  if not m then print(HEX.red .. "Evergreen:|r no module '" .. tostring(id) .. "'."); listModules(); return end
  local on
  if state == "on" then on = true elseif state == "off" then on = false else on = not ns.ModuleEnabled(id) end
  EvergreenDB.modules[id] = on
  print(HEX.green .. "Evergreen:|r " .. m.name .. " module " .. (on and "on" or "off") .. ". " .. HEX.ink .. "/reload|r to apply.")
end

-- Wrap the guide's /eg handler so module commands work even when the guide is off.
local function wrapSlash()
  local guide = SlashCmdList["EVERGREEN"]
  SlashCmdList["EVERGREEN"] = function(msg)
    local m = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = m:match("^(%S+)%s*(.*)$")
    if cmd == "modules" then
      listModules()
    elseif cmd == "module" then
      local id, state = rest:match("^(%S+)%s*(%S*)$")
      setModule(id, state)
    elseif cmd == "journal" or cmd == "ej" then
      if SlashCmdList.EVERGREENJOURNAL then SlashCmdList.EVERGREENJOURNAL(rest) end
    elseif cmd == "reveal" then
      if ns.Reveal then ns.Reveal.Slash(rest) else print(HEX.green .. "Evergreen:|r Reveal module is off. /eg module reveal on, then /reload.") end
    elseif not ns.ModuleEnabled("guide") then
      print(HEX.green .. "Evergreen:|r guide module is off. /eg modules lists modules; /eg module guide on, then /reload.")
    else
      guide(msg)
      if m == "help" or m == "?" then
        print(HEX.green .. "Modules|r: /eg modules, /eg module <id> on|off, /eg reveal, /ej, /eb, /emove")
      end
    end
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, _, name)
  if name ~= ADDON then return end
  self:UnregisterEvent("ADDON_LOADED")
  EvergreenDB = EvergreenDB or {}
  EvergreenDB.modules = EvergreenDB.modules or {}
  wrapSlash()
end)
