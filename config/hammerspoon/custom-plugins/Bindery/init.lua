---@diagnostic disable: undefined-global

local M = {}

M.__index = M

M.name = "bindery"

local _utils = require("utils")

local Utils = {}

local log

---imports from utils
---can be implemented in this file if publishing as a module
local hyper = _utils.keys.hyper

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

---imports from utils
---can be implemented in this file if publishing as a module
Utils.tblDeepExtend = _utils.tblDeepExtend
Utils.keyStroke = _utils.keyStroke

---@param items string[]
---@return nil
function Utils.safeSelectMenuItem(items)
  local app = hs.application.frontmostApplication()
  local success = app:selectMenuItem(items)
  if not success then
    hs.alert.show("Menu item not found")
    log.ef("Menu item not found")
  end
end

-- ------------------------------------------------------------------
-- Types
-- ------------------------------------------------------------------

---@class Hs.Bindery.Config
---@field apps? Hs.Bindery.Config.Apps Apps configuration
---@field customBindings? table<string, Hs.Bindery.Config.CustomBindings> Custom bindings configuration
---@field contextualBindings? table<string,  Hs.Bindery.Config.ContextualBindings[]> Contextual bindings configuration
---@field watcher? Hs.Bindery.Config.Watcher Watcher configuration
---@field logLevel? string The log level to use

---@alias Hs.Bindery.Modifier "cmd"|"ctrl"|"alt"|"shift"|"fn"

---@class Hs.Bindery.Config.Apps
---@field modifier Hs.Bindery.Modifier|Hs.Bindery.Modifier[] Modifiers to use for the app launchers
---@field bindings table<string, string> App launchers

---@class Hs.Bindery.Config.CustomBindings
---@field modifier Hs.Bindery.Modifier|Hs.Bindery.Modifier[] Modifiers to use for the custom bindings
---@field key string Key to use for the custom bindings
---@field action function Action to perform for the custom bindings

---@class Hs.Bindery.Config.ContextualBindings
---@field modifier Hs.Bindery.Modifier|Hs.Bindery.Modifier[] Modifiers to use for the contextual bindings
---@field key string Key to use for the contextual bindings
---@field action function Action to perform for the contextual bindings

---@class Hs.Bindery.Config.Watcher
---@field hideAllWindowExceptFront Hs.Bindery.Config.Watcher.HideAllWindowExceptFront Whether to hide all windows except the frontmost one
---@field autoMaximizeWindow Hs.Bindery.Config.Watcher.AutoMaximizeWindow Whether to maximize the window when it is activated

---@class Hs.Bindery.Config.Watcher.Bindings
---@field modifier Hs.Bindery.Modifier|Hs.Bindery.Modifier[] Modifiers to use for the watcher bindings
---@field key string Key to use for the watcher bindings

---@class Hs.Bindery.Config.Watcher.HideAllWindowExceptFront
---@field enabled boolean Whether to hide all windows except the frontmost one
---@field bindings? Hs.Bindery.Config.Watcher.Bindings Bindings to use for the watcher hide all window except front bindings

---@class Hs.Bindery.Config.Watcher.AutoMaximizeWindow
---@field enabled boolean Whether to maximize the window when it is activated
---@field bindings? Hs.Bindery.Config.Watcher.Bindings Bindings to use for the watcher auto maximize window bindings

-- ------------------------------------------------------------------
-- Configuration
-- ------------------------------------------------------------------

---@type Hs.Bindery.Config
local default_config = {
  logLevel = "warning",
  apps = {
    modifier = hyper,
    bindings = {},
  },
  customBindings = {},
  contextualBindings = {},
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

local activeLauncherHotkeys = {}

local function setupLaunchers()
  for appName, shortcut in pairs(M.config.apps.bindings) do
    local hotkey = hs.hotkey.bind(M.config.apps.modifier, shortcut, function()
      hs.application.launchOrFocus(appName)
    end)
    table.insert(activeLauncherHotkeys, hotkey)
  end
  log.df(string.format("Initialized launcher %s hotkeys", #activeLauncherHotkeys))
end

local function clearLaunchers()
  for _, hotkey in ipairs(activeLauncherHotkeys) do
    if hotkey then
      hotkey:delete()
    end
  end
  log.df(string.format("Cleared %s launcher hotkeys", #activeLauncherHotkeys))
  activeLauncherHotkeys = {}
end

-- ------------------------------------------------------------------
-- Custom Bindings
-- ------------------------------------------------------------------

local activeCustomBindings = {}

local function setupCustomBindings()
  for _, customAction in pairs(M.config.customBindings) do
    local hotkey = hs.hotkey.bind(customAction.modifier, customAction.key, customAction.action)
    table.insert(activeCustomBindings, hotkey)
  end
  log.df(string.format("Initialized custom %s hotkeys", #activeCustomBindings))
end

local function clearCustomBindings()
  for _, customAction in ipairs(activeCustomBindings) do
    if customAction then
      customAction:delete()
    end
  end

  log.df(string.format("Cleared %s custom hotkeys", #activeCustomBindings))
  activeCustomBindings = {}
end

-- ------------------------------------------------------------------
-- Contextual Bindings
-- ------------------------------------------------------------------

-- Store active contextual hotkeys for cleanup
local activeContextualHotkeys = {}

---Function to clear all contextual bindings
---@param appName? string
---@return nil
local function clearContextualBindings(appName)
  if not appName then
    for _, hotkeys in ipairs(activeContextualHotkeys) do
      for _, hotkey in ipairs(hotkeys) do
        if hotkey then
          hotkey:delete()
        end
      end
    end
    log.df(string.format("Cleared %s contextual hotkeys", #activeContextualHotkeys))
    activeContextualHotkeys = {}
  else
    if not activeContextualHotkeys[appName] then
      log.df(string.format("No contextual hotkeys defined for: %s", appName))
      return
    end
    for _, hotkey in ipairs(activeContextualHotkeys[appName]) do
      if hotkey then
        hotkey:delete()
      end
    end
    log.df(string.format("Cleared %s contextual hotkeys", #activeContextualHotkeys[appName]))
    activeContextualHotkeys[appName] = {}
  end
end

---Function to activate contextual bindings for a specific app
---@param appName string
---@return nil
local function activateContextualBindings(appName)
  clearContextualBindings(appName)

  local bindings = M.config.contextualBindings[appName]
  if not bindings then
    log.df(string.format("No contextual bindings defined for: %s", appName))
    return
  end

  for _, binding in ipairs(bindings) do
    local hotkey = hs.hotkey.bind(binding.modifier, binding.key, binding.action)
    if not activeContextualHotkeys[appName] then
      activeContextualHotkeys[appName] = {}
    end
    table.insert(activeContextualHotkeys[appName], hotkey)
  end
  log.df(string.format("Activated %s contextual hotkeys for: %s", #activeContextualHotkeys[appName], appName))
end

-- ------------------------------------------------------------------
-- Window Watcher
-- ------------------------------------------------------------------

-- Global variable to track watcher
local _hideAllWindowExceptFrontStatus = false
local _autoMaximizeWindowStatus = false

local appWatcher = nil

local activeWatcherHotkeys = {}

local function setupWatcher()
  _hideAllWindowExceptFrontStatus = M.config.watcher.hideAllWindowExceptFront.enabled or false

  _autoMaximizeWindowStatus = M.config.watcher.autoMaximizeWindow.enabled or false

  if appWatcher then
    appWatcher:stop()
    appWatcher = nil
  end

  appWatcher = hs.application.watcher.new(function(appName, eventType)
    log.df(string.format("Watcher event: App=%s, Event=%s", appName, eventType))

    if eventType == hs.application.watcher.activated then
      log.df(string.format("App activated: %s", appName))

      activateContextualBindings(appName)

      if _hideAllWindowExceptFrontStatus then
        -- hide all windows except the frontmost one
        Utils.keyStroke({ "cmd", "alt" }, "h")
        log.df("Hide all windows except the frontmost one")
      end

      if _hideAllWindowExceptFrontStatus and _autoMaximizeWindowStatus then
        -- maximize window
        Utils.keyStroke({ "fn", "ctrl" }, "f")
        log.df("Maximize window")
      end
    end

    if eventType == hs.application.watcher.deactivated then
      log.df(string.format("App deactivated: %s", appName))
      clearContextualBindings(appName)
    end
  end)

  appWatcher:start()

  log.df("App watcher started")

  -- Bind `hideAllWindowExceptFront` toggle
  if M.config.watcher.hideAllWindowExceptFront.enabled then
    local bindings = M.config.watcher.hideAllWindowExceptFront.bindings
    if bindings and type(bindings) == "table" then
      local hotkey = hs.hotkey.bind(bindings.modifier, bindings.key, function()
        _hideAllWindowExceptFrontStatus = not _hideAllWindowExceptFrontStatus
        hs.alert.show(string.format("hideAllWindowExceptFront: %s", _hideAllWindowExceptFrontStatus))
        log.df(string.format("hideAllWindowExceptFront: %s", _hideAllWindowExceptFrontStatus))
      end)
      table.insert(activeWatcherHotkeys, hotkey)
      log.df(string.format("Initialized watcher hideAllWindowExceptFront hotkey"))
    else
      log.df("No watcher hideAllWindowExceptFront bindings defined")
    end
  end

  -- Bind `autoMaximizeWindow` toggle
  if M.config.watcher.autoMaximizeWindow.enabled then
    local bindings = M.config.watcher.autoMaximizeWindow.bindings
    if bindings and type(bindings) == "table" then
      local hotkey = hs.hotkey.bind(bindings.modifier, bindings.key, function()
        _autoMaximizeWindowStatus = not _autoMaximizeWindowStatus
        hs.alert.show(string.format("autoMaximizeWindow: %s", _autoMaximizeWindowStatus))
        log.df(string.format("autoMaximizeWindow: %s", _autoMaximizeWindowStatus))
      end)
      table.insert(activeWatcherHotkeys, hotkey)
      log.df(string.format("Initialized watcher autoMaximizeWindow hotkey"))
    else
      log.df("No watcher autoMaximizeWindow bindings defined")
    end
  end
end

local function clearWatcher()
  if appWatcher then
    appWatcher:stop()
    appWatcher = nil
    log.df("Stopped app watcher")
  end

  for _, hotkey in ipairs(activeWatcherHotkeys) do
    if hotkey then
      hotkey:delete()
    end
  end
  log.df(string.format("Cleared %s watcher hotkeys", #activeWatcherHotkeys))
  activeWatcherHotkeys = {}
end

-- ------------------------------------------------------------------
-- API
-- ------------------------------------------------------------------

---@type Hs.Bindery.Config
M.config = {}

---@param userConfig? Hs.Bindery.Config
---@return nil
function M:start(userConfig)
  print("-- Starting Bindery...")
  M.config = Utils.tblDeepExtend("force", default_config, userConfig or {})
  log = hs.logger.new(M.name, M.config.logLevel)

  setupLaunchers()
  setupCustomBindings()
  setupWatcher()
end

function M:stop()
  print("-- Stopping Bindery...")
  clearLaunchers()
  clearCustomBindings()
  clearContextualBindings()
  clearWatcher()
end

M.keyStroke = Utils.keyStroke
M.safeSelectMenuItem = Utils.safeSelectMenuItem

return M
