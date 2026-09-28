-- !Everror capture: takes over the Lua error handler (chaining to Blizzard's, which still logs and
-- feeds the crash reporter), records blocked actions, and starts a session per login/reload.
local ADDON, ns = ...
local C = ns.Core

local db            -- EverrorDB once SavedVariables are loaded
local pending = {}  -- errors raised before that (only our own load, in practice)
local busy = false

-- Same level math as Blizzard's Forever handler (Blizzard_ScriptErrors GetErrorData): the stack
-- depth now, minus the depth at the time of the error, points at the frame that errored.
local function errorData()
  local level = 4
  if GetCallstackHeight and GetErrorCallstackHeight then
    local now, atError = GetCallstackHeight(), GetErrorCallstackHeight()
    if now and atError then level = now - (atError - 1) end
  end
  local stack = debugstack and debugstack(level) or ""
  local locals = debuglocals and debuglocals(level, true) or ""
  -- errors in a file's main chunk (while addons load) can leave that level past the end of the
  -- stack; take the whole stack instead (our own frames are trimmed later)
  if stack == "" and debugstack then stack = debugstack(2) or "" end
  return stack, locals
end

local function accessible(v)
  return not canaccessvalue or canaccessvalue(v)
end

local function store(err)
  err.msg = accessible(err.msg) and err.msg or "<secret message>"
  if not accessible(err.stack) then err.stack = "" end
  if not accessible(err.locals) then err.locals = "" end
  if not db then pending[#pending + 1] = err; return end
  C.Record(db, err, time())
  if ns.OnNewError then ns.OnNewError() end
end
ns.Store = store

local previous = geterrorhandler()
local function handler(msg)
  if not busy then
    busy = true
    pcall(function()
      local stack, locals = errorData()
      store({ msg = msg, stack = stack, locals = locals })
    end)
    busy = false
  end
  if previous then return previous(msg) end
end
seterrorhandler(handler)

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ADDON_ACTION_BLOCKED")
ev:RegisterEvent("ADDON_ACTION_FORBIDDEN")
ev:SetScript("OnEvent", function(_, event, a, b)
  if event == "ADDON_LOADED" and a == ADDON then
    EverrorDB = EverrorDB or {}
    db = C.Init(EverrorDB)
    if db.popupOff == nil then db.popupOff = true end
    ns.db = db
    C.NewSession(db, time())
    for _, err in ipairs(pending) do C.Record(db, err, time()) end
    pending = nil
    if ns.OnLoaded then ns.OnLoaded() end
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- a = isInitialLogin, b = isReloadingUi; later zone changes also fire this, keep the first kind
    if db and (a or b) then C.SetKind(db, b and "reload" or "login") end
  elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
    store({
      msg = ("%s tried to call the protected function '%s'"):format(tostring(a), tostring(b)),
      stack = debugstack and debugstack(2) or "",
      kind = event == "ADDON_ACTION_BLOCKED" and "blocked" or "forbidden",
    })
  end
end)
