---@diagnostic disable: undefined-global

local globalPref = require("global-pref")

-- ------------------------------------------------------------------
-- Global Preferences
-- ------------------------------------------------------------------

globalPref:init()

-- ------------------------------------------------------------------
-- Pack
-- ------------------------------------------------------------------

local packRoot = os.getenv("HOME") .. "/.local/share/hammerspoon/site/Spoons"
local packPath = packRoot .. "/Pack.spoon"
local packagePath = packRoot .. "/?.spoon/init.lua"

if not hs.fs.attributes(packPath) then
  local packRepo = "https://github.com/y3owk1n/Pack.spoon.git"
  local cmd = string.format("git clone --filter=blob:none --branch=stable '%s' '%s'", packRepo, packPath)

  local ok, _, code = os.execute(cmd)

  if not ok then
    print(string.format("Failed to remove %s: exit code %s", packPath, code or "unknown"))
  end
end

if not package.path:find(packagePath, 1, true) then
  package.path = package.path .. ";" .. packagePath
end

hs.loadSpoon("Pack")
spoon.Pack:start()
