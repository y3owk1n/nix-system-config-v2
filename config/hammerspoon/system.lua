---@diagnostic disable: undefined-global

local utils = require("utils")
local app_watcher = require("app-watcher")

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
end

local function clear_launchers()
  for _, hotkey in ipairs(active_launcher_hotkeys) do
    if hotkey then
      hotkey:delete()
    end
  end
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
end

local function clear_custom_bindings()
  for _, custom_action in ipairs(active_custom_bindings) do
    if custom_action then
      custom_action:delete()
    end
  end

  active_custom_bindings = {}
end

-- ------------------------------------------------------------------
-- Contextual Bindings
-- ------------------------------------------------------------------

-- Store active contextual hotkeys for cleanup
local active_contextual_hotkeys = {}

---Function to clear all contextual bindings
---@return nil
local function clear_contextual_bindings()
  for _, hotkey in ipairs(active_contextual_hotkeys) do
    if hotkey then
      hotkey:delete()
    end
  end
  active_contextual_hotkeys = {}
  log.df("Cleared " .. #active_contextual_hotkeys .. " contextual bindings")
end

---Function to activate contextual bindings for a specific app
---@param app_name string
---@return nil
local function activate_contextual_bindings(app_name)
  clear_contextual_bindings()

  local bindings = M.config.contextual_bindings[app_name]
  if not bindings then
    log.df("No contextual bindings defined for: " .. (app_name or "Unknown"))
    return
  end

  log.df("Activating " .. #bindings .. " contextual bindings for: " .. app_name)

  for _, binding in ipairs(bindings) do
    local hotkey = hs.hotkey.bind(binding.modifier, binding.key, binding.action)
    table.insert(active_contextual_hotkeys, hotkey)
  end
end

-- ------------------------------------------------------------------
-- Window Watcher
-- ------------------------------------------------------------------

-- Global variable to track watcher
local _hide_all_window_except_front_status = false
local _auto_maximize_window_status = false

local active_watcher_hotkeys = {}

local function setup_watcher()
  _hide_all_window_except_front_status = M.config.watcher.hide_all_window_except_front.enabled or false

  _auto_maximize_window_status = M.config.watcher.auto_maximize_window.enabled or false

  app_watcher.register(M.mod_name, function(app_name, event_type, app_object)
    -- Wrap the entire callback in pcall to prevent crashes
    local success, error = pcall(function()
      log.df("Watcher event: App=" .. (app_name or "nil") .. ", Event=" .. event_type)

      if event_type == hs.application.watcher.activated then
        log.df("App activated: " .. (app_name or "Unknown"))

        hs.timer.doAfter(0.1, function()
          activate_contextual_bindings(app_name)
        end)

        if _hide_all_window_except_front_status then
          hs.timer.doAfter(0.1, function()
            -- hide all windows except the frontmost one
            key_stroke({ "cmd", "alt" }, "h")
          end)
        end

        if _hide_all_window_except_front_status and _auto_maximize_window_status then
          hs.timer.doAfter(0.1, function()
            -- maximize window
            key_stroke({ "fn", "ctrl" }, "f")
          end)
        end
      end

      if event_type == hs.application.watcher.deactivated then
        log.df("App deactivated: " .. (app_name or "Unknown"))
        clear_contextual_bindings()
      end
    end)

    if not success then
      log.df("Error in watcher callback: " .. error)
      -- Restart the watcher after an error
      hs.timer.doAfter(1.0, start_watcher)
    end
  end)

  log.df("System watcher registered with centralized manager")

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
    else
      log.df("No watcher auto_maximize_window bindings defined")
    end
  end
end

local function clear_watcher()
  app_watcher.unregister(M.mod_name)

  for _, hotkey in ipairs(active_watcher_hotkeys) do
    if hotkey then
      hotkey:delete()
    end
  end
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
  M.config = utils.tbl_deep_extend("force", default_config, user_config or {})
  log = hs.logger.new(M.mod_name, M.config.log_level)
end

---@return nil
function M:start()
  setup_launchers()
  setup_custom_bindings()
  setup_watcher()
end

function M:stop()
  clear_launchers()
  clear_custom_bindings()
  clear_contextual_bindings()
  clear_watcher()
end

M.key_stroke = key_stroke
M.safe_select_menu_item = safe_select_menu_item

return M
