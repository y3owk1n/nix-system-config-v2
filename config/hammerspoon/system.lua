---@diagnostic disable: undefined-global

local utils = require("utils")

local M = {}

M.__index = M

M.mod_name = "system"

local log

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

---@param mods Hs.System.Modifier|Hs.System.Modifier[]
---@param key string
---@param delay? number
---@return nil
local function key_stroke(mods, key, delay)
  hs.eventtap.keyStroke(mods, key, delay or 0)
end

---@param items string[]
---@return nil
local function safe_select_menu_item(items)
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

---@class Hs.System.Config
---@field apps? Hs.System.Config.Apps Apps configuration
---@field custom_bindings? table<string, Hs.System.Config.CustomBindings> Custom bindings configuration
---@field contextual_bindings? table<string,  Hs.System.Config.ContextualBindings[]> Contextual bindings configuration
---@field watcher? Hs.System.Config.Watcher Watcher configuration
---@field log_level? string The log level to use

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
---@field hide_all_window_except_front Hs.System.Config.Watcher.HideAllWindowExceptFront Whether to hide all windows except the frontmost one
---@field auto_maximize_window Hs.System.Config.Watcher.AutoMaximizeWindow Whether to maximize the window when it is activated

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
  log_level = "warning",
  apps = {
    modifier = utils.hyper,
    bindings = {},
  },
  custom_bindings = {},
  contextual_bindings = {},
  watcher = {
    hide_all_window_except_front = {
      enabled = false,
    },
    auto_maximize_window = {
      enabled = false,
    },
  },
}

-- ------------------------------------------------------------------
-- App Launchers
-- ------------------------------------------------------------------

local active_launcher_hotkeys = {}

local function setup_launchers()
  for appName, shortcut in pairs(M.config.apps.bindings) do
    local hotkey = hs.hotkey.bind(M.config.apps.modifier, shortcut, function()
      hs.application.launchOrFocus(appName)
    end)
    table.insert(active_launcher_hotkeys, hotkey)
  end
  log.df(string.format("Initialized launcher %s hotkeys", #active_launcher_hotkeys))
end

local function clear_launchers()
  for _, hotkey in ipairs(active_launcher_hotkeys) do
    if hotkey then
      hotkey:delete()
    end
  end
  log.df(string.format("Cleared %s launcher hotkeys", #active_launcher_hotkeys))
  active_launcher_hotkeys = {}
end

-- ------------------------------------------------------------------
-- Custom Bindings
-- ------------------------------------------------------------------

local active_custom_bindings = {}

local function setup_custom_bindings()
  for _, custom_action in pairs(M.config.custom_bindings) do
    local hotkey = hs.hotkey.bind(custom_action.modifier, custom_action.key, custom_action.action)
    table.insert(active_custom_bindings, hotkey)
  end
  log.df(string.format("Initialized custom %s hotkeys", #active_custom_bindings))
end

local function clear_custom_bindings()
  for _, custom_action in ipairs(active_custom_bindings) do
    if custom_action then
      custom_action:delete()
    end
  end

  log.df(string.format("Cleared %s custom hotkeys", #active_custom_bindings))
  active_custom_bindings = {}
end

-- ------------------------------------------------------------------
-- Contextual Bindings
-- ------------------------------------------------------------------

-- Store active contextual hotkeys for cleanup
local active_contextual_hotkeys = {}

---Function to clear all contextual bindings
---@param app_name? string
---@return nil
local function clear_contextual_bindings(app_name)
  if not app_name then
    for _, hotkeys in ipairs(active_contextual_hotkeys) do
      for _, hotkey in ipairs(hotkeys) do
        if hotkey then
          hotkey:delete()
        end
      end
    end
    log.df(string.format("Cleared %s contextual hotkeys", #active_contextual_hotkeys))
    active_contextual_hotkeys = {}
  else
    if not active_contextual_hotkeys[app_name] then
      log.df(string.format("No contextual hotkeys defined for: %s", app_name))
      return
    end
    for _, hotkey in ipairs(active_contextual_hotkeys[app_name]) do
      if hotkey then
        hotkey:delete()
      end
    end
    log.df(string.format("Cleared %s contextual hotkeys", #active_contextual_hotkeys[app_name]))
    active_contextual_hotkeys[app_name] = {}
  end
end

---Function to activate contextual bindings for a specific app
---@param app_name string
---@return nil
local function activate_contextual_bindings(app_name)
  clear_contextual_bindings(app_name)

  local bindings = M.config.contextual_bindings[app_name]
  if not bindings then
    log.df(string.format("No contextual bindings defined for: %s", app_name))
    return
  end

  for _, binding in ipairs(bindings) do
    local hotkey = hs.hotkey.bind(binding.modifier, binding.key, binding.action)
    if not active_contextual_hotkeys[app_name] then
      active_contextual_hotkeys[app_name] = {}
    end
    table.insert(active_contextual_hotkeys[app_name], hotkey)
  end
  log.df(string.format("Activated %s contextual hotkeys for: %s", #active_contextual_hotkeys[app_name], app_name))
end

-- ------------------------------------------------------------------
-- Window Watcher
-- ------------------------------------------------------------------

-- Global variable to track watcher
local _hide_all_window_except_front_status = false
local _auto_maximize_window_status = false

local app_watcher = nil

local active_watcher_hotkeys = {}

local function setup_watcher()
  _hide_all_window_except_front_status = M.config.watcher.hide_all_window_except_front.enabled or false

  _auto_maximize_window_status = M.config.watcher.auto_maximize_window.enabled or false

  if app_watcher then
    app_watcher:stop()
    app_watcher = nil
  end

  app_watcher = hs.application.watcher.new(function(app_name, event_type)
    log.df(string.format("Watcher event: App=%s, Event=%s", app_name, event_type))

    if event_type == hs.application.watcher.activated then
      log.df(string.format("App activated: %s", app_name))

      activate_contextual_bindings(app_name)

      if _hide_all_window_except_front_status then
        -- hide all windows except the frontmost one
        key_stroke({ "cmd", "alt" }, "h")
        log.df("Hide all windows except the frontmost one")
      end

      if _hide_all_window_except_front_status and _auto_maximize_window_status then
        -- maximize window
        key_stroke({ "fn", "ctrl" }, "f")
        log.df("Maximize window")
      end
    end

    if event_type == hs.application.watcher.deactivated then
      log.df(string.format("App deactivated: %s", app_name))
      clear_contextual_bindings(app_name)
    end
  end)

  app_watcher:start()

  log.df("App watcher started")

  -- Bind `hideAllWindowExceptFront` toggle
  if M.config.watcher.hide_all_window_except_front.enabled then
    local bindings = M.config.watcher.hide_all_window_except_front.bindings
    if bindings and type(bindings) == "table" then
      local hotkey = hs.hotkey.bind(bindings.modifier, bindings.key, function()
        _hide_all_window_except_front_status = not _hide_all_window_except_front_status
        hs.alert.show(string.format("hide_all_window_except_front: %s", _hide_all_window_except_front_status))
        log.df(string.format("hide_all_window_except_front: %s", _hide_all_window_except_front_status))
      end)
      table.insert(active_watcher_hotkeys, hotkey)
      log.df(string.format("Initialized watcher hide_all_window_except_front hotkey"))
    else
      log.df("No watcher hide_all_window_except_front bindings defined")
    end
  end

  -- Bind `autoMaximizeWindow` toggle
  if M.config.watcher.auto_maximize_window.enabled then
    local bindings = M.config.watcher.auto_maximize_window.bindings
    if bindings and type(bindings) == "table" then
      local hotkey = hs.hotkey.bind(bindings.modifier, bindings.key, function()
        _auto_maximize_window_status = not _auto_maximize_window_status
        hs.alert.show(string.format("auto_maximize_window: %s", _auto_maximize_window_status))
        log.df(string.format("auto_maximize_window: %s", _auto_maximize_window_status))
      end)
      table.insert(active_watcher_hotkeys, hotkey)
      log.df(string.format("Initialized watcher auto_maximize_window hotkey"))
    else
      log.df("No watcher auto_maximize_window bindings defined")
    end
  end
end

local function clear_watcher()
  if app_watcher then
    app_watcher:stop()
    app_watcher = nil
    log.df("Stopped app watcher")
  end

  for _, hotkey in ipairs(active_watcher_hotkeys) do
    if hotkey then
      hotkey:delete()
    end
  end
  log.df(string.format("Cleared %s watcher hotkeys", #active_watcher_hotkeys))
  active_watcher_hotkeys = {}
end

-- ------------------------------------------------------------------
-- API
-- ------------------------------------------------------------------

---@type Hs.System.Config
M.config = {}

---@param user_config? Hs.System.Config
---@return nil
function M:init(user_config)
  print("-- Initializing System...")
  M.config = utils.tbl_deep_extend("force", default_config, user_config or {})
  log = hs.logger.new(M.mod_name, M.config.log_level)
end

---@return nil
function M:start()
  print("-- Starting System...")
  setup_launchers()
  setup_custom_bindings()
  setup_watcher()
end

function M:stop()
  print("-- Stopping System...")
  clear_launchers()
  clear_custom_bindings()
  clear_contextual_bindings()
  clear_watcher()
end

M.key_stroke = key_stroke
M.safe_select_menu_item = safe_select_menu_item

return M
