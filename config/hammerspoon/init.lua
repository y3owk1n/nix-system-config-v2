---@diagnostic disable: undefined-global

local bind = hs.hotkey.bind
local launchOrFocus = hs.application.launchOrFocus
local notify = hs.alert.show
local frontmostApplication = hs.application.frontmostApplication
local doAfter = hs.timer.doAfter
local watcher = hs.application.watcher
local printf = hs.printf

local hyper = { "cmd", "alt", "ctrl", "shift" }

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

---@param mods Hs.Modifier|Hs.Modifier[]
---@param key string
---@param delay? number
---@return nil
local function keyStroke(mods, key, delay)
  hs.eventtap.keyStroke(mods, key, delay or 0)
end

---@param items string[]
---@return nil
local function safeSelectMenuItem(items)
  local app = frontmostApplication()
  local success = app:selectMenuItem(items)
  if not success then
    notify("Menu item not found")
  end
end

-- ------------------------------------------------------------------
-- Global Preferences
-- ------------------------------------------------------------------

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
bind(hyper, "h", function()
  hs.toggleConsole()
end)

-- ------------------------------------------------------------------
-- Types
-- ------------------------------------------------------------------

---@class Hs.Config
---@field apps? Hs.Config.Apps Apps configuration
---@field custom_bindings? table<string, Hs.Config.CustomBindings> Custom bindings configuration
---@field contextual_bindings? table<string,  Hs.Config.ContextualBindings[]> Contextual bindings configuration
---@field watcher? Hs.Config.Watcher Watcher configuration

---@alias Hs.Modifier "cmd"|"ctrl"|"alt"|"shift"|"fn"

---@class Hs.Config.Apps
---@field modifier Hs.Modifier|Hs.Modifier[] Modifiers to use for the app launchers
---@field bindings table<string, string> App launchers

---@class Hs.Config.CustomBindings
---@field modifier Hs.Modifier|Hs.Modifier[] Modifiers to use for the custom bindings
---@field key string Key to use for the custom bindings
---@field action function Action to perform for the custom bindings

---@class Hs.Config.ContextualBindings
---@field modifier Hs.Modifier|Hs.Modifier[] Modifiers to use for the contextual bindings
---@field key string Key to use for the contextual bindings
---@field action function Action to perform for the contextual bindings

---@class Hs.Config.Watcher
---@field hideAllWindowExceptFront Hs.Config.Watcher.HideAllWindowExceptFront Whether to hide all windows except the frontmost one
---@field autoMaximizeWindow Hs.Config.Watcher.AutoMaximizeWindow Whether to maximize the window when it is activated

---@class Hs.Config.Watcher.Bindings
---@field modifier Hs.Modifier|Hs.Modifier[] Modifiers to use for the watcher bindings
---@field key string Key to use for the watcher bindings

---@class Hs.Config.Watcher.HideAllWindowExceptFront
---@field enabled boolean Whether to hide all windows except the frontmost one
---@field bindings? Hs.Config.Watcher.Bindings Bindings to use for the watcher hide all window except front bindings

---@class Hs.Config.Watcher.AutoMaximizeWindow
---@field enabled boolean Whether to maximize the window when it is activated
---@field bindings? Hs.Config.Watcher.Bindings Bindings to use for the watcher auto maximize window bindings

-- ------------------------------------------------------------------
-- Configuration
-- ------------------------------------------------------------------

---@type Hs.Config
local config = {
  apps = {
    modifier = hyper,
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
      modifier = hyper,
      key = "return",
      action = function()
        keyStroke("cmd", "space")
      end,
    },
    toggle_curr_prev_app = {
      modifier = hyper,
      key = "l",
      action = function()
        keyStroke({ "cmd" }, "tab")

        doAfter(0.01, function()
          keyStroke({}, "return")
        end)
      end,
    },
    maximize_window = {
      modifier = { "ctrl", "shift" },
      key = "m",
      action = function()
        keyStroke({ "fn", "ctrl" }, "f")
      end,
    },
    move_window = {
      modifier = { "ctrl", "shift" },
      key = "h",
      action = function()
        safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
      end,
    },
    move_window_right = {
      modifier = { "ctrl", "shift" },
      key = "l",
      action = function()
        safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
      end,
    },
    move_window_bottom = {
      modifier = { "ctrl", "shift" },
      key = "j",
      action = function()
        safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
      end,
    },
    move_window_top = {
      modifier = { "ctrl", "shift" },
      key = "k",
      action = function()
        safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
      end,
    },
  },
  contextual_bindings = {
    ["Finder"] = {
      {
        modifier = { "cmd" },
        key = "q",
        action = function()
          keyStroke({ "cmd" }, "w")
        end,
      },
    },
  },
  watcher = {
    hideAllWindowExceptFront = {
      enabled = true,
      bindings = {
        modifier = hyper,
        key = "1",
      },
    },
    autoMaximizeWindow = {
      enabled = true,
      bindings = {
        modifier = hyper,
        key = "2",
      },
    },
  },
}

-- ------------------------------------------------------------------
-- App Launchers
-- ------------------------------------------------------------------

for appName, shortcut in pairs(config.apps.bindings) do
  bind(config.apps.modifier, shortcut, function()
    launchOrFocus(appName)
  end)
end

-- ------------------------------------------------------------------
-- Custom Bindings
-- ------------------------------------------------------------------

for _, customAction in pairs(config.custom_bindings) do
  bind(customAction.modifier, customAction.key, customAction.action)
end

-- ------------------------------------------------------------------
-- Contextual Bindings
-- ------------------------------------------------------------------

-- Store active contextual hotkeys for cleanup
local activeContextualHotkeys = {}

---Function to clear all contextual bindings
---@return nil
local function clearContextualBindings()
  for _, hotkey in ipairs(activeContextualHotkeys) do
    if hotkey then
      hotkey:delete()
    end
  end
  activeContextualHotkeys = {}
  printf("Cleared %d contextual bindings", #activeContextualHotkeys)
end

---Function to activate contextual bindings for a specific app
---@param appName string
---@return nil
local function activateContextualBindings(appName)
  clearContextualBindings()

  local bindings = config.contextual_bindings[appName]
  if not bindings then
    printf("No contextual bindings defined for: %s", appName or "Unknown")
    return
  end

  printf("Activating %d contextual bindings for: %s", #bindings, appName)

  for _, binding in ipairs(bindings) do
    local hotkey = bind(binding.modifier, binding.key, binding.action)
    table.insert(activeContextualHotkeys, hotkey)
  end
end

-- ------------------------------------------------------------------
-- Window Watcher
-- ------------------------------------------------------------------

-- Global variable to track watcher
local _appWatcher = nil

local _hideAllWindowExceptFrontStatus = config.watcher.hideAllWindowExceptFront.enabled or false

local _autoMaximizeWindowStatus = config.watcher.autoMaximizeWindow.enabled or false

---Function to create and start the watcher
---@return nil
local function startWatcher()
  -- Stop existing watcher if it exists
  if _appWatcher then
    _appWatcher:stop()
  end

  _appWatcher = watcher.new(function(appName, eventType, appObject)
    -- Wrap the entire callback in pcall to prevent crashes
    local success, error = pcall(function()
      printf("Watcher event: App=%s, Event=%d", appName or "nil", eventType or -1)

      if eventType == watcher.activated then
        printf("App activated: %s", appName or "Unknown")

        doAfter(0.1, function()
          activateContextualBindings(appName)
        end)

        if _hideAllWindowExceptFrontStatus then
          doAfter(0.1, function()
            -- hide all windows except the frontmost one
            keyStroke({ "cmd", "alt" }, "h")
          end)
        end

        if _hideAllWindowExceptFrontStatus and _autoMaximizeWindowStatus then
          doAfter(0.1, function()
            -- maximize window
            keyStroke({ "fn", "ctrl" }, "f")
          end)
        end
      end

      if eventType == watcher.deactivated then
        printf("App deactivated: %s", appName or "Unknown")
        clearContextualBindings()
      end
    end)

    if not success then
      printf("Error in watcher callback: %s", error)
      -- Restart the watcher after an error
      doAfter(1.0, startWatcher)
    end
  end)

  _appWatcher:start()
  printf("Watcher started/restarted")
end

-- Bind `hideAllWindowExceptFront` toggle
if config.watcher.hideAllWindowExceptFront.enabled then
  local bindings = config.watcher.hideAllWindowExceptFront.bindings
  if bindings and type(bindings) == "table" then
    bind(bindings.modifier, bindings.key, function()
      _hideAllWindowExceptFrontStatus = not _hideAllWindowExceptFrontStatus
      notify(string.format("hideAllWindowExceptFront: %s", _hideAllWindowExceptFrontStatus))
      printf("hideAllWindowExceptFront: %s", _hideAllWindowExceptFrontStatus)
    end)
  else
    printf("No watcher hideAllWindowExceptFront bindings defined")
  end
end

-- Bind `autoMaximizeWindow` toggle
if config.watcher.autoMaximizeWindow.enabled then
  local bindings = config.watcher.autoMaximizeWindow.bindings
  if bindings and type(bindings) == "table" then
    bind(bindings.modifier, bindings.key, function()
      _autoMaximizeWindowStatus = not _autoMaximizeWindowStatus
      notify(string.format("autoMaximizeWindow: %s", _autoMaximizeWindowStatus))
      printf("autoMaximizeWindow: %s", _autoMaximizeWindowStatus)
    end)
  else
    printf("No watcher autoMaximizeWindow bindings defined")
  end
end

-- Start the watcher initially
startWatcher()

-- Initialize contextual bindings for the currently active app
doAfter(0.5, function()
  local currentApp = frontmostApplication()
  if currentApp then
    activateContextualBindings(currentApp:name())
  end
end)
