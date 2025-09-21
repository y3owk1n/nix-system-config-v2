---@diagnostic disable: undefined-global

local utils = require("utils")

local M = {}

M.__index = M

local bind = hs.hotkey.bind
local launchOrFocus = hs.application.launchOrFocus
local notify = hs.alert.show
local frontmostApplication = hs.application.frontmostApplication
local doAfter = hs.timer.doAfter
local watcher = hs.application.watcher
local printf = hs.printf

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

---@param mods Hs.System.Modifier|Hs.System.Modifier[]
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
-- Types
-- ------------------------------------------------------------------

---@class Hs.System.Config
---@field apps? Hs.System.Config.Apps Apps configuration
---@field custom_bindings? table<string, Hs.System.Config.CustomBindings> Custom bindings configuration
---@field contextual_bindings? table<string,  Hs.System.Config.ContextualBindings[]> Contextual bindings configuration
---@field watcher? Hs.System.Config.Watcher Watcher configuration

---@alias Hs.System.Modifier "cmd"|"ctrl"|"alt"|"shift"|"fn"

---@class Hs.System.Config.Apps
---@field modifier Hs.System.Modifier|Hs.System.Modifier[] Modifiers to use for the app launchers
---@field bindings table<string, string> App launchers

---@class Hs.System.Config.CustomBindings
---@field modifier Hs.System.Modifier|Hs.System.Modifier[] Modifiers to use for the custom bindings
---@field key string Key to use for the custom bindings
---@field action function Action to perform for the custom bindings

---@class Hs.System.Config.ContextualBindings
---@field modifier Hs.System.Modifier|Hs.System.Modifier[] Modifiers to use for the contextual bindings
---@field key string Key to use for the contextual bindings
---@field action function Action to perform for the contextual bindings

---@class Hs.System.Config.Watcher
---@field hideAllWindowExceptFront Hs.System.Config.Watcher.HideAllWindowExceptFront Whether to hide all windows except the frontmost one
---@field autoMaximizeWindow Hs.System.Config.Watcher.AutoMaximizeWindow Whether to maximize the window when it is activated

---@class Hs.System.Config.Watcher.Bindings
---@field modifier Hs.System.Modifier|Hs.System.Modifier[] Modifiers to use for the watcher bindings
---@field key string Key to use for the watcher bindings

---@class Hs.System.Config.Watcher.HideAllWindowExceptFront
---@field enabled boolean Whether to hide all windows except the frontmost one
---@field bindings? Hs.System.Config.Watcher.Bindings Bindings to use for the watcher hide all window except front bindings

---@class Hs.System.Config.Watcher.AutoMaximizeWindow
---@field enabled boolean Whether to maximize the window when it is activated
---@field bindings? Hs.System.Config.Watcher.Bindings Bindings to use for the watcher auto maximize window bindings

-- ------------------------------------------------------------------
-- Configuration
-- ------------------------------------------------------------------

---@type Hs.System.Config
local default_config = {
  apps = {
    modifier = utils.hyper,
    bindings = {},
  },
  custom_bindings = {},
  contextual_bindings = {},
  watcher = {
    hideAllWindowExceptFront = {
      enabled = false,
    },
    autoMaximizeWindow = {
      enabled = false,
    },
  },
}

-- ------------------------------------------------------------------
-- App Launchers
-- ------------------------------------------------------------------

local function setup_launchers()
  for appName, shortcut in pairs(M.config.apps.bindings) do
    bind(M.config.apps.modifier, shortcut, function()
      launchOrFocus(appName)
    end)
  end
end

-- ------------------------------------------------------------------
-- Custom Bindings
-- ------------------------------------------------------------------

local function setup_custom_bindings()
  for _, customAction in pairs(M.config.custom_bindings) do
    bind(customAction.modifier, customAction.key, customAction.action)
  end
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

  local bindings = M.config.contextual_bindings[appName]
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

local function setup_watcher()
  -- Global variable to track watcher
  local _appWatcher = nil

  local _hideAllWindowExceptFrontStatus = M.config.watcher.hideAllWindowExceptFront.enabled or false

  local _autoMaximizeWindowStatus = M.config.watcher.autoMaximizeWindow.enabled or false

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
  if M.config.watcher.hideAllWindowExceptFront.enabled then
    local bindings = M.config.watcher.hideAllWindowExceptFront.bindings
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
  if M.config.watcher.autoMaximizeWindow.enabled then
    local bindings = M.config.watcher.autoMaximizeWindow.bindings
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
end

-- ------------------------------------------------------------------
-- API
-- ------------------------------------------------------------------

---@type Hs.System.Config
M.config = {}

---@param user_config? Hs.System.Config
---@return nil
function M.setup(user_config)
  M.config = utils.tbl_deep_extend("force", default_config, user_config or {})

  setup_launchers()
  setup_custom_bindings()

  setup_watcher()
end

M.keyStroke = keyStroke
M.safeSelectMenuItem = safeSelectMenuItem

return M
