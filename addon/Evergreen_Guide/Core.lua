-- Evergreen: leveling companion for WoW Forever and Classic Era.
-- Tracks a route's quests from your log, tells you the next step, and points a waypoint at it.
-- Routes live in Data.lua (ns.ROUTES); the engine here is race- and faction-agnostic.

local ADDON, ns = ...
local FR = CreateFrame("Frame", "EvergreenEvents")
ns.FR = FR

-- ------------------------------------------------------------------ palette / fonts
-- Colours follow Blizzard's UI (the WoW Forever skin): gold headings, white titles, warm grey
-- secondary text. Green stays for "done" and the chat prefix.
local C = {
  bg      = {0.06, 0.05, 0.04, 0.90},
  panel   = {0.10, 0.08, 0.06, 1},
  line    = {0.35, 0.29, 0.20, 1},
  ink     = {0.91, 0.89, 0.85},
  white   = {1, 1, 1},
  muted   = {0.64, 0.62, 0.58},
  green   = {0.25, 0.75, 0.25},
  gold    = {1, 0.82, 0},
  violet  = {0.71, 0.55, 1},
  red     = {1, 0.25, 0.25},
}
local HEX = {
  ink="|cffe8e4d8", muted="|cffa39e93", green="|cff7fd35e", gold="|cffffd100", violet="|cffb48cff", red="|cffff4040", white="|cffffffff",
}
local FONT_DISPLAY = "Fonts\\FRIZQT__.TTF"
local FONT_BODY    = "Fonts\\FRIZQT__.TTF"
local FONT_NUM     = "Fonts\\FRIZQT__.TTF"

local MAP_NAMES = ns.MAP_NAMES
local ROUTE, BRACKETS          -- active route and its bracket list; set by SelectRoute()
local playerRace, playerFaction, playerClass

local function RouteFits(route)
  -- race match beats faction match; a race that exists on both sides (Skyborne) is split by faction
  if route.races and playerRace and route.races[playerRace] then
    return (route.faction == playerFaction) and 4 or 3
  end
  if route.faction == playerFaction then return 2 end
  return 1
end

-- Steps may carry cls="DRUID" or cls={DRUID=true, SHAMAN=true}: class quests that only this
-- character's class should see. Until the class is known (file load) every step is kept.
-- race="Gnome" (or a set) does the same by race file name, for steps in shared brackets that
-- only one race's version of a class gets (Forever's new race/class combos).
local function ClassFits(step)
  if step.race and playerRace then
    if type(step.race) == "string" then
      if step.race ~= playerRace then return false end
    elseif not step.race[playerRace] then
      return false
    end
  end
  if not step.cls or not playerClass then return true end
  if type(step.cls) == "string" then return step.cls == playerClass end
  return step.cls[playerClass] == true
end

-- Shallow-copy each bracket with the other classes' steps dropped. Step indices, and so the
-- per-character step keys, are stable because a character's class never changes.
local function FilterBrackets(list)
  local out = {}
  for _, b in ipairs(list) do
    local nb = {}
    for k, v in pairs(b) do nb[k] = v end
    nb.steps = {}
    for _, s in ipairs(b.steps) do
      if ClassFits(s) then table.insert(nb.steps, s) end
    end
    table.insert(out, nb)
  end
  return out
end

local function SelectRoute(id)
  local best, bestScore
  for _, r in ipairs(ns.ROUTES) do
    if id and r.id == id then best = r; break end
    local s = RouteFits(r)
    if not bestScore or s > bestScore then best, bestScore = r, s end
  end
  ROUTE = best or ns.ROUTES[1]
  BRACKETS = FilterBrackets(ROUTE.brackets)
  return ROUTE
end
SelectRoute()

-- first bracket a character of this race may use on the active route
local function FirstBracketFor()
  if not ROUTE then return 1 end
  if ROUTE.races and playerRace and ROUTE.races[playerRace] then return 1 end
  return math.min((ROUTE.raceOnly or 0) + 1, #BRACKETS)
end

-- ------------------------------------------------------------------ saved variables
local DB, CDB
local defaults = {
  showForever = true, arrowShown = true, flip = false, scale = 1, locked = false, nativePin = true,
  minimap = { angle = 200 },
  fixes = {},   -- ["bracket:index/phase"] = {x, y, uiMapID}: waypoint overrides set in game with /eg fix
}
local function InitDB()
  EvergreenDB = EvergreenDB or {}
  for k, v in pairs(defaults) do
    if EvergreenDB[k] == nil then EvergreenDB[k] = (type(v) == "table") and CopyTable(v) or v end
  end
  DB = EvergreenDB
  EvergreenCharDB = EvergreenCharDB or {}
  CDB = EvergreenCharDB
  CDB.manual   = CDB.manual   or {}   -- [stepKey] = true (done) / false (forced undone)
  CDB.turnins  = CDB.turnins  or {}   -- [questName] = number of turn-ins seen
  CDB.learned  = CDB.learned  or {}   -- [questName#part] = questID
  CDB.bracket  = CDB.bracket          -- nil = auto
  CDB.focus    = CDB.focus            -- stepKey the arrow follows, or nil
  CDB.route    = CDB.route            -- route id override, nil = auto by race / faction
end

-- ------------------------------------------------------------------ quest log scan
local log = {}        -- byName[name] = { complete=bool, id=number }
local logByID = {}    -- [questID] = same entry
local idToName = {}
local completed       -- set of completed quest ids from the server, or nil when the client has no bulk API
local QUEST_IDS = ns.QUEST_IDS or {}
local QUEST_META = ns.QUEST_META or {}

local function RefreshCompleted()
  local ok, t = false, nil
  if C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs then
    ok, t = pcall(C_QuestLog.GetAllCompletedQuestIDs)
    if ok and type(t) == "table" and #t > 0 then
      completed = {}
      for _, id in ipairs(t) do completed[id] = true end
      return
    end
  end
  if GetQuestsCompleted then
    ok, t = pcall(GetQuestsCompleted)
    if ok and type(t) == "table" and next(t) ~= nil then completed = t; return end
  end
  completed = nil
end

local function ScanLog()
  wipe(log); wipe(logByID)
  if C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetNumQuestLogEntries then
    -- modern quest log API (retail-style clients, possibly the 1.60 Forever build)
    local n = C_QuestLog.GetNumQuestLogEntries() or 0
    for i = 1, n do
      local info = C_QuestLog.GetInfo(i)
      if info and not info.isHeader and info.title then
        local complete = false
        if C_QuestLog.IsComplete then complete = C_QuestLog.IsComplete(info.questID) and true or false end
        log[info.title] = { complete = complete, id = info.questID }
        if info.questID then idToName[info.questID] = info.title; logByID[info.questID] = log[info.title] end
      end
    end
    if next(log) ~= nil or not GetQuestLogTitle then return end
  end
  local n = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
  for i = 1, n do
    local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
    if title and not isHeader then
      log[title] = { complete = (isComplete == 1) or (isComplete == true), id = questID }
      if questID then idToName[questID] = title; logByID[questID] = log[title] end
    end
  end
end

local function QuestFlagged(id)
  if not id then return false end
  if completed and completed[id] then return true end
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    local ok, r = pcall(C_QuestLog.IsQuestFlaggedCompleted, id)
    return ok and r and true or false
  end
  return false
end

-- quest id for a step: hand-set id, else the resolved list for that name at the step's part
local function StepQuestID(step)
  if step.id then return step.id end
  local ids = QUEST_IDS[step.q]
  if ids then return ids[step.p or 1] end
  return nil
end

local function QuestNameFromID(id)
  local name = idToName[id]
  if not name and C_QuestLog and C_QuestLog.GetQuestInfo then name = C_QuestLog.GetQuestInfo(id) end
  if not name and C_QuestLog and C_QuestLog.GetTitleForQuestID then name = C_QuestLog.GetTitleForQuestID(id) end
  return name
end

-- ------------------------------------------------------------------ position helpers
local function Vec(x, y)
  if CreateVector2D then return CreateVector2D(x, y) end
  return { x = x, y = y }
end

local function PlayerMapPos()
  local mapID = C_Map.GetBestMapForUnit("player")
  if not mapID then return nil end
  local pos = C_Map.GetPlayerMapPosition(mapID, "player")
  if not pos then return nil end
  local x, y = pos:GetXY()
  if not x or (x == 0 and y == 0) then return nil end
  return mapID, x, y
end

local function WorldPos(mapID, x, y)
  if not (C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
  local continent, world = C_Map.GetWorldPosFromMapPos(mapID, Vec(x, y))
  if not world then return nil end
  local wx, wy = world:GetXY()
  return continent, wx, wy
end

-- distance in map units (0..100) between the player and a point on the same map
local function MapDistance(mapID, tx, ty)
  local pm, px, py = PlayerMapPos()
  if not pm or pm ~= mapID then return nil end
  local dx, dy = (px * 100) - tx, (py * 100) - ty
  return math.sqrt(dx * dx + dy * dy)
end

-- ------------------------------------------------------------------ step model
local function StepKey(b, i) return b.id .. ":" .. i end

local function StepMap(b, coord) return (coord and coord[4]) or coord.map or b.map end

local function HandCoordUnsure(c)
  if not c then return true end
  local t = c[3] or ""
  return t:find("(verify)", 1, true) ~= nil or t:find("Follow the quest text", 1, true) ~= nil
end

-- Phase coordinates for a quest step. Database coordinates (QuestIDs.lua) win for the
-- giver and turn-in; hand coordinates win for objectives unless they were marked unsure.
-- database coords are {x, y, uiMapID, "name"}; hand coords are {x, y, "text", uiMapID}. Normalize to hand order.
local function FromMeta(c)
  if not c then return nil end
  return { c[1], c[2], c[4] or "", c[3] }
end

local function PhaseCoord(b, step, phase)
  local meta = QUEST_META[StepQuestID(step) or 0]
  local c
  if phase == "turn" then
    c = (meta and FromMeta(meta.r)) or step.r or (meta and FromMeta(meta.g)) or step.g
  elseif phase == "obj" then
    if step.o and not HandCoordUnsure(step.o) then c = step.o
    elseif meta and meta.o then
      local txt = (meta.t and meta.t ~= "" and meta.t) or (step.o and step.o[3]) or "Follow the quest text"
      c = { meta.o[1], meta.o[2], txt, meta.o[3] }
    else c = step.o or (meta and FromMeta(meta.r)) or step.r or (meta and FromMeta(meta.g)) or step.g end
  else
    c = (meta and FromMeta(meta.g)) or step.g
  end
  if not c then return nil end
  local map = c[4]
  if type(map) ~= "number" then map = b.map end
  return c[1], c[2], map, c[3]
end

local function CoordOfRaw(b, step)
  -- returns x, y, map, label for the *current phase* of a step (nil if none)
  if step.q then
    return PhaseCoord(b, step, step.phase or "giver")
  end
  if step.x and step.y then return step.x, step.y, step.map or b.map, step.t or step.man or step.bind or step.fp end
  return nil
end

-- A waypoint fixed in game (/eg fix) wins over the route data for that step and phase.
local function FixKey(step) return (step.key or "?") .. "/" .. (step.q and (step.phase or "giver") or "pt") end

local function CoordOf(b, step)
  local x, y, map, label = CoordOfRaw(b, step)
  local f = DB and DB.fixes and DB.fixes[FixKey(step)]
  if f then return f[1], f[2], f[3], label or step.t end
  return x, y, map, label
end

local function IsInformational(step) return step.note or step.forever end

local function ComputeStep(b, i, step)
  local key = StepKey(b, i)
  step.key = key
  local m = CDB.manual[key]
  local done = false
  step.phase = nil
  step.onQuest = false

  if step.q then
    local part = step.p or 1
    local qid = StepQuestID(step)
    step.qid = qid
    local entry = (qid and logByID[qid]) or (not qid and log[step.q]) or nil
    if entry then
      step.onQuest = true
      step.phase = entry.complete and "turn" or "obj"
      -- learn the quest id for this part while it's in the log (fallback path for unresolved names)
      if not qid and entry.id and (CDB.turnins[step.q] or 0) == part - 1 then
        CDB.learned[step.q .. "#" .. part] = entry.id
      end
    else
      step.phase = "giver"
    end
    if qid and QuestFlagged(qid) then done = true end
    if not qid then
      local lid = CDB.learned[step.q .. "#" .. part]
      if lid and QuestFlagged(lid) then done = true end
      if (CDB.turnins[step.q] or 0) >= part then done = true end
    end
    -- Split steps (optimized routes): one quest becomes accept / do / turn-in steps placed
    -- apart, so pickups batch at a hub and objectives interleave. Turned in = all three done.
    if step.act == "accept" then
      step.phase = "giver"
      if entry then done = true end
    elseif step.act == "do" then
      if entry then
        step.phase = "obj"
        if entry.complete then done = true end
      end
    elseif step.act == "turnin" then
      if entry then step.phase = "turn" end
    end
  elseif step.lv then
    done = UnitLevel("player") >= step.lv
  elseif step.bind then
    local loc = GetBindLocation() or ""
    if loc:lower():find(step.bind:lower(), 1, true) then done = true; CDB.manual[key] = true end
  elseif step.tr then
    local map = step.map or b.map
    if step.any then
      if C_Map.GetBestMapForUnit("player") == map then done = true; CDB.manual[key] = true end
    else
      local d = MapDistance(map, step.x, step.y)
      if d and d <= 3 then done = true; CDB.manual[key] = true end
    end
  end

  if m == true then done = true elseif m == false then done = false end
  step.done = done
  return done
end

local function Recompute(b)
  local lastDoneQuest = 0
  for i, step in ipairs(b.steps) do
    step.skipped = false
    step.implied = false
    if not IsInformational(step) then
      ComputeStep(b, i, step)
      -- only a turn-in proves progress; a done accept/do step just means "in the log"
      if step.q and step.done and (not step.act or step.act == "turnin") then lastDoneQuest = i end
    end
  end
  -- Inference from the character's history: everything before the last quest the server says
  -- is complete has been passed. Travel / bind / flight-point / manual steps there count as done,
  -- and quests there that are neither complete nor in the log are marked skipped so they do not
  -- block the "now" step. Right-click still overrides either way.
  for i = 1, lastDoneQuest - 1 do
    local step = b.steps[i]
    if not IsInformational(step) and not step.done and CDB.manual[step.key] == nil then
      if step.q then
        if not step.onQuest then step.skipped = true end
      elseif not step.lv then
        step.done = true; step.implied = true
      end
    end
  end
end

-- bracket-level inference: if any quest in a later bracket is complete, treat this whole bracket as passed
local function BracketPassed(b)
  for _, step in ipairs(b.steps) do
    if step.q and not step.opt then
      local qid = StepQuestID(step)
      if qid and QuestFlagged(qid) then return true end
    end
  end
  return false
end

local function BracketRequiredLeft(b)
  local left = 0
  for _, step in ipairs(b.steps) do
    if not IsInformational(step) and not step.opt and not step.done then left = left + 1 end
  end
  return left
end

local function AutoBracketIndex()
  local lvl = UnitLevel("player")
  local first = FirstBracketFor()
  local candidates = {}
  for i = first, #BRACKETS do
    local b = BRACKETS[i]
    if lvl >= b.lv[1] and lvl <= b.lv[2] then table.insert(candidates, i) end
  end
  if #candidates == 0 then
    -- above every range: last bracket; below: the first bracket this race may use
    if lvl > BRACKETS[#BRACKETS].lv[2] then return #BRACKETS end
    return first
  end
  for _, i in ipairs(candidates) do
    Recompute(BRACKETS[i])
    if BracketRequiredLeft(BRACKETS[i]) > 0 then return i end
  end
  return candidates[#candidates]
end

local currentIndex = 1
local function CurrentBracket()
  if CDB.bracket and BRACKETS[CDB.bracket] then currentIndex = CDB.bracket else currentIndex = AutoBracketIndex() end
  return BRACKETS[currentIndex]
end

-- "current" = the step the arrow follows: focus if set and undone, else first undone required step
local function CurrentStep(b)
  if CDB.focus then
    for i, step in ipairs(b.steps) do
      if step.key == CDB.focus then
        if step.done then CDB.focus = nil else return step, i end
      end
    end
    -- focus may be in another bracket; drop it
    CDB.focus = nil
  end
  for i, step in ipairs(b.steps) do
    if not IsInformational(step) and not step.done and not step.skipped then
      if not step.opt or step.onQuest then return step, i end
    end
  end
  return nil
end

-- ------------------------------------------------------------------ text rendering
local function PhaseText(b, step)
  if not step.q then return nil end
  local _, _, _, label = PhaseCoord(b, step, step.phase or "giver")
  if step.phase == "turn" then
    return HEX.green .. "Turn in: " .. HEX.ink .. (label or "?") .. "|r"
  elseif step.phase == "obj" then
    if step.o or (QUEST_META[step.qid or 0] and QUEST_META[step.qid or 0].o) then
      return HEX.gold .. "Do: " .. HEX.ink .. (label or "?") .. "|r"
    end
    return HEX.green .. "Deliver to: " .. HEX.ink .. (label or "?") .. "|r"
  else
    return HEX.muted .. "Pick up: " .. HEX.ink .. (label or "?") .. "|r"
  end
end

local function CoordText(b, step)
  local x, y, map = CoordOf(b, step)
  if not x then return "" end
  local zone = MAP_NAMES[map] or ""
  return HEX.gold .. string.format("%d,%d", x, y) .. "|r " .. HEX.muted .. zone .. "|r"
end

local function ClassLabel(step)
  if not step.cls then return "" end
  local name = type(step.cls) == "string" and step.cls or (playerClass or "class")
  return HEX.gold .. " " .. name:sub(1, 1) .. name:sub(2):lower() .. "|r"
end

local function StepTitle(step)
  if step.q then
    local verb = step.act == "accept" and "Accept " or step.act == "do" and "Do " or step.act == "turnin" and "Turn in " or ""
    local t = HEX.muted .. verb .. "|r" .. HEX.white .. step.q .. "|r" .. ClassLabel(step)
    if step.p and step.p > 1 then t = t .. HEX.muted .. " (" .. step.p .. ")|r" end
    if step.opt then t = t .. HEX.muted .. " optional|r" end
    return t
  elseif step.lv then return HEX.white .. "Reach level " .. step.lv .. "|r"
  elseif step.bind then return HEX.white .. "Bind your hearthstone: " .. step.bind .. "|r"
  elseif step.fp then return HEX.white .. "Flight point: " .. step.fp .. "|r"
  elseif step.tr then return HEX.white .. "Travel|r"
  elseif step.man then return HEX.white .. "Manual step|r"
  end
  return ""
end

-- For Everpanel: the step the arrow follows, as plain text (nil before the guide has loaded).
function ns.GuideStepText()
  if not CDB then return nil end
  local b = CurrentBracket()
  local step = b and CurrentStep(b)
  if not step then return nil end
  return (StepTitle(step):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function StepBody(b, step)
  if step.q then
    local s = PhaseText(b, step)
    local ct = CoordText(b, step)
    if ct ~= "" then s = s .. "  " .. ct end
    return s
  elseif step.tr then return HEX.ink .. step.t .. "|r  " .. CoordText(b, step)
  elseif step.man then return HEX.ink .. step.man .. "|r  " .. CoordText(b, step)
  elseif step.bind or step.fp then return CoordText(b, step)
  end
  return ""
end

-- ------------------------------------------------------------------ UI: main frame
local UI = {}
ns.UI = UI
local rows = {}
local ROW_GAP = 4

local function Skin_RowHighlight(f) if ns.Skin and ns.Skin.RowHighlight then return ns.Skin.RowHighlight(f) end end

local function Backdrop(f, bg, border, edge)
  if not f.SetBackdrop then return end
  f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = edge or 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  f:SetBackdropColor(unpack(bg))
  f:SetBackdropBorderColor(unpack(border))
end

-- Text in the client's own UI face (Friz Quadrata) with the usual drop shadow.
local function MakeText(parent, font, size, color, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetFont(font, size, "")
  fs:SetShadowOffset(1, -1)
  fs:SetShadowColor(0, 0, 0, 1)
  fs:SetTextColor(unpack(color))
  fs:SetJustifyH(justify or "LEFT")
  fs:SetJustifyV("TOP")
  return fs
end

-- Blizzard push button (red on WoW Forever); b.text is kept for code that sets the label.
local function MakeButton(parent, w, h, text)
  local b = ns.Skin.Button(parent, text, w, h)
  if b.text and b.text.SetText then
    local orig = b.text.SetText
    b.text.SetText = function(fs, s) if b.SetText and b.GetFontString and b:GetFontString() == fs then b:SetText(s) else orig(fs, s) end end
  end
  return b
end

local function BuildMain()
  local f = ns.Skin.Window("EvergreenFrame", 420, 540, "Evergreen", "Interface\\Icons\\Spell_Nature_NatureTouchGrow", function() UI.SavePos() end)
  f:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
  f:SetResizable(true)
  if f.SetResizeBounds then f:SetResizeBounds(360, 360) elseif f.SetMinResize then f:SetMinResize(360, 360) end
  f:SetFrameStrata("MEDIUM")
  f:SetScript("OnDragStart", function(s) if not DB.locked then s:StartMoving() end end)
  UI.main = f
  local left = f.portraitW + 4

  -- route line under the title bar (click to cycle routes)
  local rt = CreateFrame("Button", nil, f)
  rt:SetPoint("TOPLEFT", left, f.contentTop - 4); rt:SetPoint("TOPRIGHT", -12, f.contentTop - 4); rt:SetHeight(16)
  rt.text = MakeText(rt, FONT_BODY, 10, C.muted); rt.text:SetPoint("LEFT"); rt.text:SetPoint("RIGHT"); rt.text:SetWordWrap(false)
  rt:SetScript("OnClick", function()
    -- cycle routes
    local idx = 1
    for i, r in ipairs(ns.ROUTES) do if r == ROUTE then idx = i end end
    local nextRoute = ns.ROUTES[(idx % #ns.ROUTES) + 1]
    CDB.route = nextRoute.id; SelectRoute(CDB.route); CDB.bracket = nil; UI.Refresh()
  end)
  rt:SetScript("OnEnter", function(s)
    GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Route", 1, 0.82, 0)
    for _, r in ipairs(ns.ROUTES) do
      GameTooltip:AddLine((r == ROUTE and "> " or "   ") .. r.name .. "  (" .. r.faction .. ")", 1, 1, 1)
    end
    GameTooltip:AddLine("Click to cycle. /eg route <id> to pick, /eg route auto to reset.", 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  rt:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.routeText = rt.text
  UI.titleText = rt.text

  -- bracket selector: < > Auto, level range, zone name, hub line
  local sel = CreateFrame("Frame", nil, f)
  sel:SetPoint("TOPLEFT", left, f.contentTop - 22); sel:SetPoint("TOPRIGHT", -12, f.contentTop - 22); sel:SetHeight(40)
  local prev = MakeButton(sel, 26, 22, "<"); prev:SetPoint("TOPLEFT", 0, 0)
  local nxt  = MakeButton(sel, 26, 22, ">"); nxt:SetPoint("LEFT", prev, "RIGHT", 2, 0)
  local auto = MakeButton(sel, 50, 22, "Auto"); auto:SetPoint("LEFT", nxt, "RIGHT", 2, 0)
  UI.autoBtn = auto
  prev:SetScript("OnClick", function() CDB.bracket = math.max(1, currentIndex - 1); UI.Refresh() end)
  nxt:SetScript("OnClick", function() CDB.bracket = math.min(#BRACKETS, currentIndex + 1); UI.Refresh() end)
  auto:SetScript("OnClick", function() CDB.bracket = nil; UI.Refresh() end)
  local lv = MakeText(sel, FONT_BODY, 13, C.gold); lv:SetPoint("LEFT", auto, "RIGHT", 8, 0)
  UI.lvText = lv
  local zn = MakeText(sel, FONT_BODY, 13, C.ink); zn:SetPoint("LEFT", lv, "RIGHT", 6, 0)
  zn:SetPoint("RIGHT", sel, "RIGHT", 0, 0); zn:SetWordWrap(false)
  UI.zoneText = zn
  local meta = MakeText(sel, FONT_BODY, 10, C.muted); meta:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -3)
  meta:SetPoint("RIGHT", sel, "RIGHT", 0, 0); meta:SetWordWrap(false)
  UI.metaText = meta

  -- "now" panel: what to do next, in an inset
  local now = CreateFrame("Button", nil, f)
  now:SetPoint("TOPLEFT", 10, f.contentTop - 70); now:SetPoint("TOPRIGHT", -10, f.contentTop - 70); now:SetHeight(64)
  local nowBg = ns.Skin.Inset(now); nowBg:SetAllPoints()
  Skin_RowHighlight(now)
  now:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local nowLabel = MakeText(now, FONT_BODY, 9, C.gold); nowLabel:SetPoint("TOPLEFT", 10, -7); nowLabel:SetText("NEXT STEP")
  local nowTitle = MakeText(now, FONT_BODY, 13, C.white); nowTitle:SetPoint("TOPLEFT", 10, -19); nowTitle:SetPoint("RIGHT", -10, 0); nowTitle:SetWordWrap(false)
  local nowBody = MakeText(now, FONT_BODY, 11, C.ink); nowBody:SetPoint("TOPLEFT", nowTitle, "BOTTOMLEFT", 0, -3); nowBody:SetPoint("RIGHT", -10, 0); nowBody:SetWordWrap(true)
  nowBody:SetMaxLines(2)
  local nowDist = MakeText(now, FONT_BODY, 11, C.gold, "RIGHT"); nowDist:SetPoint("TOPRIGHT", -10, -7)
  UI.now, UI.nowTitle, UI.nowBody, UI.nowDist = now, nowTitle, nowBody, nowDist
  now:SetScript("OnClick", function(_, btn)
    if btn == "RightButton" then
      local step = UI.currentStep
      if step then CDB.manual[step.key] = true; UI.Refresh() end
    else
      DB.arrowShown = not DB.arrowShown; UI.UpdateArrow(true)
    end
  end)
  now:SetScript("OnEnter", function(s)
    GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Left-click: show / hide the arrow", 1, 1, 1)
    GameTooltip:AddLine("Right-click: mark this step done and move on", 1, 1, 1)
    GameTooltip:Show()
  end)
  now:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- step list in an inset, like the quest log
  local listBg = ns.Skin.Inset(f)
  listBg:SetPoint("TOPLEFT", now, "BOTTOMLEFT", 0, -6)
  listBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 46)
  local scroll = CreateFrame("ScrollFrame", "EvergreenScroll", listBg, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 6, -6)
  scroll:SetPoint("BOTTOMRIGHT", -28, 6)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)
  UI.scroll, UI.content = scroll, content
  scroll:SetScript("OnSizeChanged", function() UI.Layout() end)

  -- footer: bracket progress, racial cooldowns, Forever notes toggle
  local foot = CreateFrame("Frame", nil, f)
  foot:SetPoint("BOTTOMLEFT", 14, 10); foot:SetPoint("BOTTOMRIGHT", -14, 10); foot:SetHeight(32)
  local bar = CreateFrame("StatusBar", nil, foot)
  bar:SetPoint("TOPLEFT", 0, 0); bar:SetPoint("TOPRIGHT", -120, 0); bar:SetHeight(10)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(0.85, 0.62, 0.12)
  local barBG = bar:CreateTexture(nil, "BACKGROUND"); barBG:SetAllPoints(); barBG:SetColorTexture(0, 0, 0, 0.6)
  bar:SetMinMaxValues(0, 1); bar:SetValue(0)
  UI.bar = bar
  local prog = MakeText(foot, FONT_BODY, 10, C.muted); prog:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
  UI.progText = prog
  local cd = MakeText(foot, FONT_BODY, 10, C.muted, "RIGHT"); cd:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
  cd:SetPoint("LEFT", prog, "RIGHT", 6, 0)
  UI.cdText = cd
  local fev = CreateFrame("CheckButton", nil, foot, "UICheckButtonTemplate")
  fev:SetSize(22, 22); fev:SetPoint("TOPRIGHT", foot, "TOPRIGHT", 0, 6)
  fev:SetChecked(DB.showForever)
  fev:SetScript("OnClick", function(s) DB.showForever = s:GetChecked() and true or false; UI.Refresh() end)
  local fevT = MakeText(foot, FONT_BODY, 10, C.violet, "RIGHT"); fevT:SetPoint("RIGHT", fev, "LEFT", 0, 0); fevT:SetText("Forever notes")

  -- resize grip
  local grip = CreateFrame("Button", nil, f)
  grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", -4, 4)
  grip:SetFrameLevel(f:GetFrameLevel() + 20)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
  grip:SetScript("OnMouseUp", function() f:StopMovingOrSizing(); UI.SavePos(); UI.Layout() end)

  if f.CloseButton then f.CloseButton:SetScript("OnClick", function() f:Hide() end) end
  f:SetScript("OnShow", function() UI.Refresh() end)
  f:Hide()
end

function UI.SavePos()
  local f = UI.main
  local p, _, rp, x, y = f:GetPoint(1)
  DB.pos = { p, rp, x, y, f:GetWidth(), f:GetHeight() }
end

function UI.RestorePos()
  local f = UI.main
  if DB.pos then
    f:ClearAllPoints(); f:SetPoint(DB.pos[1], UIParent, DB.pos[2], DB.pos[3], DB.pos[4])
    f:SetSize(DB.pos[5] or 420, DB.pos[6] or 520)
  end
  f:SetScale(DB.scale or 1)
end

-- rows ----------------------------------------------------------------
local function GetRow(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Button", nil, UI.content)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  Skin_RowHighlight(r)
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(14, 14); r.icon:SetPoint("TOPLEFT", 6, -5)
  r.who = MakeText(r, FONT_DISPLAY, 12, C.gold); r.who:SetPoint("TOPLEFT", 8, -4)
  r.title = MakeText(r, FONT_BODY, 12, C.ink); r.title:SetPoint("TOPLEFT", 26, -4); r.title:SetPoint("RIGHT", -6, 0); r.title:SetWordWrap(true)
  r.body = MakeText(r, FONT_BODY, 11, C.ink); r.body:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -2); r.body:SetPoint("RIGHT", -6, 0); r.body:SetWordWrap(true)
  r.stripe = r:CreateTexture(nil, "BACKGROUND"); r.stripe:SetWidth(2); r.stripe:SetPoint("TOPLEFT", 0, -2); r.stripe:SetPoint("BOTTOMLEFT", 0, 2)
  r:SetScript("OnClick", function(s, btn)
    local step = s.step
    if not step or IsInformational(step) then return end
    if btn == "RightButton" then
      if step.skipped then
        CDB.manual[step.key] = false; UI.Refresh(); return
      end
      if IsShiftKeyDown() then
        -- mark everything above (and this) done
        local b = BRACKETS[currentIndex]
        for j = 1, s.index do
          local st = b.steps[j]
          if not IsInformational(st) then CDB.manual[st.key] = true end
        end
      else
        if step.done then CDB.manual[step.key] = false else CDB.manual[step.key] = true end
      end
      UI.Refresh()
    else
      if CDB.focus == step.key then CDB.focus = nil else CDB.focus = step.key end
      UI.Refresh()
    end
  end)
  r:SetScript("OnEnter", function(s)
    local step = s.step
    if not step or IsInformational(step) then return end
    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
    if step.q then
      GameTooltip:AddLine(step.q .. (step.qid and (HEX.muted .. "  #" .. step.qid .. "|r") or (HEX.red .. "  (no id: name-matched only)|r")), 1, 1, 1)
      local b = BRACKETS[currentIndex]
      local gx, gy, gm, gl = PhaseCoord(b, step, "giver")
      local ox, oy, om, ol = PhaseCoord(b, step, "obj")
      local rx, ry, rm, rl = PhaseCoord(b, step, "turn")
      if gx then GameTooltip:AddLine("Pick up: " .. (gl or "") .. "  (" .. gx .. "," .. gy .. " " .. (MAP_NAMES[gm] or "") .. ")", 0.6, 0.6, 0.6, true) end
      if ox and (step.o or (QUEST_META[step.qid or 0] and QUEST_META[step.qid or 0].o)) then GameTooltip:AddLine("Do: " .. (ol or "") .. "  (" .. ox .. "," .. oy .. " " .. (MAP_NAMES[om] or "") .. ")", 0.82, 0.68, 0.30, true) end
      if rx then GameTooltip:AddLine("Turn in: " .. (rl or "") .. "  (" .. rx .. "," .. ry .. " " .. (MAP_NAMES[rm] or "") .. ")", 0.5, 0.83, 0.37, true) end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: point the arrow here", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: mark done / undone", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Shift-right-click: mark this and everything above done", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  rows[i] = r
  return r
end

local ICON_DONE    = "Interface\\RaidFrame\\ReadyCheck-Ready"
local ICON_PENDING = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local ICON_CURRENT = "Interface\\Minimap\\MiniMap-QuestArrow"
local ICON_FOCUS   = "Interface\\Minimap\\MiniMap-DeadArrow"

local visibleRows = 0

function UI.Layout()
  local b = BRACKETS[currentIndex]
  local width = UI.scroll:GetWidth()
  if not width or width < 50 then return end
  UI.content:SetWidth(width)
  local y = 0
  for i = 1, visibleRows do
    local r = rows[i]
    r:SetWidth(width)
    r.title:SetWidth(width - 32)
    r.body:SetWidth(width - 32)
    local h = 8
    if r.who:IsShown() then
      r.body:SetWidth(width - 14)
      h = h + r.who:GetStringHeight() + 2 + r.body:GetStringHeight()
    else
      h = h + r.title:GetStringHeight()
      if r.body:GetText() and r.body:GetText() ~= "" then h = h + 2 + r.body:GetStringHeight() end
    end
    r:SetHeight(h)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", UI.content, "TOPLEFT", 0, -y)
    y = y + h + ROW_GAP
  end
  UI.content:SetHeight(math.max(y, 1))
end

function UI.Refresh()
  if not UI.main then return end
  ScanLog()
  if not completed then RefreshCompleted() end
  local b = CurrentBracket()
  Recompute(b)
  local cur, curIndex = CurrentStep(b)
  UI.currentStep = cur

  UI.lvText:SetText(b.lv[1] .. "-" .. b.lv[2])
  UI.zoneText:SetText(b.name)
  if UI.routeText then
    local joined = (currentIndex < FirstBracketFor()) and HEX.red .. " (starting chapters are " .. (ROUTE.faction == "Horde" and "Undead" or "another race") .. "-only)|r" or ""
    UI.routeText:SetText(HEX.muted .. ROUTE.name .. " · " .. ROUTE.faction .. "|r" .. joined)
  end
  UI.metaText:SetText(HEX.muted .. "Hearth: " .. HEX.ink .. (b.hearth or "-") .. HEX.muted .. "   FP: " .. HEX.ink .. (b.fp or "-") .. "|r")
  UI.autoBtn.text:SetText(CDB.bracket and "Auto" or HEX.gold .. "Auto|r")

  -- now panel
  if cur then
    UI.nowTitle:SetText(StepTitle(cur))
    UI.nowBody:SetText(StepBody(b, cur))
  else
    UI.nowTitle:SetText(HEX.green .. "Bracket complete|r")
    UI.nowBody:SetText(HEX.muted .. "Press > for the next bracket, or Auto to follow your level.|r")
  end

  -- rows
  local n = 0
  local done, total = 0, 0
  for i, step in ipairs(b.steps) do
    local show = true
    if step.forever and not DB.showForever then show = false end
    if show then
      n = n + 1
      local r = GetRow(n)
      r.step, r.index = step, i
      r:Show()
      if step.note or step.forever then
        r.icon:Hide(); r.title:SetText("")
        r.who:Show(); r.who:SetText(step.note or "Forever")
        r.who:SetTextColor(unpack(step.forever and C.violet or C.gold))
        r.body:ClearAllPoints(); r.body:SetPoint("TOPLEFT", r.who, "BOTTOMLEFT", 0, -2); r.body:SetPoint("RIGHT", -6, 0)
        r.body:SetText((step.forever and HEX.violet or HEX.muted) .. step.t .. "|r")
        r.stripe:SetColorTexture(step.forever and C.violet[1] or C.line[1], step.forever and C.violet[2] or C.line[2], step.forever and C.violet[3] or C.line[3], 0.7)
      else
        r.who:Hide(); r.icon:Show()
        r.body:ClearAllPoints(); r.body:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -2); r.body:SetPoint("RIGHT", -6, 0)
        if not step.opt then total = total + 1; if step.done then done = done + 1 end end
        local isCur = (cur == step)
        if step.done then
          r.icon:SetTexture(ICON_DONE); r.icon:SetVertexColor(1, 1, 1)
          r.title:SetText(HEX.muted .. StepTitle(step):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") .. (step.implied and "  (passed)" or "") .. "|r")
          r.body:SetText("")
          r.stripe:SetColorTexture(C.line[1], C.line[2], C.line[3], 0.5)
        elseif step.skipped then
          r.icon:SetTexture(ICON_PENDING); r.icon:SetVertexColor(0.45, 0.45, 0.45)
          r.title:SetText(HEX.muted .. StepTitle(step):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") .. "  (skipped; right-click to un-skip)|r")
          r.body:SetText("")
          r.stripe:SetColorTexture(C.line[1], C.line[2], C.line[3], 0.3)
        else
          if isCur then
            r.icon:SetTexture(CDB.focus == step.key and ICON_FOCUS or ICON_CURRENT); r.icon:SetVertexColor(1, 1, 1)
            r.stripe:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
          else
            r.icon:SetTexture(ICON_PENDING); r.icon:SetVertexColor(0.6, 0.6, 0.6)
            r.stripe:SetColorTexture(C.line[1], C.line[2], C.line[3], (step.opt and not step.onQuest) and 0.3 or 0.7)
          end
          r.title:SetText(StepTitle(step))
          if step.opt and not step.onQuest and not isCur then
            r.body:SetText(HEX.muted .. (step.q and ("Pick up: " .. (step.g and step.g[3] or "")) or "") .. "|r")
          else
            r.body:SetText(StepBody(b, step))
          end
        end
      end
    end
  end
  visibleRows = n
  for i = n + 1, #rows do rows[i]:Hide(); rows[i].step = nil end
  UI.Layout()

  UI.bar:SetMinMaxValues(0, math.max(total, 1)); UI.bar:SetValue(done)
  UI.progText:SetText(done .. " / " .. total .. " steps")
  UI.UpdateArrow(true)
end

-- ------------------------------------------------------------------ arrow
local arrow
local tomtomHandle
local lastTargetKey

local function BuildArrow()
  local a = CreateFrame("Frame", "EvergreenArrow", UIParent, "BackdropTemplate")
  a:SetSize(150, 118)
  a:SetPoint("TOP", UIParent, "TOP", 0, -140)
  a:SetMovable(true); a:EnableMouse(true); a:SetClampedToScreen(true)
  a:SetFrameStrata("MEDIUM")
  a:RegisterForDrag("LeftButton")
  a:SetScript("OnDragStart", function(s) if not DB.locked then s:StartMoving() end end)
  a:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    local p, _, rp, x, y = s:GetPoint(1); DB.arrowPos = { p, rp, x, y }
  end)
  -- TomTom-style sprite sheet: 512x512, 9 x 12 cells of 56x42, 108 pre-rendered rotations of a shaded 3D arrow
  a.tex = a:CreateTexture(nil, "ARTWORK")
  a.tex:SetSize(108, 81); a.tex:SetPoint("TOP", 0, -2)
  a.tex:SetTexture("Interface\\AddOns\\Evergreen\\arrow")
  a.tex:SetTexCoord(0, 56 / 512, 0, 42 / 512)
  a.title = MakeText(a, FONT_BODY, 11, C.ink, "CENTER"); a.title:SetPoint("TOP", a.tex, "BOTTOM", 0, -2); a.title:SetWidth(148); a.title:SetWordWrap(false)
  a.dist = MakeText(a, FONT_NUM, 13, C.gold, "CENTER"); a.dist:SetPoint("TOP", a.title, "BOTTOM", 0, -1)
  a.status = MakeText(a, FONT_NUM, 9, C.muted, "CENTER"); a.status:SetPoint("TOP", a.dist, "BOTTOM", 0, -1)
  a:SetScript("OnMouseUp", function(_, btn) if btn == "RightButton" then DB.arrowShown = false; UI.UpdateArrow(true) end end)
  a:Hide()
  arrow = a
  if DB.arrowPos then a:ClearAllPoints(); a:SetPoint(DB.arrowPos[1], UIParent, DB.arrowPos[2], DB.arrowPos[3], DB.arrowPos[4]) end
end

local function SetTomTom(map, x, y, title)
  if not (TomTom and TomTom.AddWaypoint) then return end
  if tomtomHandle then pcall(TomTom.RemoveWaypoint, TomTom, tomtomHandle); tomtomHandle = nil end
  if map and x then
    local ok, h = pcall(TomTom.AddWaypoint, TomTom, map, x / 100, y / 100, { title = "Evergreen: " .. (title or ""), persistent = false, minimap = true, world = true, crazy = false })
    if ok then tomtomHandle = h end
  end
end

-- The game's own floating waypoint (retail-style clients): a pin in the 3D world with
-- distance, on the minimap and the map. Secret-safe because Blizzard draws it.
local nativePinOK
local function NativePin(map, x, y)
  if not DB.nativePin then return end
  if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then nativePinOK = false; return end
  local ok = pcall(function()
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(map) then error("map does not allow user waypoints") end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x / 100, y / 100))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
  end)
  nativePinOK = ok
end
local function ClearNativePin()
  if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
end

local target -- { map, x, y, label, key }

-- Other modules (the Dungeon Journal) can point the arrow somewhere else for a while:
-- ns.SetExternalTarget(uiMapID, x, y, title) takes over until ns.ClearExternalTarget() or arrival.
local external
function ns.SetExternalTarget(map, x, y, title)
  external = { map = map, x = x, y = y, title = title }
  if UI.UpdateArrow then UI.UpdateArrow(true) end
end
function ns.ClearExternalTarget()
  external = nil
  if UI.UpdateArrow then UI.UpdateArrow(true) end
end
function ns.GetExternalTarget() return external end

function UI.UpdateArrow(force)
  local b = BRACKETS[currentIndex]
  local step = UI.currentStep
  local tx, ty, tmap, label
  if external then
    step = nil
    tx, ty, tmap, label = external.x, external.y, external.map, external.title
  elseif step then tx, ty, tmap, label = CoordOf(b, step) end
  local key = external and ("ext:" .. tostring(tmap) .. ":" .. tostring(tx) .. ":" .. tostring(ty)) or (step and (step.key .. ":" .. tostring(step.phase))) or nil
  if key ~= lastTargetKey or force then
    lastTargetKey = key
    if tx then
      target = { map = tmap, x = tx, y = ty, label = label, title = (step and step.q) or label, external = external and true }
      SetTomTom(tmap, tx, ty, (step and step.q) or label)
      NativePin(tmap, tx, ty)
    else
      target = nil
      SetTomTom(nil)
      ClearNativePin()
    end
  end
  if not arrow then return end
  if not DB.arrowShown or not target then arrow:Hide(); UI.nowDist:SetText(""); return end
  arrow:Show()
  arrow.title:SetText((step and step.q and (HEX.white .. step.q .. "|r")) or (HEX.ink .. (label or "") .. "|r"))
end

local function FormatDist(yards)
  if yards >= 1000 then return string.format("%.1f k yd", yards / 1000) end
  return string.format("%d yd", yards)
end

local elapsed, cdElapsed = 0, 0
local arrowFails, cdFails = 0, 0
local lastArrowErr, lastMode

-- Distance and bearing to the target. Bearing is radians, 0 = north, counter-clockwise positive,
-- which is the same convention GetPlayerFacing() uses.
-- Tries world coordinates first (works across zones), then falls back to same-map math.
local function BearingToTarget(pm, px, py)
  local pc, pwx, pwy = WorldPos(pm, px, py)
  local tc, twx, twy = WorldPos(target.map, target.x / 100, target.y / 100)
  if pc and tc then
    if pc ~= tc then return nil, nil, "continent" end
    local dx, dy = twx - pwx, twy - pwy          -- world x = north, world y = west
    return math.sqrt(dx * dx + dy * dy), math.atan2(dy, dx), "world"
  end
  if pm == target.map then
    local dx, dy = target.x / 100 - px, target.y / 100 - py   -- map x = east, map y = south
    local w, h
    if C_Map.GetMapWorldSize then w, h = C_Map.GetMapWorldSize(pm) end
    local dist
    if w and h and w > 0 then dist = math.sqrt((dx * w) ^ 2 + (dy * h) ^ 2) else dist = math.sqrt(dx * dx + dy * dy) * 100 end
    return dist, math.atan2(-dx, -dy), (w and w > 0) and "map" or "units"
  end
  return nil, nil, "zone"
end

local TWO_PI = math.pi * 2
local function SetArrowAngle(rot)
  -- pick the pre-rendered frame closest to rot (radians, counter-clockwise positive)
  local cell = math.floor(((rot % TWO_PI) / TWO_PI) * 108 + 0.5) % 108
  local col, row = cell % 9, math.floor(cell / 9)
  arrow.tex:SetTexCoord(col * 56 / 512, (col + 1) * 56 / 512, row * 42 / 512, (row + 1) * 42 / 512)
end

local function ArrowTick()
  if not target or not arrow or not arrow:IsShown() then return end
  local pm, px, py = PlayerMapPos()
  if not pm then
    arrow.dist:SetText(HEX.muted .. "no position|r"); arrow.status:SetText("map position unavailable here")
    arrow.tex:SetAlpha(0.25); lastMode = "noposition"; return
  end
  local dist, bearing, mode = BearingToTarget(pm, px, py)
  lastMode = mode
  if not dist then
    arrow.tex:SetAlpha(0.25); SetArrowAngle(0)
    arrow.dist:SetText(HEX.muted .. (mode == "continent" and "other continent" or (MAP_NAMES[target.map] or "other zone")) .. "|r")
    arrow.status:SetText(mode == "continent" and "take a zeppelin or boat" or ("you: map " .. tostring(pm) .. ", target: map " .. tostring(target.map)))
    UI.nowDist:SetText(HEX.muted .. (MAP_NAMES[target.map] or "") .. "|r")
    return
  end
  arrow.tex:SetAlpha(1)
  local facing = GetPlayerFacing()
  local rot = bearing - (facing or 0)
  if DB.flip then rot = -rot end
  SetArrowAngle(rot)
  local txt = (mode == "units") and string.format("%d u", dist) or FormatDist(dist)
  if target.external and ((mode == "units" and dist < 1) or (mode ~= "units" and dist < 12)) then
    print(HEX.green .. "Evergreen:|r arrived at " .. (target.title or "the waypoint") .. ". Back to the guide.")
    ns.ClearExternalTarget()
    return
  end
  arrow.dist:SetText(txt)
  arrow.status:SetText(facing and "" or "no facing data: arrow shows compass bearing")
  UI.nowDist:SetText(txt .. "  " .. HEX.muted .. (MAP_NAMES[target.map] or "") .. "|r")
  -- tint by how far off your heading is: green facing the target, yellow sideways, red facing away
  local close = (mode == "units") and (dist < 2) or (dist < 30)
  if close then
    arrow.tex:SetVertexColor(1, 0.85, 0.35)
  else
    local dev = math.abs(((rot + math.pi) % TWO_PI) - math.pi) / math.pi   -- 0 = dead on, 1 = opposite
    local r, g, b
    if dev < 0.5 then
      local t = dev * 2                                   -- green -> yellow
      r, g, b = 0.45 + 0.55 * t, 0.85, 0.30 - 0.10 * t
    else
      local t = (dev - 0.5) * 2                           -- yellow -> red
      r, g, b = 1.0, 0.85 - 0.60 * t, 0.20
    end
    arrow.tex:SetVertexColor(r, g, b)
  end
end

local refreshElapsed = 0
local function OnUpdate(_, dt)
  elapsed = elapsed + dt
  cdElapsed = cdElapsed + dt
  refreshElapsed = refreshElapsed + dt
  -- safety net: re-read the quest log every 2 s even if no event arrived
  if refreshElapsed > 2 then
    refreshElapsed = 0
    if (UI.main and UI.main:IsShown()) or (arrow and arrow:IsShown()) then pcall(UI.Refresh) end
  end
  if cdElapsed > 0.5 and cdFails < 5 then
    cdElapsed = 0
    local ok, err = pcall(UI.UpdateCooldowns)
    if not ok then
      cdFails = cdFails + 1
      if cdFails == 5 then UI.cdText:SetText(""); print(HEX.red .. "Evergreen:|r cooldown strip disabled (" .. tostring(err) .. ")") end
    end
  end
  if elapsed < 0.08 then return end
  elapsed = 0
  if arrowFails >= 5 then return end
  local ok, err = pcall(ArrowTick)
  if not ok then
    arrowFails = arrowFails + 1
    lastArrowErr = tostring(err)
    if arrow and arrow.status then arrow.status:SetText(HEX.red .. "error, see chat|r") end
    if arrowFails == 1 then print(HEX.red .. "Evergreen:|r arrow error: " .. lastArrowErr) end
    if arrowFails == 5 then
      if arrow then arrow:Hide() end
      print(HEX.red .. "Evergreen:|r arrow disabled after repeated errors. /eg debug for details.")
    end
  end
end

function UI.Debug()
  local function s(v) local ok, r = pcall(tostring, v); return ok and r or "<secret>" end
  local pm = C_Map.GetBestMapForUnit("player")
  local px, py
  pcall(function() local _, x, y = PlayerMapPos(); px, py = x, y end)
  print(HEX.green .. "Evergreen debug|r")
  print("  client: " .. s(GetBuildInfo and GetBuildInfo() or "?"))
  print("  player map: " .. s(pm) .. " (" .. s(MAP_NAMES[pm] or (C_Map.GetMapInfo and pm and C_Map.GetMapInfo(pm) and C_Map.GetMapInfo(pm).name) or "?") .. ")  pos: " .. s(px) .. ", " .. s(py) .. "  facing: " .. s(GetPlayerFacing and GetPlayerFacing()))
  print("  target: " .. (target and (s(target.x) .. "," .. s(target.y) .. " map " .. s(target.map) .. " " .. s(MAP_NAMES[target.map])) or "none") .. "  mode: " .. s(lastMode))
  print("  api: GetWorldPosFromMapPos=" .. s(C_Map.GetWorldPosFromMapPos ~= nil) .. " GetMapWorldSize=" .. s(C_Map.GetMapWorldSize ~= nil) .. " SetUserWaypoint=" .. s(C_Map.SetUserWaypoint ~= nil) .. " SuperTrack=" .. s(C_SuperTrack ~= nil) .. " TomTom=" .. s(TomTom ~= nil))
  local ev = {}
  for k, v in pairs(eventCounts) do table.insert(ev, k .. "=" .. v) end
  table.sort(ev)
  local nlog = 0
  for _ in pairs(log) do nlog = nlog + 1 end
  local ncomp = 0
  if completed then for _ in pairs(completed) do ncomp = ncomp + 1 end end
  print("  quest log entries seen: " .. nlog .. "   bulk completed list: " .. (completed and ncomp or "none (per-quest flags)") .. "   modern log api: " .. s(C_QuestLog and C_QuestLog.GetInfo ~= nil))
  print("  events: " .. table.concat(ev, " "))
  print("  native pin: " .. (DB.nativePin and "on" or "off") .. " last set ok=" .. s(nativePinOK) .. "   arrow shown=" .. s(arrow and arrow:IsShown()) .. " fails=" .. arrowFails .. " lastErr=" .. s(lastArrowErr))
end

-- ------------------------------------------------------------------ racial cooldown strip
local racialSlots   -- { {short, spellID}, ... } resolved once per login for this character's race
local function ResolveRacials()
  racialSlots = {}
  local list = ns.RACIAL_SPELLS[playerRace or ""]
  if not list then return end
  for _, entry in ipairs(list) do
    for i = 2, #entry do
      local id = entry[i]
      local known = false
      pcall(function()
        if IsPlayerSpell and IsPlayerSpell(id) then known = true
        elseif IsSpellKnown and IsSpellKnown(id) then known = true end
      end)
      if known then table.insert(racialSlots, { entry[1], id }); break end
    end
  end
end

function UI.UpdateCooldowns()
  if not UI.cdText then return end
  if not racialSlots or #racialSlots == 0 then UI.cdText:SetText(""); return end
  -- Newer clients hand back "secret" numbers for cooldowns that cannot be compared or
  -- concatenated by addon code, so every numeric step lives inside pcall and the
  -- non-secret isActive flag decides ready / on cooldown.
  local function secondsLeft(start, dur)
    local ok, left = pcall(function()
      if not start or not dur or dur <= 2 or start <= 0 then return nil end
      return string.format("%ds", math.ceil(start + dur - GetTime()))
    end)
    if ok then return left end
    return nil
  end
  local function cd(id, short)
    local active, start, dur
    if C_Spell and C_Spell.GetSpellCooldown then
      local info = C_Spell.GetSpellCooldown(id)
      if info then
        start, dur = info.startTime, info.duration
        if info.isActive ~= nil then active = info.isActive and true or false end
      end
    elseif GetSpellCooldown then
      start, dur = GetSpellCooldown(id)
    end
    local left = secondsLeft(start, dur)
    if active == nil then active = (left ~= nil) end
    if active then
      return HEX.muted .. short .. " " .. HEX.red .. (left or "on cd") .. "|r"
    end
    return HEX.muted .. short .. " " .. HEX.green .. "ready|r"
  end
  local parts = {}
  for _, slot in ipairs(racialSlots) do table.insert(parts, cd(slot[2], slot[1])) end
  UI.cdText:SetText(table.concat(parts, "   "))
end

-- ------------------------------------------------------------------ minimap button
local function BuildMinimap()
  -- one of three Evergreen minimap buttons (guide, journal, buffs); see ns.Skin.MinimapButton
  ns.Skin.MinimapButton("guide", "Interface\\Icons\\INV_Misc_Map_01", (DB.minimap and DB.minimap.angle) or 200,
    function(b)
      if b == "RightButton" then DB.arrowShown = not DB.arrowShown; UI.UpdateArrow(true)
      else if UI.main:IsShown() then UI.main:Hide() else UI.main:Show() end end
    end,
    function(tt)
      tt:AddLine("Evergreen: leveling guide", 1, 0.82, 0)
      if ROUTE then tt:AddLine(ROUTE.name, 1, 1, 1) end
      tt:AddLine("Left-click: guide window", 0.9, 0.9, 0.9)
      tt:AddLine("Right-click: show / hide the arrow", 0.9, 0.9, 0.9)
    end)
end

-- ------------------------------------------------------------------ flight point detection
local function OnTaxiOpened()
  local b = BRACKETS[currentIndex]
  for _, step in ipairs(b.steps) do
    if step.fp and not step.done then
      local d = MapDistance(step.map or b.map, step.x, step.y)
      if d and d <= 6 then CDB.manual[step.key] = true end
    end
  end
  UI.Refresh()
end

-- ------------------------------------------------------------------ events
local eventCounts = {}
ns.eventCounts = eventCounts
local pendingRefresh
local function QueueRefresh()
  if pendingRefresh then return end
  pendingRefresh = true
  C_Timer.After(0.3, function() pendingRefresh = false; UI.Refresh() end)
end

for _, ev in ipairs({
  "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD",
  "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED",
  "PLAYER_LEVEL_UP", "TAXIMAP_OPENED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "HEARTHSTONE_BOUND",
}) do
  pcall(FR.RegisterEvent, FR, ev)   -- some of these do not exist on every client build
end

FR:SetScript("OnEvent", function(self, event, a1, a2)
  eventCounts[event] = (eventCounts[event] or 0) + 1
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    InitDB()
    if not ns.ModuleEnabled("guide") then self:UnregisterAllEvents(); return end
    BuildMain(); BuildArrow(); BuildMinimap()
    UI.RestorePos()
    self:SetScript("OnUpdate", OnUpdate)
  elseif event == "PLAYER_LOGIN" then
    local _, race = UnitRace("player")
    playerRace = race
    playerFaction = UnitFactionGroup("player")
    local _, cls = UnitClass("player")
    playerClass = cls
    SelectRoute(CDB.route)
    ResolveRacials()
    RefreshCompleted()
    ScanLog()
    UI.Refresh()
    -- the completed-quest list can arrive a moment after login on some clients
    C_Timer.After(3, function() RefreshCompleted(); UI.Refresh() end)
    if currentIndex >= 1 and UnitLevel("player") < BRACKETS[FirstBracketFor()].lv[1] and FirstBracketFor() > 1 then
      print(HEX.green .. "Evergreen:|r no " .. tostring(race) .. " starting route yet. " .. ROUTE.name .. " picks you up at level " .. BRACKETS[FirstBracketFor()].lv[1] .. " (" .. BRACKETS[FirstBracketFor()].name .. ").")
    end
    if not DB.greeted then
      DB.greeted = true
      print(HEX.green .. "The Evergreen|r loaded. " .. HEX.muted .. "/eg to open, /eg arrow to toggle the waypoint arrow.|r")
    end
  elseif event == "QUEST_TURNED_IN" then
    local questID = a1
    if completed and questID then completed[questID] = true end
    local name = QuestNameFromID(questID)
    if name then
      CDB.turnins[name] = (CDB.turnins[name] or 0) + 1
      CDB.learned[name .. "#" .. CDB.turnins[name]] = questID
    end
    C_Timer.After(1.5, RefreshCompleted)
    QueueRefresh()
  elseif event == "TAXIMAP_OPENED" then
    OnTaxiOpened()
  elseif event == "PLAYER_LEVEL_UP" then
    QueueRefresh()
    C_Timer.After(1, function()
      local b = CurrentBracket()
      if not CDB.bracket and BracketRequiredLeft(b) == 0 then
        print(HEX.green .. "Evergreen:|r bracket complete. Moving to " .. b.lv[1] .. "-" .. b.lv[2] .. " " .. b.name .. ".")
      end
    end)
  else
    QueueRefresh()
  end
end)

-- ------------------------------------------------------------------ slash commands
-- /eg itself is registered by the Evergreen core (Modules.lua), which passes guide commands here.
ns.GuideSlash = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "" or msg == "show" or msg == "toggle" then
    if UI.main:IsShown() then UI.main:Hide() else UI.main:Show() end
  elseif msg == "arrow" then
    DB.arrowShown = not DB.arrowShown; UI.UpdateArrow(true)
    print(HEX.green .. "Evergreen:|r arrow " .. (DB.arrowShown and "on" or "off"))
  elseif msg == "auto" then
    CDB.bracket = nil; UI.Refresh()
  elseif msg == "debug" then
    UI.Debug()
  elseif msg == "sync" then
    RefreshCompleted(); ScanLog()
    local b = CurrentBracket(); Recompute(b)
    local doneQ, skipped, inLog, total, noid = 0, 0, 0, 0, 0
    for _, step in ipairs(b.steps) do
      if step.q then
        total = total + 1
        if not step.qid then noid = noid + 1 end
        if step.done then doneQ = doneQ + 1 elseif step.skipped then skipped = skipped + 1 end
        if step.onQuest then inLog = inLog + 1 end
      end
    end
    local histCount = 0
    if completed then for _ in pairs(completed) do histCount = histCount + 1 end end
    print(HEX.green .. "Evergreen sync:|r " .. (completed and (histCount .. " completed quests known from the server") or "no bulk completed-quest list on this client; per-quest flags in use"))
    print(string.format("  %s: %d quest steps, %d complete, %d skipped (passed over), %d in your log, %d without a resolved id", b.name, total, doneQ, skipped, inLog, noid))
    UI.Refresh()
  elseif msg:match("^route") then
    local id = msg:match("route%s+(%S+)")
    if id == "auto" then CDB.route = nil; SelectRoute(); CDB.bracket = nil; UI.Refresh()
    elseif id then
      local found
      for _, r in ipairs(ns.ROUTES) do if r.id == id then found = r end end
      if found then CDB.route = id; SelectRoute(id); CDB.bracket = nil; UI.Refresh() else print(HEX.red .. "Evergreen:|r no route '" .. id .. "'") end
    end
    print(HEX.green .. "Evergreen routes:|r")
    for _, r in ipairs(ns.ROUTES) do print("  " .. (r == ROUTE and HEX.green .. "> " or "   ") .. r.id .. "|r  " .. r.name .. "  (" .. r.faction .. ")") end
  elseif msg == "pin" then
    DB.nativePin = not DB.nativePin
    if DB.nativePin then UI.UpdateArrow(true) else ClearNativePin() end
    print(HEX.green .. "Evergreen:|r in-world waypoint pin " .. (DB.nativePin and "on" or "off"))
  elseif msg == "flip" then
    DB.flip = not DB.flip; print(HEX.green .. "Evergreen:|r arrow direction " .. (DB.flip and "flipped" or "normal"))
  elseif msg == "lock" then
    DB.locked = not DB.locked; print(HEX.green .. "Evergreen:|r frames " .. (DB.locked and "locked" or "unlocked"))
  elseif msg == "forever" then
    DB.showForever = not DB.showForever; UI.Refresh()
  elseif msg == "next" then
    local b = BRACKETS[currentIndex]
    local step = UI.currentStep
    if step then print(HEX.green .. "Next:|r " .. StepTitle(step) .. "  " .. (StepBody(b, step) or "")) else print(HEX.green .. "Evergreen:|r bracket complete.") end
  elseif msg == "here" then
    local pm, px, py = PlayerMapPos()
    if not pm then print(HEX.green .. "Evergreen:|r no map position here (instance or unmapped area)."); return end
    local step = UI.currentStep
    print(HEX.green .. "Evergreen here:|r " .. HEX.gold .. string.format("%.1f, %.1f", px * 100, py * 100) .. "|r  " .. (MAP_NAMES[pm] or "map") .. " (uiMapID " .. pm .. ")")
    if step then
      local x, y, map = CoordOf(BRACKETS[currentIndex], step)
      print("  current step " .. HEX.ink .. FixKey(step) .. "|r " .. StepTitle(step) .. (x and (HEX.muted .. "  points at " .. string.format("%d,%d", x, y) .. " " .. (MAP_NAMES[map] or map) .. "|r") or ""))
      print("  /eg fix moves that waypoint to where you stand; /eg fix clear removes the override.")
    end
  elseif msg == "fix" or msg == "fix clear" then
    local step = UI.currentStep
    if not step then print(HEX.green .. "Evergreen:|r no current step to fix."); return end
    local k = FixKey(step)
    if msg == "fix clear" then
      DB.fixes[k] = nil
      print(HEX.green .. "Evergreen:|r override removed for " .. k .. "; back to the route's coordinates.")
    else
      local pm, px, py = PlayerMapPos()
      if not pm then print(HEX.green .. "Evergreen:|r no map position here."); return end
      DB.fixes[k] = { math.floor(px * 1000 + 0.5) / 10, math.floor(py * 1000 + 0.5) / 10, pm }
      print(HEX.green .. "Evergreen:|r " .. k .. " now points at " .. HEX.gold .. string.format("%.1f, %.1f", px * 100, py * 100) .. "|r " .. (MAP_NAMES[pm] or pm) .. ". Saved for every character. /eg fixes lists them.")
    end
    UI.Refresh()
  elseif msg == "fixes" then
    local n = 0
    for k, f in pairs(DB.fixes) do
      n = n + 1
      print("  " .. k .. " = {" .. f[1] .. ", " .. f[2] .. ", " .. f[3] .. "}  " .. HEX.muted .. (MAP_NAMES[f[3]] or "") .. "|r")
    end
    print(HEX.green .. "Evergreen:|r " .. n .. " waypoint override" .. (n == 1 and "" or "s") .. ". Key = bracket:step/phase (giver, obj, turn, or pt for travel steps). Copy them into Routes_<Race>.lua to make them permanent.")
  elseif msg == "fixes clear" then
    wipe(DB.fixes); UI.Refresh(); print(HEX.green .. "Evergreen:|r all waypoint overrides removed.")
  elseif msg:match("^scale") then
    local n = tonumber(msg:match("scale%s+([%d%.]+)"))
    if n and n > 0.4 and n < 2.5 then DB.scale = n; UI.main:SetScale(n) end
  elseif msg == "reset" then
    wipe(CDB.manual); wipe(CDB.turnins); wipe(CDB.learned); CDB.focus = nil; CDB.bracket = nil
    UI.Refresh(); print(HEX.green .. "Evergreen:|r progress reset for this character.")
  elseif msg == "resetpos" then
    DB.pos = nil; DB.arrowPos = nil
    UI.main:ClearAllPoints(); UI.main:SetPoint("CENTER", UIParent, "CENTER", 260, 40); UI.main:SetSize(420, 520)
    arrow:ClearAllPoints(); arrow:SetPoint("TOP", UIParent, "TOP", 0, -140)
  else
    print(HEX.green .. "Evergreen|r commands: /eg, /eg sync, /eg arrow, /eg pin, /eg next, /eg here, /eg fix, /eg fix clear, /eg fixes, /eg auto, /eg route <id|auto>, /eg forever, /eg flip, /eg lock, /eg scale 1.1, /eg debug, /eg reset, /eg resetpos")
  end
end
