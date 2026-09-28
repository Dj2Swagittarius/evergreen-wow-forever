-- Reads and writes of this addon's namespace go to the Evergreen core's shared namespace, so every
-- file here keeps `local ADDON, ns = ...` (ADDON is this addon's own name). See Evergreen/Modules.lua.
local _, ns = ...
setmetatable(ns, { __index = EvergreenNS, __newindex = EvergreenNS })
