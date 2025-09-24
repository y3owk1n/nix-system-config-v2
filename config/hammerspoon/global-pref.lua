---@diagnostic disable: undefined-global

local utils = require("utils")

local M = {}

M.__index = M

function M:init()
  print("-- Initializing global preferences...")
  hs.autoLaunch(true)
  hs.automaticallyCheckForUpdates(true)
  hs.consoleOnTop(false)
  hs.dockIcon(false)
  hs.menuIcon(true)
  hs.uploadCrashData(false)
  hs.preferencesDarkMode(true)

  hs.console.darkMode(true)
  hs.console.outputBackgroundColor({ white = 0 })
  hs.console.consolePrintColor({ white = 1 })
  hs.console.consoleResultColor({ white = 0.8 })
  hs.console.consoleCommandColor({ white = 1 })

  -- fast animation for hs windows
  hs.window.animationDuration = 0.1

  -- verbose, debug, info, warning, error, nothing
  hs.logger.defaultLogLevel = "warning"

  -- toggle console
  hs.hotkey.bind(utils.hyper, "h", function()
    hs.toggleConsole()
  end)
end

return M
