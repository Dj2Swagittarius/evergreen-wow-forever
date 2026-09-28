-- Journal boss viewer: the Bosses tab of the dungeon journal (Journal.lua).
--
-- A row of boss buttons; the selected boss is shown as a 3D model (drag to turn, mouse wheel to
-- zoom), with its level, description and loot underneath.

local ADDON, ns = ...
local J = ns.Journal
if not J then return end

local MODEL_H = 240

local function Model()
  if J.model then return J.model end
  local m = CreateFrame("PlayerModel", nil, J.child)
  m:SetHeight(MODEL_H)
  m.bg = m:CreateTexture(nil, "BACKGROUND"); m.bg:SetAllPoints(); m.bg:SetColorTexture(0, 0, 0, 0.35)
  m.msg = ns.Skin.Text(m, "GameFontDisable", "CENTER"); m.msg:SetPoint("CENTER")
  m.hint = ns.Skin.Text(m, "GameFontDisableSmall", "RIGHT"); m.hint:SetPoint("BOTTOMRIGHT", -6, 4)
  m.hint:SetText("drag to turn  ·  wheel to zoom")
  m:EnableMouse(true); m:EnableMouseWheel(true)
  m.facing, m.zoom = 0, 1
  m:SetScript("OnMouseDown", function(s) s.dragX = GetCursorPosition() end)
  m:SetScript("OnMouseUp", function(s) s.dragX = nil end)
  m:SetScript("OnHide", function(s) s.dragX = nil end)
  m:SetScript("OnUpdate", function(s)
    if not s.dragX then return end
    local x = GetCursorPosition()
    s.facing = s.facing + (x - s.dragX) / 80
    s.dragX = x
    s:SetFacing(s.facing)
  end)
  m:SetScript("OnMouseWheel", function(s, d)
    s.zoom = math.max(0.4, math.min(2.5, s.zoom - d * 0.1))
    if s.SetCamDistanceScale then s:SetCamDistanceScale(s.zoom) end
  end)
  J.model = m
  table.insert(J.extras, m)
  return m
end

-- The client may not have the creature cached: SetCreature asks the server, so check back a few
-- times before calling it unavailable.
local function ShowCreature(m, key, npc)
  m.key, m.npc, m.tries = key, npc, 0
  m.msg:SetText("")
  if m.ClearModel then m:ClearModel() end
  if not npc then m.msg:SetText(J.HEX.muted .. "No model for this entry|r"); return end
  local function try()
    if m.key ~= key then return end
    m.tries = m.tries + 1
    m:SetCreature(npc)
    m:SetFacing(m.facing)
    if m.SetCamDistanceScale then m:SetCamDistanceScale(m.zoom) end
    local fid = m.GetModelFileID and m:GetModelFileID()
    if fid and fid ~= 0 then return end
    if m.tries < 4 then C_Timer.After(0.5, try) else m.msg:SetText(J.HEX.muted .. "Model not available in this client|r") end
  end
  try()
end

function J.DrawBosses(d, y)
  local HEX = J.HEX
  local bosses = d.bosses or {}
  J.bossButtons = {}
  if #bosses == 0 then
    local t = J.GetText(); t:SetPoint("TOPLEFT", 4, y); t:SetText(HEX.muted .. "Bosses not known yet.|r")
    return y - 18
  end
  local idx = math.min(J.bossIdx or 1, #bosses)
  J.bossIdx = idx

  -- boss buttons, wrapping onto more rows
  local x, maxW = 4, J.child:GetWidth() - 8
  for i, boss in ipairs(bosses) do
    local b = J.GetSmallButton(boss.name or "?")
    local w = math.max(60, #(boss.name or "?") * 7 + 20)
    b:SetWidth(w)
    if x > 4 and x + w > maxW then x = 4; y = y - 24 end
    b:SetPoint("TOPLEFT", x, y)
    if i == idx then b:LockHighlight() else b:UnlockHighlight() end
    b:SetScript("OnClick", function() J.bossIdx = i; J.RefreshContent() end)
    J.bossButtons[i] = b
    x = x + w + 4
  end
  y = y - 30

  -- the model; reloaded only when the selected boss changes
  local boss = bosses[idx]
  local m = Model()
  m:ClearAllPoints()
  m:SetPoint("TOPLEFT", 4, y)
  m:SetPoint("RIGHT", J.child, "RIGHT", -4, 0)
  m:Show()
  local key = d.key .. ":" .. idx
  if m.key ~= key then ShowCreature(m, key, boss.npc) end
  y = y - MODEL_H - 8

  -- info
  local t = J.GetText()
  t:SetPoint("TOPLEFT", 4, y)
  t:SetFont("Fonts\\FRIZQT__.TTF", 15, "")
  t:SetText(HEX.gold .. (boss.name or "?") .. "|r" .. (boss.rare and (HEX.muted .. "  rare|r") or "")
    .. (boss.level and (HEX.muted .. "  level " .. boss.level .. "|r") or ""))
  y = y - 24
  if boss.desc then
    local dsc = J.GetText()
    dsc:SetPoint("TOPLEFT", 4, y)
    dsc:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    dsc:SetText(HEX.muted .. boss.desc .. "|r")
    y = y - dsc:GetStringHeight() - 6
  end
  return J.DrawItems(d, boss, y) - 8
end
