---@diagnostic disable: undefined-global

local utils = require("utils")

local M = {}

M.__index = M

function M.setup()
  hs.autoLaunch(true)
  hs.automaticallyCheckForUpdates(true)
  hs.consoleOnTop(false)
  hs.dockIcon(false)
  hs.menuIcon(true)
  hs.uploadCrashData(false)
  hs.preferencesDarkMode(true)

  -- verbose, debug, info, warning, error, nothing
  hs.logger.defaultLogLevel = "warning"

  -- toggle console
  hs.hotkey.bind(utils.hyper, "h", function()
    hs.toggleConsole()
  end)
end

return M
