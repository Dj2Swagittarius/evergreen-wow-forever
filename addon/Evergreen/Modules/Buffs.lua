-- Buffs module (formerly the Everbuff addon): scan nearby friendlies for missing buffs, one secure button casts the next one per click.
--
-- How it works (and why it is built this way): addons cannot cast spells on their own. A secure
-- action button can cast exactly one spell per hardware click, and its target/spell may only be
-- changed out of combat. So Everbuff keeps a list of "who is missing what", writes the first entry
-- into the button's macro, and re-arms after every cast. Click until it reads "all buffed".

local ADDON, ns = ...
local EB = CreateFrame("Frame", "EverbuffEvents")

BINDING_HEADER_EVERBUFF = "Everbuff"
_G["BINDING_NAME_CLICK EverbuffButton:LeftButton"] = "Cast next buff"

local HEX = { ink="|cffe8e4d8", muted="|cffa39e93", green="|cff7fd35e", gold="|cffffd100", red="|cffff4040", white="|cffffffff" }
local C = {
  bg={0.06,0.05,0.04,0.9}, panel={0.08,0.065,0.05,0.9}, line={0.45,0.37,0.24,1},
  ink={0.85,0.86,0.81}, muted={0.56,0.58,0.54}, green={1,0.82,0}, gold={1,0.82,0}, red={0.88,0.54,0.48},
}
local FONT_DISPLAY = "Fonts\\MORPHEUS.ttf"
local FONT_BODY = "Fonts\\FRIZQT__.TTF"
local FONT_NUM = "Fonts\\ARIALN.TTF"

-- ------------------------------------------------------------------ buff definitions
-- Each entry: spell = what to cast; satisfiedBy = any of these auras on the unit counts as buffed.
-- classes = which target classes want it (nil = everyone). self = true when it is a self-only / no-target cast.
local CASTER = { PRIEST=true, MAGE=true, WARLOCK=true, DRUID=true, SHAMAN=true, PALADIN=true }
local MELEE  = { WARRIOR=true, ROGUE=true, HUNTER=true }

local BUFFS = {
  PRIEST = {
    { spell="Power Word: Fortitude", satisfiedBy={"Power Word: Fortitude", "Prayer of Fortitude"} },
    { spell="Divine Spirit", satisfiedBy={"Divine Spirit", "Prayer of Spirit"}, classes=CASTER },
    { spell="Shadow Protection", satisfiedBy={"Shadow Protection", "Prayer of Shadow Protection"}, optional=true },
    { spell="Inner Fire", satisfiedBy={"Inner Fire"}, self=true },
  },
  MAGE = {
    { spell="Arcane Intellect", satisfiedBy={"Arcane Intellect", "Arcane Brilliance"}, classes=CASTER },
    { spell="Frost Armor", satisfiedBy={"Frost Armor", "Ice Armor", "Mage Armor"}, self=true, upgrades={"Mage Armor", "Ice Armor"} },
  },
  DRUID = {
    { spell="Mark of the Wild", satisfiedBy={"Mark of the Wild", "Gift of the Wild"} },
    { spell="Thorns", satisfiedBy={"Thorns"}, classes=MELEE, optional=true },
  },
  PALADIN = {
    { spell="Blessing of Might", satisfiedBy={"Blessing of Might", "Greater Blessing of Might", "Blessing of Kings", "Greater Blessing of Kings", "Blessing of Salvation", "Greater Blessing of Salvation"}, classes=MELEE },
    { spell="Blessing of Wisdom", satisfiedBy={"Blessing of Wisdom", "Greater Blessing of Wisdom", "Blessing of Kings", "Greater Blessing of Kings", "Blessing of Salvation", "Greater Blessing of Salvation"}, classes=CASTER },
  },
  WARRIOR = {
    { spell="Battle Shout", satisfiedBy={"Battle Shout"}, self=true },
  },
  -- classes with no buff to put on other people still get their own self-buff tracked
  HUNTER = {
    { spell="Aspect of the Hawk", satisfiedBy={"Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Cheetah", "Aspect of the Pack", "Aspect of the Beast", "Aspect of the Wild", "Aspect of the Viper", "Aspect of the Falcon"}, self=true, upgrades={"Aspect of the Hawk", "Aspect of the Monkey"} },
  },
  SHAMAN = {
    { spell="Lightning Shield", satisfiedBy={"Lightning Shield", "Water Shield", "Earth Shield"}, self=true },
  },
  WARLOCK = {
    { spell="Demon Skin", satisfiedBy={"Demon Skin", "Demon Armor", "Fel Armor"}, self=true, upgrades={"Demon Armor"} },
  },
}

-- ------------------------------------------------------------------ helpers
local DB
local function InitDB()
  EverbuffDB = EverbuffDB or {}
  DB = EverbuffDB
  if DB.optional == nil then DB.optional = false end
  if DB.nameplates == nil then DB.nameplates = true end
  if DB.locked == nil then DB.locked = false end
end

-- Is this spell in the character's spellbook? Clients disagree on which API answers that
-- (the 1.60 Forever client, Era 1.15 and retail each expose a different set), so every
-- known method is tried and the first definite "yes" wins. A method that errors or is
-- missing is skipped, never treated as "no". If no method at all could answer, the spell
-- is assumed known: a failed cast is a visible error, a silently empty queue is not.
local function SpellKnown(name)
  local answered = false
  local function try(f)
    local ok, r = pcall(f)
    if ok and r ~= nil then answered = true; return r == true end
    return false
  end
  -- 1. modern spellbook lookup by name
  if try(function()
    if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
      local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
      if bank ~= nil then return C_SpellBook.IsSpellInSpellBook(name, bank) == true end
      return C_SpellBook.IsSpellInSpellBook(name) == true
    end
    return nil
  end) then return true end
  -- 2. resolve to an id, then ask whether the player owns that id
  if try(function()
    if not (C_Spell and C_Spell.GetSpellInfo) then return nil end
    local info = C_Spell.GetSpellInfo(name)
    if not info or not info.spellID then return false end
    if IsPlayerSpell and IsPlayerSpell(info.spellID) then return true end
    if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(info.spellID) then return true end
    if IsSpellKnown and IsSpellKnown(info.spellID) then return true end
    -- name lookups only resolve for spells in the book on most clients, so an id with
    -- no owner check available still counts
    if not IsPlayerSpell and not IsSpellKnown then return true end
    return false
  end) then return true end
  -- 3. classic-style: GetSpellInfo(name) returns nil for spells not in the book
  if try(function()
    if type(GetSpellInfo) ~= "function" then return nil end
    return GetSpellInfo(name) ~= nil
  end) then return true end
  -- 4. walk the spellbook tabs by name (classic API)
  if try(function()
    if type(GetNumSpellTabs) ~= "function" or type(GetSpellBookItemName) ~= "function" then return nil end
    local bank = BOOKTYPE_SPELL or "spell"
    for tab = 1, GetNumSpellTabs() do
      local _, _, offset, num = GetSpellTabInfo(tab)
      for i = offset + 1, offset + num do
        if GetSpellBookItemName(i, bank) == name then return true end
      end
    end
    return false
  end) then return true end
  return not answered
end

-- A def may list higher-tier replacements (Ice Armor over Frost Armor, ...). Cast the best
-- one the character knows.
local function BestSpell(d)
  if d.upgrades then
    for _, s in ipairs(d.upgrades) do if SpellKnown(s) then return s end end
  end
  return d.spell
end

local function HasAura(unit, names)
  for _, n in ipairs(names) do
    local ok, found = pcall(function()
      if AuraUtil and AuraUtil.FindAuraByName then
        return AuraUtil.FindAuraByName(n, unit) ~= nil
      end
      for i = 1, 40 do
        local name = UnitBuff(unit, i)
        if not name then break end
        if name == n then return true end
      end
      return false
    end)
    if ok and found then return true end
  end
  return false
end

local function InRange(spell, unit)
  local ok, r = pcall(function()
    if C_Spell and C_Spell.IsSpellInRange then
      local res = C_Spell.IsSpellInRange(spell, unit)
      return res == true or res == 1 or res == nil   -- nil = no range info; assume ok
    end
    local res = IsSpellInRange(spell, unit)
    return res == 1 or res == nil
  end)
  return ok and r
end

local function UnitOK(unit)
  if not UnitExists(unit) or not UnitIsPlayer(unit) then return false end
  if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then return false end
  if not UnitIsFriend("player", unit) then return false end
  if UnitCanAttack("player", unit) then return false end
  return true
end

-- candidate unit ids: yourself, group, target, mouseover, friendly nameplates
local seenNames = {}
local function CandidateUnits()
  wipe(seenNames)
  local list = {}
  local function add(u)
    if UnitOK(u) then
      local name = UnitName(u)
      if name and not seenNames[name] then seenNames[name] = true; table.insert(list, u) end
    end
  end
  add("player")
  if IsInRaid() then
    for i = 1, 40 do add("raid" .. i) end
  else
    for i = 1, 4 do add("party" .. i) end
  end
  add("target"); add("mouseover")
  if DB.nameplates then
    for i = 1, 40 do add("nameplate" .. i) end
  end
  return list
end

-- ------------------------------------------------------------------ scan
local playerClass
local queue = {}      -- { {unit=, name=, class=, spell=}, ... }
local known = {}      -- spell -> known?

local function Scan()
  wipe(queue)
  local defs = BUFFS[playerClass]
  if not defs then return end
  -- re-check the spellbook every scan: it is empty for a moment after login on the 1.60
  -- client, and a character trains new buffs as it levels. Caching the first answer left
  -- the queue permanently empty for anyone whose first scan ran too early.
  for _, d in ipairs(defs) do known[d.spell] = SpellKnown(d.spell) end
  local units = CandidateUnits()
  for _, d in ipairs(defs) do
    if known[d.spell] and (not d.optional or DB.optional) then
      local spell = BestSpell(d)
      if d.self then
        if not HasAura("player", d.satisfiedBy) then
          table.insert(queue, { unit="player", name=UnitName("player"), class=playerClass, spell=spell })
        end
      else
        for _, u in ipairs(units) do
          local _, cls = UnitClass(u)
          if (not d.classes or d.classes[cls]) and not HasAura(u, d.satisfiedBy) and (u == "player" or InRange(spell, u)) then
            local name, realm = UnitName(u)
            local full = (realm and realm ~= "") and (name .. "-" .. realm) or name
            table.insert(queue, { unit=u, name=name, fullName=full, class=cls, spell=spell })
          end
        end
      end
    end
  end
end

-- ------------------------------------------------------------------ UI
local frame, button, title, sub, list
local pendingArm

local function ClassColor(cls)
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
  if c then return string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255) end
  return HEX.ink
end

-- Every cast on someone else first TARGETS that person, then casts on the target only:
--   /target party1            (group members, by unit id)
--   /targetexact Name-Realm   (strangers from nameplates, whose slot numbers shift as people move)
--   /cast [@target,help,nodead] Spell
-- The explicit [@target] matters: a bare /cast after a target that did not stick falls back to
-- self-cast, which is how buffs used to land on you. Now a missed target is a visible error
-- instead. The person stays selected afterwards so you can see who got it.
local function MacroFor(q)
  if q.unit == "player" then return "/cast [@player] " .. q.spell end
  local tar
  if q.unit:match("^party%d") or q.unit:match("^raid%d") then
    tar = "/target " .. q.unit
  elseif q.unit ~= "target" then
    tar = "/targetexact " .. (q.fullName or q.name or "")
  end
  return (tar and (tar .. "\n") or "") .. "/cast [@target,help,nodead] " .. q.spell
end

local function Arm()
  -- write the next cast into the secure button; only allowed out of combat
  if InCombatLockdown() then pendingArm = true; return end
  pendingArm = false
  local next = queue[1]
  if next then
    button:SetAttribute("macrotext", MacroFor(next))
    button.label:SetText(HEX.white .. next.spell .. "|r")
    button.who:SetText(ClassColor(next.class) .. (next.name or next.unit) .. "|r")
    button:SetBackdropBorderColor(unpack(C.green))
    button.icon:SetAlpha(1)
    button.hint:SetText("click to cast")
  else
    button:SetAttribute("macrotext", "")
    button.label:SetText(HEX.green .. "All buffed|r")
    button.who:SetText(HEX.muted .. "nobody in range needs anything|r")
    button:SetBackdropBorderColor(unpack(C.line))
    button.icon:SetAlpha(0.35)
    button.hint:SetText("")
  end
  -- spell icon
  local icon
  if next then
    pcall(function()
      if C_Spell and C_Spell.GetSpellTexture then icon = C_Spell.GetSpellTexture(next.spell)
      elseif GetSpellTexture then icon = GetSpellTexture(next.spell) end
    end)
  end
  button.icon:SetTexture(icon or "Interface\\Icons\\Spell_Holy_WordFortitude")
  -- list
  local lines = {}
  local shown = 0
  for i, q in ipairs(queue) do
    if i > 8 then table.insert(lines, HEX.muted .. "+" .. (#queue - 8) .. " more|r"); break end
    table.insert(lines, ClassColor(q.class) .. (q.name or q.unit) .. "|r " .. HEX.muted .. "needs " .. HEX.ink .. q.spell .. "|r")
    shown = shown + 1
  end
  list:SetText(table.concat(lines, "\n"))
  sub:SetText(#queue > 0 and (HEX.gold .. #queue .. "|r " .. HEX.muted .. "cast" .. (#queue == 1 and "" or "s") .. " queued, one per click|r") or "")
  local h = 104 + (#lines > 0 and (#lines * 14 + 10) or 0)
  frame:SetHeight(h)
end

-- Friendly nameplates are how an addon can see players who are not in your group. Turn them on
-- (out of combat) so everyone in nameplate range is scanned, not just the party.
local function EnsureFriendlyPlates()
  if not DB.nameplates or InCombatLockdown() then return end
  pcall(function()
    if GetCVar("nameplateShowFriends") ~= "1" then SetCVar("nameplateShowFriends", "1") end
    -- show plates for friendly players even when they are not in a group
    if GetCVar("nameplateShowFriendlyNPCs") == nil then return end
  end)
end

local function Refresh()
  if not frame then return end
  EnsureFriendlyPlates()
  Scan()
  Arm()
end

local function Backdrop(f, bg, border, edge)
  f:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=edge or 14, insets={left=3,right=3,top=3,bottom=3} })
  f:SetBackdropColor(unpack(bg)); f:SetBackdropBorderColor(unpack(border))
end

local function MakeText(parent, font, size, color, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(font, size, ""); fs:SetTextColor(unpack(color)); fs:SetJustifyH(justify or "LEFT"); fs:SetJustifyV("TOP")
  return fs
end

local function Build()
  -- metal panel from Blizzard's templates (ns.Skin), so it matches the WoW Forever UI
  frame = ns.Skin.Panel("EverbuffFrame", 270, 112, "Everbuff")
  frame:SetParent(UIParent)
  frame:SetPoint("CENTER", UIParent, "CENTER", -300, 200)
  frame:SetFrameStrata("MEDIUM")
  frame:SetMovable(true); frame:EnableMouse(true); frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(s) if not DB.locked then s:StartMoving() end end)
  frame:SetScript("OnDragStop", function(s) s:StopMovingOrSizing(); local p, _, rp, x, y = s:GetPoint(1); DB.pos = { p, rp, x, y } end)
  if DB.pos then frame:ClearAllPoints(); frame:SetPoint(DB.pos[1], UIParent, DB.pos[2], DB.pos[3], DB.pos[4]) end
  if frame.CloseButton then frame.CloseButton:SetScript("OnClick", function() frame:Hide() end) end

  title = ns.Skin.Text(frame, "GameFontNormalSmall"); title:Hide()          -- the frame's own title bar says "Everbuff"
  sub = ns.Skin.Text(frame, "GameFontDisableSmall", "RIGHT"); sub:SetPoint("TOPRIGHT", -12, -30)

  -- the one button. Secure: type=macro, macrotext set by Arm() out of combat.
  button = CreateFrame("Button", "EverbuffButton", frame, "SecureActionButtonTemplate,BackdropTemplate")
  button:SetSize(246, 46)
  button:SetPoint("TOPLEFT", 12, -44)
  -- register both phases; the secure template acts on whichever the client uses (key-down on
  -- modern clients, mouse-up on classic ones), so a plain mouse click always casts
  button:RegisterForClicks("AnyDown", "AnyUp")
  button:SetAttribute("type", "macro")
  button:SetAttribute("macrotext", "")
  Backdrop(button, C.panel, C.line, 12)
  button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(36, 36); button.icon:SetPoint("LEFT", 5, 0)
  local iconFrame = button:CreateTexture(nil, "OVERLAY"); iconFrame:SetTexture("Interface\\Common\\WhiteIconFrame")
  iconFrame:SetAllPoints(button.icon); iconFrame:SetVertexColor(1, 0.82, 0, 1)
  button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
  button.hint = ns.Skin.Text(button, "GameFontDisableSmall", "RIGHT"); button.hint:SetPoint("BOTTOMRIGHT", -8, 5); button.hint:SetText("click to cast")
  button.label = ns.Skin.Text(button, "GameFontNormal"); button.label:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 8, -2); button.label:SetPoint("RIGHT", -8, 0); button.label:SetWordWrap(false)
  button.who = ns.Skin.Text(button, "GameFontHighlightSmall"); button.who:SetPoint("TOPLEFT", button.label, "BOTTOMLEFT", 0, -3); button.who:SetPoint("RIGHT", -8, 0); button.who:SetWordWrap(false)
  button:SetScript("OnEnter", function(s)
    GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Click: target them and cast the buff shown", 1, 1, 1)
    GameTooltip:AddLine("Optional: bind it under Key Bindings > AddOns > Everbuff", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  -- after a click the cast starts; rescan shortly after so the button re-arms with the next one
  button:HookScript("PostClick", function() C_Timer.After(0.6, Refresh); C_Timer.After(2.0, Refresh) end)

  list = ns.Skin.Text(frame, "GameFontHighlightSmall"); list:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 2, -8); list:SetPoint("RIGHT", -12, 0)
  list:SetSpacing(2)

  frame:SetScript("OnMouseUp", function(_, btn) if btn == "RightButton" then frame:Hide() end end)
end

-- ------------------------------------------------------------------ events
local scanTimer
local function QueueScan(delay)
  if scanTimer then return end
  scanTimer = C_Timer.NewTimer(delay or 0.4, function() scanTimer = nil; Refresh() end)
end

for _, ev in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "UNIT_AURA", "PLAYER_TARGET_CHANGED",
  "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED",
  "LEARNED_SPELL_IN_TAB", "PLAYER_LEVEL_UP", "ZONE_CHANGED_NEW_AREA" }) do
  pcall(EB.RegisterEvent, EB, ev)
end

local started = false
local function Start()
  if started then return end
  local _, cls = UnitClass("player")
  if not cls then return end          -- class not readable yet; the next event tries again
  started = true
  playerClass = cls
  if not BUFFS[cls] then
    frame:Hide()
    print(HEX.green .. "Everbuff:|r " .. tostring(cls) .. " has no buff to track. Nothing to do on this character.")
    return
  end
  Refresh()
  if not DB.greeted then DB.greeted = true; print(HEX.green .. "Everbuff|r loaded. /eb to toggle, click the button once per buff.") end
  -- periodic sweep for range changes
  C_Timer.NewTicker(1.5, function() if frame:IsShown() then Refresh() end end)
end

EB:SetScript("OnEvent", function(self, event, a1)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    if not ns.ModuleEnabled("buffs") then self:UnregisterAllEvents(); return end
    InitDB(); Build()
    ns.Skin.MinimapButton("buffs", "Interface\\Icons\\Spell_Holy_WordFortitude", 250,
      function(b)
        if b == "RightButton" then SlashCmdList["EVERBUFF"]("scan") else SlashCmdList["EVERBUFF"]("") end
      end,
      function(tt)
        tt:AddLine("Evergreen: Everbuff", 1, 0.82, 0)
        tt:AddLine(#queue .. " buff" .. (#queue == 1 and "" or "s") .. " queued", 1, 1, 1)
        tt:AddLine("Left-click: show / hide the buff button", 0.9, 0.9, 0.9)
        tt:AddLine("Right-click: rescan and list who needs what", 0.9, 0.9, 0.9)
      end)
  elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    -- the spellbook can still be empty at PLAYER_LOGIN on the 1.60 client; PLAYER_ENTERING_WORLD
    -- fires after it is filled, and Scan re-reads the book every time anyway
    if not frame then return end
    Start()
    if started then QueueScan(1.0) end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pendingArm then Refresh() end
  elseif event == "UNIT_AURA" then
    QueueScan(0.5)
  else
    QueueScan(0.3)
  end
end)

SLASH_EVERBUFF1 = "/eb"
SLASH_EVERBUFF2 = "/everbuff"
SlashCmdList["EVERBUFF"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if not frame then
    print(HEX.green .. "Everbuff:|r Buffs module is off. /eg module buffs on, then /reload.")
  elseif msg == "" then
    if frame:IsShown() then frame:Hide() else frame:Show(); Refresh() end
  elseif msg == "optional" then
    DB.optional = not DB.optional; Refresh()
    print(HEX.green .. "Everbuff:|r optional buffs (Shadow Protection, Thorns) " .. (DB.optional and "on" or "off"))
  elseif msg == "plates" then
    DB.nameplates = not DB.nameplates; Refresh()
    print(HEX.green .. "Everbuff:|r scanning strangers via friendly nameplates " .. (DB.nameplates and "on (nameplates are switched on automatically)" or "off"))
  elseif msg == "lock" then
    DB.locked = not DB.locked; print(HEX.green .. "Everbuff:|r frame " .. (DB.locked and "locked" or "unlocked"))
  elseif msg == "scan" then
    Refresh(); print(HEX.green .. "Everbuff:|r " .. #queue .. " casts queued")
    for _, q in ipairs(queue) do print("  " .. tostring(q.name) .. " needs " .. q.spell) end
  elseif msg == "debug" then
    local plates, players, friendly = 0, 0, 0
    for i = 1, 40 do
      local u = "nameplate" .. i
      if UnitExists(u) then
        plates = plates + 1
        if UnitIsPlayer(u) then players = players + 1 end
        if UnitIsPlayer(u) and UnitIsFriend("player", u) then friendly = friendly + 1 end
      end
    end
    local cv = "?"; pcall(function() cv = GetCVar("nameplateShowFriends") end)
    print(HEX.green .. "Everbuff debug|r  class=" .. tostring(playerClass) .. "  nameplateShowFriends=" .. tostring(cv) .. "  scanPlates=" .. tostring(DB.nameplates))
    print("  nameplates: " .. plates .. " total, " .. players .. " players, " .. friendly .. " friendly players")
    local ks = {}
    for k, v in pairs(known) do table.insert(ks, k .. "=" .. tostring(v)) end
    print("  spells known: " .. table.concat(ks, ", "))
    print("  queue: " .. #queue .. "   macro: " .. tostring(button:GetAttribute("macrotext")):gsub("\n", " | "))
    for i, q in ipairs(queue) do if i <= 6 then print("   " .. i .. ". " .. tostring(q.name) .. " (" .. q.unit .. ") needs " .. q.spell) end end
  elseif msg == "reset" then
    DB.pos = nil; frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", -300, 200)
  else
    print(HEX.green .. "Everbuff|r: /eb, /eb scan, /eb debug, /eb optional, /eb plates, /eb lock, /eb reset")
  end
end
