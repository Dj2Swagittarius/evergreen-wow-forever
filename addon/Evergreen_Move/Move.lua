-- Move module (formerly the EverMove addon): drag Blizzard windows (map, character sheet, bags, ...) anywhere.
-- Positions are saved per character-independent frame name (bags per bag ID).

local ADDON, ns = ...
local DB

local PREFIX = "|cff7fd35eEverMove|r: "
local function say(msg) DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg) end

-- Windows to make movable. Anything missing in this client is skipped, and
-- load-on-demand windows are picked up when their Blizzard addon loads.
-- Handle = invisible drag strip along the title bar (insets keep it clear of
-- the portrait on the left and the close button on the right).
local PANEL = { l = 60, r = 70, t = -4, h = 24 }
local FRAMES = {
  -- always loaded
  CharacterFrame = PANEL, SpellBookFrame = PANEL, QuestLogFrame = PANEL,
  FriendsFrame = PANEL, GossipFrame = PANEL, QuestFrame = PANEL,
  MerchantFrame = PANEL, BankFrame = PANEL, MailFrame = PANEL,
  OpenMailFrame = PANEL, TradeFrame = PANEL, TaxiFrame = PANEL,
  PetStableFrame = PANEL, DressUpFrame = PANEL, HelpFrame = PANEL,
  LFGParentFrame = PANEL, PVPFrame = PANEL, HonorFrame = PANEL,
  ItemTextFrame = PANEL, TabardFrame = PANEL, GuildRegistrarFrame = PANEL,
  PetitionFrame = PANEL, WorldStateScoreFrame = PANEL,
  WorldMapFrame = { l = 10, r = 70, t = 0, h = 22 },
  ContainerFrameCombinedBags = { l = 45, r = 32, t = -4, h = 20, raise = true },
  -- load on demand
  PlayerTalentFrame = PANEL, TalentFrame = PANEL, AuctionFrame = PANEL,
  AuctionHouseFrame = PANEL, ClassTrainerFrame = PANEL, TradeSkillFrame = PANEL,
  CraftFrame = PANEL, MacroFrame = PANEL, InspectFrame = PANEL,
  KeyBindingFrame = PANEL, TimeManagerFrame = PANEL, CommunitiesFrame = PANEL,
  CollectionsJournal = PANEL, EncounterJournal = PANEL, ProfessionsFrame = PANEL,
  PlayerSpellsFrame = PANEL, SettingsPanel = PANEL,
}
local BAG = { l = 45, r = 32, t = -4, h = 20, raise = true }
local MAX_BAG_FRAMES = 13

local hooked = {}   -- frame -> true once set up
local pending = {}  -- frames to reposition after combat

-- Bag windows are recycled (ContainerFrame1 might hold any bag), so key them
-- by the bag ID they currently show instead of the frame name.
local function key(frame)
  if frame.everMoveBag then return "bag" .. (frame:GetID() or 0) end
  return frame:GetName()
end

local function blocked(frame)
  return InCombatLockdown() and frame:IsProtected()
end

local function apply(frame)
  if not DB or frame.everMoving then return end
  local p = DB.pos[key(frame)]
  if not p then return end
  if blocked(frame) then pending[frame] = true return end
  frame:ClearAllPoints()
  frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

-- Blizzard re-anchors panels right after showing them, so apply once now and
-- once on the next frame to win the race.
local function applySoon(frame)
  apply(frame)
  C_Timer.After(0, function() if frame:IsShown() then apply(frame) end end)
end

local function startDrag(frame)
  if DB.locked or blocked(frame) then return end
  frame.everMoving = true
  frame:StartMoving()
end

local function stopDrag(frame)
  if not frame.everMoving then return end
  frame:StopMovingOrSizing()
  frame.everMoving = nil
  -- Keep Blizzard's layout cache out of it; we restore positions ourselves.
  frame:SetUserPlaced(false)
  local point, _, relPoint, x, y = frame:GetPoint(1)
  if point then DB.pos[key(frame)] = { point, relPoint, x, y } end
end

local function makeHandle(frame, cfg)
  local h = CreateFrame("Frame", nil, frame)
  h:SetPoint("TOPLEFT", frame, "TOPLEFT", cfg.l, cfg.t)
  h:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -cfg.r, cfg.t)
  h:SetHeight(cfg.h)
  -- Bags are packed with item buttons and a portrait button; sit above them.
  if cfg.raise then h:SetFrameLevel(frame:GetFrameLevel() + 20) end
  h:EnableMouse(true)
  h:RegisterForDrag("LeftButton")
  h:SetScript("OnDragStart", function() startDrag(frame) end)
  h:SetScript("OnDragStop", function() stopDrag(frame) end)
  h:SetScript("OnHide", function() stopDrag(frame) end)
end

local function setup(frame, cfg)
  if type(frame) ~= "table" or not frame.SetMovable or hooked[frame] then return end
  if blocked(frame) then return end -- retried when combat ends
  hooked[frame] = true
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  -- Dragging any empty part of the window works too, not just the title strip.
  frame:RegisterForDrag("LeftButton")
  frame:HookScript("OnDragStart", startDrag)
  frame:HookScript("OnDragStop", stopDrag)
  frame:HookScript("OnShow", applySoon)
  frame:HookScript("OnHide", stopDrag)
  makeHandle(frame, cfg)
  if frame:IsShown() then applySoon(frame) end
end

local function setupAll()
  for name, cfg in pairs(FRAMES) do setup(_G[name], cfg) end
  for i = 1, MAX_BAG_FRAMES do
    local f = _G["ContainerFrame" .. i]
    if f then
      f.everMoveBag = true
      setup(f, BAG)
    end
  end
end

local function applyShown()
  for frame in pairs(hooked) do
    if frame:IsShown() then apply(frame) end
  end
end

-- Bag windows can be created and re-anchored when a bag opens, so hook them up
-- (and put saved positions back) every time bags open.
local function onBagsOpened()
  setupAll()
  applyShown()
  C_Timer.After(0, applyShown)
end

local function describe(f)
  if type(f) ~= "table" or not f.GetName then return tostring(f) end
  local point, rel, relPoint, x, y = f:GetPoint(1)
  return string.format("%s shown=%s hooked=%s movable=%s mouse=%s prot=%s id=%s parent=%s at=%s>%s:%s %d,%d",
    f:GetName() or "?", tostring(f:IsShown()), tostring(hooked[f] or false), tostring(f:IsMovable()),
    tostring(f:IsMouseEnabled()), tostring(f:IsProtected()), tostring(f.GetID and f:GetID()),
    f:GetParent() and (f:GetParent():GetName() or "anon") or "nil",
    tostring(point), rel and (rel:GetName() or "anon") or "nil", tostring(relPoint), x or 0, y or 0)
end

local function debugBags()
  say("UpdateContainerFrameAnchors=" .. tostring(UpdateContainerFrameAnchors ~= nil) ..
    " UpdateUIPanelPositions=" .. tostring(UpdateUIPanelPositions ~= nil))
  local foci = GetMouseFoci and GetMouseFoci() or { GetMouseFocus and GetMouseFocus() }
  for _, f in ipairs(foci) do
    say("under mouse: " .. describe(f))
    local p = f.GetParent and f:GetParent()
    if p then say("  parent: " .. describe(p)) end
  end
  for name, f in pairs(_G) do
    if type(name) == "string" and name:match("^ContainerFrame%w*$") and type(f) == "table" and f.GetObjectType and f:IsShown() then
      say(describe(f))
    end
  end
end

local function resetAll()
  wipe(DB.pos)
  if UpdateUIPanelPositions then UpdateUIPanelPositions() end
  if UpdateContainerFrameAnchors then UpdateContainerFrameAnchors() end
  say("positions reset. Windows snap back as they reopen (/reload to be sure).")
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    if not ns.ModuleEnabled("move") then ev:UnregisterAllEvents(); return end
    EverMoveDB = EverMoveDB or {}
    DB = EverMoveDB
    DB.pos = DB.pos or {}
    -- Blizzard re-anchors panels and bags through these; put ours back after.
    if UpdateUIPanelPositions then hooksecurefunc("UpdateUIPanelPositions", applyShown) end
    if UpdateContainerFrameAnchors then hooksecurefunc("UpdateContainerFrameAnchors", applyShown) end
    for _, fn in ipairs({ "OpenBag", "ToggleBag", "OpenAllBags", "ToggleAllBags",
                          "OpenBackpack", "ToggleBackpack", "ContainerFrame_OnShow" }) do
      if type(_G[fn]) == "function" then hooksecurefunc(fn, onBagsOpened) end
    end
  end
  if not DB then return end
  if event == "PLAYER_REGEN_ENABLED" then
    for frame in pairs(pending) do
      pending[frame] = nil
      if frame:IsShown() then apply(frame) end
    end
  end
  -- Every ADDON_LOADED may have created a load-on-demand window.
  setupAll()
  if event == "PLAYER_LOGIN" then
    say("drag windows by their title bar. /emove for options." .. (DB.locked and " (locked)" or ""))
  end
end)

SLASH_EVERMOVE1 = "/emove"
SLASH_EVERMOVE2 = "/evermove"
SlashCmdList.EVERMOVE = function(msg)
  msg = strlower(strtrim(msg or ""))
  if not DB then
    say("Move module is off. /eg module move on, then /reload.")
  elseif msg == "lock" or msg == "unlock" then
    DB.locked = (msg == "lock")
    say(DB.locked and "windows locked." or "windows unlocked.")
  elseif msg == "reset" then
    resetAll()
  elseif msg == "debug" then
    debugBags()
  else
    say("/emove lock | unlock | reset | debug")
  end
end
