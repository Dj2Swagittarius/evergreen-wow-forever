-- Everblock UI: the list window and /block.
local _, ns = ...
local C = ns.Core
local Say = ns.Say
local Skin = ns.Skin

local ROWS = 12
local ROW_H = 20
local win, rows, input, statsText, scrollOffset = nil, {}, nil, nil, 0

-- One list of guilds then hand-blocked players.
local function entries()
  local out = {}
  for _, g in ipairs(C.SortedGuilds(ns.db)) do
    out[#out + 1] = { kind = "guild", name = g.name, text = ("<%s>  |cffa39e93%d known member%s|r"):format(g.name, g.members, g.members == 1 and "" or "s") }
  end
  for _, p in ipairs(C.SortedPlayers(ns.db)) do
    out[#out + 1] = { kind = "player", name = p, text = p .. "  |cffa39e93player|r" }
  end
  return out
end

function ns.Refresh()
  if not win or not win:IsShown() then return end
  local list = entries()
  scrollOffset = math.max(0, math.min(scrollOffset, #list - ROWS))
  for i, row in ipairs(rows) do
    local e = list[i + scrollOffset]
    row.entry = e
    row:SetShown(e ~= nil)
    if e then row.Text:SetText(e.text) end
  end
  win.Empty:SetShown(#list == 0)
  statsText:SetText(C.StatsText(ns.db) .. (ns.db.enabled and "" or "  |cffff5555(paused)|r"))
  win.Pause:SetText(ns.db.enabled and "Pause" or "Resume")
  win.Dim:SetChecked(ns.db.dim)
end

local function button(parent, label, width, onClick)
  return Skin.Button(parent, label, width, 22, onClick)
end

local function addFromInput()
  local text = input:GetText()
  local k, isNew = C.AddGuild(ns.db, text)
  if k then
    Say(("blocking guild <%s>%s."):format(ns.db.guilds[k], isNew and "" or " (already listed)"))
    ns.RefreshPlates()
  end
  input:SetText("")
  input:ClearFocus()
  ns.Refresh()
end

local function buildWindow()
  win = Skin.Window("EverblockFrame", 380, 470, "Everblock", "Interface\\Icons\\INV_Shield_05")

  local sub = Skin.Text(win, "GameFontHighlightSmall", "Hides chat, trades, invites and duels\nfrom everyone in the guilds you list.")
  sub:SetPoint("TOPLEFT", win.portraitW + 12, win.top - 8)

  input = Skin.Edit(win, 210, 20)
  input:SetPoint("TOPLEFT", 22, win.top - 48)
  input:SetScript("OnEnterPressed", addFromInput)
  local add = button(win, "Block guild", 120, addFromInput)
  add:SetPoint("LEFT", input, "RIGHT", 8, 0)

  -- the list, in a recessed inset like the quest log
  local inset = Skin.Inset(win)
  inset:SetPoint("TOPLEFT", 12, win.top - 74)
  inset:SetPoint("BOTTOMRIGHT", -12, 96)
  for i = 1, ROWS do
    local row = CreateFrame("Frame", nil, inset)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * ROW_H)
    row:SetPoint("RIGHT", inset, "RIGHT", -4, 0)
    Skin.RowHighlight(row)
    row:EnableMouse(true)
    row.Text = Skin.Text(row, "GameFontHighlight")
    row.Text:SetPoint("LEFT", 6, 0)
    row.Text:SetPoint("RIGHT", -64, 0)
    local rm = Skin.Button(row, "Remove", 60, 18, function()
      local e = row.entry
      if not e then return end
      if e.kind == "guild" then
        local name, n = C.RemoveGuild(ns.db, e.name)
        if name then Say(("unblocked <%s> (forgot %d member%s)."):format(name, n, n == 1 and "" or "s")) end
      else
        C.RemovePlayer(ns.db, e.name)
        Say("unblocked " .. e.name .. ".")
      end
      ns.RefreshPlates()
      ns.Refresh()
    end)
    rm:SetPoint("RIGHT", 0, 0)
    rows[i] = row
  end
  win:EnableMouseWheel(true)
  win:SetScript("OnMouseWheel", function(_, delta) scrollOffset = scrollOffset - delta; ns.Refresh() end)

  win.Empty = Skin.Text(inset, "GameFontDisable", "No guilds blocked. Type a guild name above,\nor target someone and /block target.")
  win.Empty:SetPoint("TOPLEFT", 10, -10)

  statsText = Skin.Text(win, "GameFontHighlightSmall")
  statsText:SetPoint("BOTTOMLEFT", 16, 72)
  statsText:SetPoint("RIGHT", -16, 0)

  win.Dim = Skin.Check(win, "Dim their nameplates", function(self) ns.db.dim = self:GetChecked() and true or false; ns.RefreshPlates() end)
  win.Dim:SetPoint("BOTTOMLEFT", 12, 42)

  local scan = button(win, "Scan /who", 100, function() ns.ScanNext() end)
  scan:SetPoint("BOTTOMLEFT", 14, 14)
  local tgt = button(win, "Block target", 110, function() SlashCmdList.EVERBLOCK("target") end)
  tgt:SetPoint("LEFT", scan, "RIGHT", 4, 0)
  win.Pause = button(win, "Pause", 80, function()
    ns.db.enabled = not ns.db.enabled
    Say(ns.db.enabled and "blocking resumed." or "blocking paused.")
    ns.RefreshPlates()
    ns.Refresh()
  end)
  win.Pause:SetPoint("LEFT", tgt, "RIGHT", 4, 0)

  win:SetScript("OnShow", ns.Refresh)
end

local function toggle()
  if not win then buildWindow() end
  win:SetShown(not win:IsShown())
  ns.Refresh()
end

local HELP = {
  "/block - open the list",
  "/block guild <name> - block a guild (also /block unguild <name>)",
  "/block target - block your target's guild (or the player if guildless)",
  "/block add <player> / /block remove <player> - block one player by name",
  "/block scan - look up members of blocked guilds with /who (one guild per use)",
  "/block members <guild> - list known members",
  "/block pause - pause/resume  |  /block quiet - hide 'declined' messages  |  /block learn - announce learned members",
}

SLASH_EVERBLOCK1, SLASH_EVERBLOCK2 = "/block", "/everblock"
SlashCmdList.EVERBLOCK = function(msg)
  local db = ns.db
  if not db then return end
  msg = (msg or ""):match("^%s*(.-)%s*$")
  local cmd, arg = msg:match("^(%S+)%s*(.*)$")
  cmd = (cmd or ""):lower()
  if cmd == "" then toggle()
  elseif cmd == "guild" and arg ~= "" then
    local k, isNew = C.AddGuild(db, arg)
    Say(("blocking guild <%s>%s."):format(db.guilds[k], isNew and "" or " (already listed)"))
    ns.RefreshPlates(); ns.Refresh()
  elseif cmd == "unguild" and arg ~= "" then
    local name, n = C.RemoveGuild(db, arg)
    Say(name and ("unblocked <%s> (forgot %d member%s)."):format(name, n, n == 1 and "" or "s") or ("<" .. arg .. "> isn't blocked."))
    ns.RefreshPlates(); ns.Refresh()
  elseif cmd == "target" then
    if not UnitExists("target") or not UnitIsPlayer("target") or UnitIsUnit("target", "player") then Say("target another player first."); return end
    local guild = GetGuildInfo("target")
    local name = UnitName("target")
    if guild then
      C.AddGuild(db, guild)
      C.Learn(db, name, guild, time())
      Say(("blocking guild <%s>."):format(guild))
    else
      C.AddPlayer(db, name)
      Say(("%s has no guild; blocking the player."):format(name))
    end
    ns.RefreshPlates(); ns.Refresh()
  elseif cmd == "add" and arg ~= "" then
    C.AddPlayer(db, arg); Say("blocking player " .. arg .. "."); ns.RefreshPlates(); ns.Refresh()
  elseif cmd == "remove" and arg ~= "" then
    Say(C.RemovePlayer(db, arg) and ("unblocked " .. arg .. ".") or (arg .. " isn't blocked."))
    ns.RefreshPlates(); ns.Refresh()
  elseif cmd == "scan" then ns.ScanNext()
  elseif cmd == "members" then
    local g = arg ~= "" and arg or (C.SortedGuilds(db)[1] or {}).name
    if not g or not C.IsGuildBlocked(db, g) then Say("usage: /block members <blocked guild>"); return end
    local list = C.MembersOf(db, g)
    Say(("<%s>: %d known - %s"):format(db.guilds[C.GuildKey(g)], #list, #list > 0 and table.concat(list, ", ") or "none yet"))
  elseif cmd == "pause" then
    db.enabled = not db.enabled
    Say(db.enabled and "blocking resumed." or "blocking paused.")
    ns.RefreshPlates(); ns.Refresh()
  elseif cmd == "quiet" then
    db.quiet = not db.quiet; Say(db.quiet and "declines are silent now." or "declines are announced again.")
  elseif cmd == "learn" then
    db.announce = not db.announce; Say(db.announce and "announcing learned members." or "learning quietly.")
  elseif cmd == "stats" then Say(C.StatsText(db))
  else
    for _, l in ipairs(HELP) do Say(l) end
  end
end
