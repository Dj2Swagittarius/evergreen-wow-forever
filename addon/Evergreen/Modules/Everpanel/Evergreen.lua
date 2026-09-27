-- Everpanel plugins for Evergreen's own modules: current guide step, Everbuff queue, journal launcher.
local ADDON, ns = ...
local EP = ns.Everpanel
if not EP then return end

EP.Add{ id = "guide", label = "Guide", side = "left", icon = "Interface\\Icons\\INV_Misc_Book_08", interval = 2,
  events = { "QUEST_LOG_UPDATE", "QUEST_TURNED_IN" },
  visible = function() return ns.ModuleEnabled("guide") end,
  text = function()
    local s = (ns.GuideStepText and ns.GuideStepText()) or "route done"
    if #s > 40 then s = s:sub(1, 38) .. "..." end
    return s
  end,
  tooltip = function(tt)
    tt:AddLine((ns.GuideStepText and ns.GuideStepText()) or "route done", 1, 1, 1, true)
    tt:AddLine("Click: guide window", 0.6, 0.6, 0.6)
  end,
  onClick = function() if SlashCmdList.EVERGREEN then SlashCmdList.EVERGREEN("") end end,
}

EP.Add{ id = "everbuff", label = "Everbuff", side = "left", icon = "Interface\\Icons\\Spell_Holy_WordFortitude", interval = 2,
  visible = function() return ns.ModuleEnabled("buffs") and ns.EverbuffInfo ~= nil end,
  text = function()
    if not ns.EverbuffInfo then return "" end
    local n = ns.EverbuffInfo()
    return n .. " buff" .. (n == 1 and "" or "s")
  end,
  tooltip = function(tt)
    local n, queue = 0, {}
    if ns.EverbuffInfo then n, queue = ns.EverbuffInfo() end
    if n == 0 then tt:AddLine("Everyone in range is buffed", 0.6, 0.6, 0.6) end
    for i, q in ipairs(queue) do
      if i > 15 then break end
      tt:AddDoubleLine(q.name or q.unit or "?", q.spell, 1, 1, 1, 0.9, 0.9, 0.9)
    end
    tt:AddLine("Click: buff button", 0.6, 0.6, 0.6)
  end,
  onClick = function() if SlashCmdList.EVERBUFF then SlashCmdList.EVERBUFF("") end end,
}

EP.Add{ id = "journal", label = "Journal", side = "left", icon = "Interface\\Icons\\INV_Misc_Book_09",
  visible = function() return ns.ModuleEnabled("journal") and ns.Journal ~= nil end,
  text = function() return "" end,
  tooltip = function(tt) tt:AddLine("Click: dungeon journal", 0.6, 0.6, 0.6) end,
  onClick = function() if SlashCmdList.EVERGREENJOURNAL then SlashCmdList.EVERGREENJOURNAL("") end end,
}
