---@diagnostic disable: undefined-global

local globalPref = require("global-pref")
local spoonUtils = require("spoon-utils")

-- ------------------------------------------------------------------
-- Global Preferences
-- ------------------------------------------------------------------

globalPref:init()

-- ------------------------------------------------------------------
-- Vimnav
-- ------------------------------------------------------------------

spoonUtils.install({
  name = "Vimnav",
  github = "https://github.com/y3owk1n/vimnav.spoon.git",
  local_path = os.getenv("HOME") .. "/Dev/vimnav.spoon",
  -- force = true,
  -- dev = true,
}, function(mod)
  local vimnavConfig = {
    hints = {
      textFont = "JetBrainsMonoNLNFP-ExtraBold",
    },
    applicationGroups = {
      exclusions = {
        "Terminal",
        "Ghostty",
        "Screen Sharing",
        "RustDesk",
        "Adobe Photoshop 2025",
        "Adobe Illustrator 2025",
      },
    },
    mapping = {
      insertNormal = {
        ["H"] = {
          description = "Move to beginning of line",
          action = { "cmd", "left" },
        },
        ["L"] = {
          description = "Move to end of line",
          action = { "cmd", "right" },
        },
      },
      insertVisual = {
        ["H"] = {
          description = "Move to beginning of line",
          action = { { "shift", "cmd" }, "left" },
        },
        ["L"] = {
          description = "Move to end of line",
          action = { { "shift", "cmd" }, "right" },
        },
      },
    },
    menubar = {
      enabled = false,
    },
    overlay = {
      enabled = true,
      textFont = "JetBrainsMonoNLNFP-ExtraBold",
    },
    whichkey = {
      enabled = true,
      textFont = "JetBrainsMonoNLNFP-ExtraBold",
    },
    enhancedAccessibility = {
      enableForChromium = false,
      enableForElectron = false,
    },
  }

  mod:configure(vimnavConfig):start()
end)

-- ------------------------------------------------------------------
-- Bindery
-- ------------------------------------------------------------------

spoonUtils.install({
  name = "Bindery",
  github = "https://github.com/y3owk1n/bindery.spoon.git",
  local_path = os.getenv("HOME") .. "/Dev/bindery.spoon",
  -- force = true,
  -- dev = true,
}, function(mod)
  local binderyConfig = {
    apps = {
      modifier = mod.specialModifiers.hyper,
      bindings = {
        ["Safari"] = "b",
        ["Ghostty"] = "t",
        ["Notes"] = "n",
        ["Mail"] = "m",
        ["Calendar"] = "c",
        ["WhatsApp"] = "w",
        ["Finder"] = "f",
        ["System Settings"] = "s",
        ["Passwords"] = "p",
        ["Activity Monitor"] = "a",
      },
    },
    customBindings = {
      -- spotlightRemap = {
      --   modifier = mod.specialModifiers.hyper,
      --   key = "return",
      --   action = function()
      --     mod.keyStroke("cmd", "space")
      --   end,
      -- },
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
        modifier = { "alt", "shift" },
        key = "m",
        action = function()
          mod.keyStroke({ "fn", "ctrl" }, "f")
        end,
      },
      moveWindow = {
        modifier = { "alt", "shift" },
        key = "h",
        action = function()
          mod.safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
        end,
      },
      moveWindowRight = {
        modifier = { "alt", "shift" },
        key = "l",
        action = function()
          mod.safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
        end,
      },
      moveWindowBottom = {
        modifier = { "alt", "shift" },
        key = "j",
        action = function()
          mod.safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
        end,
      },
      moveWindowTop = {
        modifier = { "alt", "shift" },
        key = "k",
        action = function()
          mod.safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
        end,
      },
      focusRight = {
        modifier = { "alt" },
        key = "l",
        action = function()
          hs.window.frontmostWindow():focusWindowEast(hs.window.visibleWindows(), true, true)
        end,
      },
      focusLeft = {
        modifier = { "alt" },
        key = "h",
        action = function()
          hs.window.frontmostWindow():focusWindowWest(hs.window.visibleWindows(), true, true)
        end,
      },
      focusBottom = {
        modifier = { "alt" },
        key = "j",
        action = function()
          hs.window.frontmostWindow():focusWindowSouth(hs.window.visibleWindows(), true, true)
        end,
      },
      focusTop = {
        modifier = { "alt" },
        key = "k",
        action = function()
          hs.window.frontmostWindow():focusWindowNorth(hs.window.visibleWindows(), true, true)
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

  mod:configure(binderyConfig):start()
end)
