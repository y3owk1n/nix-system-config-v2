---@diagnostic disable: undefined-global

local utils = require("utils")
local global_pref = require("global-pref")
local system = require("system")

-- ------------------------------------------------------------------
-- Global Preferences
-- ------------------------------------------------------------------

global_pref.setup()

-- ------------------------------------------------------------------
-- System
-- ------------------------------------------------------------------

---@type Hs.System.Config
local system_config = {
  apps = {
    modifier = utils.hyper,
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
  custom_bindings = {
    spotlight_remap = {
      modifier = utils.hyper,
      key = "return",
      action = function()
        system.keyStroke("cmd", "space")
      end,
    },
    toggle_curr_prev_app = {
      modifier = utils.hyper,
      key = "l",
      action = function()
        system.keyStroke({ "cmd" }, "tab")

        hs.timer.doAfter(0.01, function()
          system.keyStroke({}, "return")
        end)
      end,
    },
    maximize_window = {
      modifier = { "ctrl", "shift" },
      key = "m",
      action = function()
        system.keyStroke({ "fn", "ctrl" }, "f")
      end,
    },
    move_window = {
      modifier = { "ctrl", "shift" },
      key = "h",
      action = function()
        system.safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
      end,
    },
    move_window_right = {
      modifier = { "ctrl", "shift" },
      key = "l",
      action = function()
        system.safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
      end,
    },
    move_window_bottom = {
      modifier = { "ctrl", "shift" },
      key = "j",
      action = function()
        system.safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
      end,
    },
    move_window_top = {
      modifier = { "ctrl", "shift" },
      key = "k",
      action = function()
        system.safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
      end,
    },
  },
  contextual_bindings = {
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
        modifier = utils.hyper,
        key = "1",
      },
    },
    autoMaximizeWindow = {
      enabled = true,
      bindings = {
        modifier = utils.hyper,
        key = "2",
      },
    },
  },
}

system.setup(system_config)
