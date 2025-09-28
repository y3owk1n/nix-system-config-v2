---@diagnostic disable: undefined-global

local globalPref = require("global-pref")
local installSpoon = require("utils").installSpoon

-- ------------------------------------------------------------------
-- Global Preferences
-- ------------------------------------------------------------------

globalPref:init()

-- ------------------------------------------------------------------
-- Pack
-- ------------------------------------------------------------------

_G.k92 = {}
_G.k92.packRoot = os.getenv("HOME") .. "/.local/share/hammerspoon/site/Spoons"
_G.k92.packagePath = _G.k92.packRoot .. "/?.spoon/init.lua"

if not package.path:find(_G.k92.packagePath, 1, true) then
  package.path = package.path .. ";" .. _G.k92.packagePath
end

-- ------------------------------------------------------------------
-- Vimnav
-- ------------------------------------------------------------------

installSpoon("Vimnav", "https://github.com/y3owk1n/vimnav.spoon.git", false, function(mod)
  local vimnavConfig = {
    excludedApps = {
      "Terminal",
      "Ghostty",
      "Screen Sharing",
      "RustDesk",
    },
  }

  mod:start(vimnavConfig)
end)

-- ------------------------------------------------------------------
-- Bindery
-- ------------------------------------------------------------------

installSpoon("Bindery", "https://github.com/y3owk1n/bindery.spoon.git", false, function(mod)
  local binderyConfig = {
    apps = {
      modifier = mod.specialModifiers.hyper,
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
        modifier = mod.specialModifiers.hyper,
        key = "return",
        action = function()
          mod.keyStroke("cmd", "space")
        end,
      },
      toggleCurrPrevApp = {
        modifier = mod.specialModifiers.hyper,
        key = "l",
        action = function()
          mod.keyStroke({ "cmd" }, "tab")

          hs.timer.doAfter(0.01, function()
            mod.keyStroke({}, "return")
          end)
        end,
      },
      maximizeWindow = {
        modifier = { "ctrl", "shift" },
        key = "m",
        action = function()
          mod.keyStroke({ "fn", "ctrl" }, "f")
        end,
      },
      moveWindow = {
        modifier = { "ctrl", "shift" },
        key = "h",
        action = function()
          mod.safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
        end,
      },
      moveWindowRight = {
        modifier = { "ctrl", "shift" },
        key = "l",
        action = function()
          mod.safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
        end,
      },
      moveWindowBottom = {
        modifier = { "ctrl", "shift" },
        key = "j",
        action = function()
          mod.safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
        end,
      },
      moveWindowTop = {
        modifier = { "ctrl", "shift" },
        key = "k",
        action = function()
          mod.safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
        end,
      },
    },
    contextualBindings = {
      ["Finder"] = {
        {
          modifier = { "cmd" },
          key = "q",
          action = function()
            mod.keyStroke({ "cmd" }, "w")
          end,
        },
      },
    },
    watcher = {
      hideAllWindowExceptFront = {
        enabled = true,
        bindings = {
          modifier = mod.specialModifiers.hyper,
          key = "1",
        },
      },
      autoMaximizeWindow = {
        enabled = true,
        bindings = {
          modifier = mod.specialModifiers.hyper,
          key = "2",
        },
      },
    },
  }

  mod:start(binderyConfig)
end)
