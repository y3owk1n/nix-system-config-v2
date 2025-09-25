return {
  name = "Bindery",
  dir = os.getenv("HOME") .. "/.hammerspoon/custom-plugins/Bindery",
  config = function()
    local keys = require("utils").keys
    local bindery = spoon.Bindery

    ---@type Hs.Bindery.Config
    local binderyConfig = {
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
            bindery.keyStroke("cmd", "space")
          end,
        },
        toggleCurrPrevApp = {
          modifier = keys.hyper,
          key = "l",
          action = function()
            bindery.keyStroke({ "cmd" }, "tab")

            hs.timer.doAfter(0.01, function()
              bindery.keyStroke({}, "return")
            end)
          end,
        },
        maximizeWindow = {
          modifier = { "ctrl", "shift" },
          key = "m",
          action = function()
            bindery.keyStroke({ "fn", "ctrl" }, "f")
          end,
        },
        moveWindow = {
          modifier = { "ctrl", "shift" },
          key = "h",
          action = function()
            bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
          end,
        },
        moveWindowRight = {
          modifier = { "ctrl", "shift" },
          key = "l",
          action = function()
            bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
          end,
        },
        moveWindowBottom = {
          modifier = { "ctrl", "shift" },
          key = "j",
          action = function()
            bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
          end,
        },
        moveWindowTop = {
          modifier = { "ctrl", "shift" },
          key = "k",
          action = function()
            bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
          end,
        },
      },
      contextualBindings = {
        ["Finder"] = {
          {
            modifier = { "cmd" },
            key = "q",
            action = function()
              bindery.keyStroke({ "cmd" }, "w")
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

    bindery:start(binderyConfig)
  end,
}
