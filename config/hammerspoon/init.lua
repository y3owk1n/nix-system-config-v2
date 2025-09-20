---@diagnostic disable: undefined-global

local bind = hs.hotkey.bind
local launchOrFocus = hs.application.launchOrFocus
local notify = hs.alert.show
local frontmostApplication = hs.application.frontmostApplication
local doAfter = hs.timer.doAfter

local hyper = { "cmd", "alt", "ctrl", "shift" }

local keyStroke = function(mods, key, delay)
  hs.eventtap.keyStroke(mods, key, delay or 0)
end

-- ------------------------------------------------------------------
-- Launcher
-- ------------------------------------------------------------------

local apps = {
  ["Safari"] = "b",
  ["Ghostty"] = "t",
  ["Notes"] = "n",
  ["Mail"] = "m",
  ["WhatsApp"] = "w",
  ["Finder"] = "f",
  ["System Settings"] = "s",
  ["Passwords"] = "p",
}

for appName, shortcut in pairs(apps) do
  bind(hyper, shortcut, function()
    launchOrFocus(appName)
  end)
end

-- ------------------------------------------------------------------
-- Remaps
-- ------------------------------------------------------------------

-- Spotlight
bind(hyper, "return", function()
  keyStroke("cmd", "space")
end)

-- ------------------------------------------------------------------
-- Toggle Current Previous App
-- ------------------------------------------------------------------

bind(hyper, "l", function()
  keyStroke({ "cmd" }, "tab")

  doAfter(0.01, function()
    keyStroke({}, "return")
  end)
end)

-- ------------------------------------------------------------------
-- Window Management
-- ------------------------------------------------------------------

-- Maximize window
bind({ "ctrl", "shift" }, "m", function()
  keyStroke({ "fn", "ctrl" }, "f")
end)

local function safeSelectMenuItem(items)
  local app = frontmostApplication()
  local success = app:selectMenuItem(items)
  if not success then
    notify("Menu item not found")
  end
end

-- Move window to left
bind({ "ctrl", "shift" }, "h", function()
  safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
end)

-- Move window to right
bind({ "ctrl", "shift" }, "l", function()
  safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
end)

-- Move window to bottom
bind({ "ctrl", "shift" }, "j", function()
  safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
end)

-- Move window to top
bind({ "ctrl", "shift" }, "k", function()
  safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
end)

-- ------------------------------------------------------------------
-- Window Watcher
-- ------------------------------------------------------------------

local wf = hs.window.filter.new(nil) -- nil = all apps

wf:subscribe({
  hs.window.filter.windowUnfocused,
}, function(win, appName, event)
  -- hide all windows except the frontmost one
  hs.eventtap.keyStroke({ "cmd", "alt" }, "h", 0)
end)
