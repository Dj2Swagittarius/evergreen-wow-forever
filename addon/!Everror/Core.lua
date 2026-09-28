-- !Everror core: sessions, de-duplication, trimming and text format. Pure Lua (no WoW API), so it
-- runs in the LuaJIT tests as well as in game.
local _, ns = ...
local C = {}
ns.Core = C

local MAX_SESSIONS = 10
local MAX_ERRORS = 200     -- across all kept sessions
local MAX_STACK_LINES = 20
local MAX_LOCAL_LINES = 25
local MAX_LINE = 160
local SELF = "!Everror"

local function lines(s)
  local out = {}
  for l in ((s or "") .. "\n"):gmatch("(.-)\r?\n") do out[#out + 1] = l end
  while #out > 0 and out[#out] == "" do out[#out] = nil end
  return out
end

local function cap(l)
  if #l > MAX_LINE then return l:sub(1, MAX_LINE - 3) .. "..." end
  return l
end

function C.Init(db)
  db.sessions = db.sessions or {}
  db.nextID = db.nextID or ((db.sessions[#db.sessions] and db.sessions[#db.sessions].id or 0) + 1)
  return db
end

function C.Current(db) return db.sessions[#db.sessions] end
function C.Last(db) return db.sessions[#db.sessions - 1] end
function C.CountCurrent(db)
  local s = C.Current(db)
  return s and #s.errors or 0
end

local function total(db)
  local n = 0
  for _, s in ipairs(db.sessions) do n = n + #s.errors end
  return n
end

-- Drop whole old sessions beyond the session cap, then the oldest errors of older sessions until
-- the total fits. The current session is only trimmed by Record's own cap.
local function prune(db)
  while #db.sessions > MAX_SESSIONS do table.remove(db.sessions, 1) end
  local i = 1
  while total(db) > MAX_ERRORS and i < #db.sessions do
    local s = db.sessions[i]
    if #s.errors > 0 then table.remove(s.errors, 1) else i = i + 1 end
  end
end

function C.NewSession(db, now)
  local s = { id = db.nextID, start = now, kind = "login", errors = {} }
  db.nextID = db.nextID + 1
  db.sessions[#db.sessions + 1] = s
  prune(db)
  return s
end

function C.SetKind(db, kind)
  local s = C.Current(db)
  if s then s.kind = kind end
end

function C.AddonOf(msg, stack)
  for _, text in ipairs({ msg or "", stack or "" }) do
    for name in text:gmatch("[Aa]dd[Oo]ns[/\\]([^/\\]+)[/\\]") do
      if name ~= SELF then return name end
    end
  end
  if (msg or ""):find(SELF, 1, true) then return SELF end
  return "?"
end

function C.TrimStack(stack)
  local out, extra = {}, 0
  for _, l in ipairs(lines(stack)) do
    if not l:find(SELF, 1, true) then
      if #out < MAX_STACK_LINES then out[#out + 1] = cap(l) else extra = extra + 1 end
    end
  end
  if extra > 0 then out[#out] = out[#out] .. "\n(" .. extra .. " more lines)" end
  return table.concat(out, "\n")
end

-- Keep only top-level locals; a table local becomes "name = <table>" without its contents.
function C.TrimLocals(locals)
  local out, extra = {}, 0
  for _, l in ipairs(lines(locals)) do
    if l ~= "" and not l:find("^%s") and not l:find("^}") then
      local name = l:match("^(.-)%s*=%s*<table>")
      if name then l = name .. " = <table>" end
      if #out < MAX_LOCAL_LINES then out[#out + 1] = cap(l) else extra = extra + 1 end
    end
  end
  if extra > 0 then out[#out + 1] = "(" .. extra .. " more locals)" end
  return table.concat(out, "\n")
end

-- err = { msg, stack, locals, kind }. Returns the stored entry.
function C.Record(db, err, now)
  local s = C.Current(db) or C.NewSession(db, now)
  local msg = tostring(err.msg or "?")
  local stack = C.TrimStack(err.stack)
  local key = msg .. "\n" .. stack
  for _, e in ipairs(s.errors) do
    if e.key == key then
      e.count, e.last = e.count + 1, now
      return e
    end
  end
  local e = {
    key = key, msg = msg, stack = stack, locals = C.TrimLocals(err.locals),
    addon = C.AddonOf(msg, err.stack), kind = err.kind or "error", count = 1, first = now, last = now,
  }
  s.errors[#s.errors + 1] = e
  if #s.errors > MAX_ERRORS then
    table.remove(s.errors, 1)
    s.dropped = (s.dropped or 0) + 1
  end
  prune(db)
  return e
end

---------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------
-- WoW has no os library; its date() is the same as os.date (the tests run under plain Lua).
local date = date or os.date
local function clock(t) return t and date("%H:%M:%S", t) or "?" end

function C.FormatEntry(e)
  local when = clock(e.first) .. (e.last ~= e.first and ("-" .. clock(e.last)) or "")
  local out = { ("[x%d] %s  %s%s"):format(e.count, e.addon, when, e.kind ~= "error" and ("  (" .. e.kind .. ")") or "") }
  out[#out + 1] = "Message: " .. e.msg
  if e.stack ~= "" then out[#out + 1] = "Stack:\n" .. e.stack end
  if e.locals and e.locals ~= "" then out[#out + 1] = "Locals:\n" .. e.locals end
  return table.concat(out, "\n")
end

function C.FormatSession(s)
  if not s then return "No earlier session." end
  local n = #s.errors
  local out = { ("== Session #%d  %s  %s  (%d error%s) =="):format(s.id, date("%m-%d %H:%M", s.start or 0),
    s.kind, n, n == 1 and "" or "s") }
  if n == 0 then out[#out + 1] = "No errors." end
  for _, e in ipairs(s.errors) do out[#out + 1] = C.FormatEntry(e) end
  if s.dropped then out[#out + 1] = ("(%d more not kept)"):format(s.dropped) end
  return table.concat(out, "\n\n")
end

function C.FormatAll(db)
  local out = {}
  for _, s in ipairs(db.sessions) do out[#out + 1] = C.FormatSession(s) end
  return #out > 0 and table.concat(out, "\n\n") or "No errors recorded."
end
