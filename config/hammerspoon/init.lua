---@diagnostic disable: undefined-global

local utils = require("utils")
local global_pref = require("global-pref")
local app_watcher = require("app-watcher")
local system = require("system")
local vimium = require("vimium")

-- ------------------------------------------------------------------
-- Global Preferences
-- ------------------------------------------------------------------

global_pref.setup()

-- ------------------------------------------------------------------
-- App Watcher
-- ------------------------------------------------------------------

local app_watcher_config = {}

app_watcher.setup(app_watcher_config)

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
        system.key_stroke("cmd", "space")
      end,
    },
    toggle_curr_prev_app = {
      modifier = utils.hyper,
      key = "l",
      action = function()
        system.key_stroke({ "cmd" }, "tab")

        hs.timer.doAfter(0.01, function()
          system.key_stroke({}, "return")
        end)
      end,
    },
    maximize_window = {
      modifier = { "ctrl", "shift" },
      key = "m",
      action = function()
        system.key_stroke({ "fn", "ctrl" }, "f")
      end,
    },
    move_window = {
      modifier = { "ctrl", "shift" },
      key = "h",
      action = function()
        system.safe_select_menu_item({ "Window", "Move & Resize", "Left" })
      end,
    },
    move_window_right = {
      modifier = { "ctrl", "shift" },
      key = "l",
      action = function()
        system.safe_select_menu_item({ "Window", "Move & Resize", "Right" })
      end,
    },
    move_window_bottom = {
      modifier = { "ctrl", "shift" },
      key = "j",
      action = function()
        system.safe_select_menu_item({ "Window", "Move & Resize", "Bottom" })
      end,
    },
    move_window_top = {
      modifier = { "ctrl", "shift" },
      key = "k",
      action = function()
        system.safe_select_menu_item({ "Window", "Move & Resize", "Top" })
      end,
    },
  },
  contextual_bindings = {
    ["Finder"] = {
      {
        modifier = { "cmd" },
        key = "q",
        action = function()
          system.key_stroke({ "cmd" }, "w")
        end,
      },
    },
  },
  watcher = {
    hide_all_window_except_front = {
      enabled = true,
      bindings = {
        modifier = utils.hyper,
        key = "1",
      },
    },
    auto_maximize_window = {
      enabled = true,
      bindings = {
        modifier = utils.hyper,
        key = "2",
      },
    },
  },
}

system.setup(system_config)

-- ------------------------------------------------------------------
-- Vimium
-- ------------------------------------------------------------------

---@type Hs.Vimium.Config
---@diagnostic disable-next-line: missing-fields
local vimium_config = {
  excluded_apps = {
    "Terminal",
    "Ghostty",
    "Screen Sharing",
    "RustDesk",
  },
}

vimium.setup(vimium_config)
