---@diagnostic disable: undefined-global

local utils = require("utils")

local M = {}

M.__index = M

local floor = math.floor
local bind = hs.hotkey.bind
local launch_or_focus = hs.application.launchOrFocus
local notify = hs.alert.show
local frontmost_application = hs.application.frontmostApplication
local do_after = hs.timer.doAfter
local watcher = hs.application.watcher
local printf = hs.printf
local timer = hs.timer

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

--- @param message string # The message to log.
local function log(message)
  if not M.config.show_logs then
    return
  end

  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local ms = floor(timer.absoluteTime() / 1e6) % 1000
  printf("[%s.%03d] %s", timestamp, ms, message)
end

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
  local app = frontmost_application()
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
---@field show_logs? boolean Whether to show logs

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
  show_logs = false,
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

local function setup_launchers()
  for appName, shortcut in pairs(M.config.apps.bindings) do
    bind(M.config.apps.modifier, shortcut, function()
      launch_or_focus(appName)
    end)
  end
end

-- ------------------------------------------------------------------
-- Custom Bindings
-- ------------------------------------------------------------------

local function setup_custom_bindings()
  for _, custom_action in pairs(M.config.custom_bindings) do
    bind(custom_action.modifier, custom_action.key, custom_action.action)
  end
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
  log("Cleared " .. #active_contextual_hotkeys .. " contextual bindings")
end

---Function to activate contextual bindings for a specific app
---@param appName string
---@return nil
local function activate_contextual_bindings(appName)
  clear_contextual_bindings()

  local bindings = M.config.contextual_bindings[appName]
  if not bindings then
    log("No contextual bindings defined for: " .. (appName or "Unknown"))
    return
  end

  log("Activating " .. #bindings .. " contextual bindings for: " .. appName)

  for _, binding in ipairs(bindings) do
    local hotkey = bind(binding.modifier, binding.key, binding.action)
    table.insert(active_contextual_hotkeys, hotkey)
  end
end

-- ------------------------------------------------------------------
-- Window Watcher
-- ------------------------------------------------------------------

-- Global variable to track watcher
local _app_watcher = nil
local _hide_all_window_except_front_status = false
local _auto_maximize_window_status = false

---Function to create and start the watcher
---@return nil
local function start_watcher()
  -- Stop existing watcher if it exists
  if _app_watcher then
    _app_watcher:stop()
  end

  _app_watcher = watcher.new(function(app_name, event_type, app_object)
    -- Wrap the entire callback in pcall to prevent crashes
    local success, error = pcall(function()
      log("Watcher event: App=" .. (app_name or "nil") .. ", Event=" .. event_type)

      if event_type == watcher.activated then
        log("App activated: " .. (app_name or "Unknown"))

        do_after(0.1, function()
          activate_contextual_bindings(app_name)
        end)

        if _hide_all_window_except_front_status then
          do_after(0.1, function()
            -- hide all windows except the frontmost one
            key_stroke({ "cmd", "alt" }, "h")
          end)
        end

        if _hide_all_window_except_front_status and _auto_maximize_window_status then
          do_after(0.1, function()
            -- maximize window
            key_stroke({ "fn", "ctrl" }, "f")
          end)
        end
      end

      if event_type == watcher.deactivated then
        log("App deactivated: " .. (app_name or "Unknown"))
        clear_contextual_bindings()
      end
    end)

    if not success then
      log("Error in watcher callback: " .. error)
      -- Restart the watcher after an error
      do_after(1.0, start_watcher)
    end
  end)

  _app_watcher:start()
  log("Watcher started/restarted")
end

local function setup_watcher()
  _hide_all_window_except_front_status = M.config.watcher.hide_all_window_except_front.enabled or false

  _auto_maximize_window_status = M.config.watcher.auto_maximize_window.enabled or false

  start_watcher()

  -- Bind `hideAllWindowExceptFront` toggle
  if M.config.watcher.hide_all_window_except_front.enabled then
    local bindings = M.config.watcher.hide_all_window_except_front.bindings
    if bindings and type(bindings) == "table" then
      bind(bindings.modifier, bindings.key, function()
        _hide_all_window_except_front_status = not _hide_all_window_except_front_status
        notify(string.format("hide_all_window_except_front: %s", _hide_all_window_except_front_status))
        log(string.format("hide_all_window_except_front: %s", _hide_all_window_except_front_status))
      end)
    else
      log("No watcher hide_all_window_except_front bindings defined")
    end
  end

  -- Bind `autoMaximizeWindow` toggle
  if M.config.watcher.auto_maximize_window.enabled then
    local bindings = M.config.watcher.auto_maximize_window.bindings
    if bindings and type(bindings) == "table" then
      bind(bindings.modifier, bindings.key, function()
        _auto_maximize_window_status = not _auto_maximize_window_status
        notify(string.format("auto_maximize_window: %s", _auto_maximize_window_status))
        log(string.format("auto_maximize_window: %s", _auto_maximize_window_status))
      end)
    else
      log("No watcher auto_maximize_window bindings defined")
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

M.key_stroke = key_stroke
M.safe_select_menu_item = safe_select_menu_item

return M
