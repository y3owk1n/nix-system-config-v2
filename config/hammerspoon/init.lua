---@diagnostic disable: undefined-global

local globalPref = require("global-pref")
local pack = require("pack")

-- ------------------------------------------------------------------
-- Global Preferences
-- ------------------------------------------------------------------

globalPref:init()

-- ------------------------------------------------------------------
-- Pack
-- ------------------------------------------------------------------

pack:init({
  dir = os.getenv("HOME") .. "/.hammerspoon/pack",
  config = {
    auto_install = true,
    auto_cleanup = true,
  },
})
