---@diagnostic disable: undefined-global

local globalPref = require("global-pref")
local system = require("system")
local vimnav = require("vimnav")
local keys = require("utils").keys

-- ------------------------------------------------------------------
-- Global Preferences
-- ------------------------------------------------------------------

globalPref:init()

-- ------------------------------------------------------------------
-- System
-- ------------------------------------------------------------------

---@type Hs.System.Config
local systemConfig = {
  apps = {
    modifier = keys.hyper,
    bindings = {
      ["Safari"] = "b",
      ["Ghostty"] = "t",
      ["Notes"] = "n",
      ["Mail"] = "m",
      ["WhatsApp"] = "w",
      ["Finder"] = "f",
      ["System Settings"] = "s",
      ["Passwords"] = "p",
    },
  },
  customBindings = {
    spotlightRemap = {
      modifier = keys.hyper,
      key = "return",
      action = function()
        system.keyStroke("cmd", "space")
      end,
    },
    toggleCurrPrevApp = {
      modifier = keys.hyper,
      key = "l",
      action = function()
        system.keyStroke({ "cmd" }, "tab")

        hs.timer.doAfter(0.01, function()
          system.keyStroke({}, "return")
        end)
      end,
    },
    maximizeWindow = {
      modifier = { "ctrl", "shift" },
      key = "m",
      action = function()
        system.keyStroke({ "fn", "ctrl" }, "f")
      end,
    },
    moveWindow = {
      modifier = { "ctrl", "shift" },
      key = "h",
      action = function()
        system.safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
      end,
    },
    moveWindowRight = {
      modifier = { "ctrl", "shift" },
      key = "l",
      action = function()
        system.safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
      end,
    },
    moveWindowBottom = {
      modifier = { "ctrl", "shift" },
      key = "j",
      action = function()
        system.safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
      end,
    },
    moveWindowTop = {
      modifier = { "ctrl", "shift" },
      key = "k",
      action = function()
        system.safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
      end,
    },
  },
  contextualBindings = {
    ["Finder"] = {
      {
        modifier = { "cmd" },
        key = "q",
        action = function()
          system.keyStroke({ "cmd" }, "w")
        end,
      },
    },
  },
  watcher = {
    hideAllWindowExceptFront = {
      enabled = true,
      bindings = {
        modifier = keys.hyper,
        key = "1",
      },
    },
    autoMaximizeWindow = {
      enabled = true,
      bindings = {
        modifier = keys.hyper,
        key = "2",
      },
    },
  },
}

system:init(systemConfig)
system:start()

-- ------------------------------------------------------------------
-- Vimium
-- ------------------------------------------------------------------

---@type Hs.Vimnav.Config
---@diagnostic disable-next-line: missing-fields
local vimnavConfig = {
  excludedApps = {
    "Terminal",
    "Ghostty",
    "Screen Sharing",
    "RustDesk",
  },
}

vimnav:init(vimnavConfig)
vimnav:start()
