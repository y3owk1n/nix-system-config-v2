---@diagnostic disable: undefined-global

local utils = require("utils")

local M = {}

M.__index = M

local watcher = hs.application.watcher
local printf = hs.printf
local timer = hs.timer
local floor = math.floor

-- Store all registered callbacks
local registered_callbacks = {}

-- Single global watcher instance
local global_watcher = nil

-- Configuration
local default_config = {
  show_logs = false,
}

-- Logging function
local function log(message)
  if not M.config.show_logs then
    return
  end

  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local ms = floor(timer.absoluteTime() / 1e6) % 1000
  printf("[AppWatcherManager][%s.%03d] %s", timestamp, ms, message)
end

-- Central event handler that distributes events to all registered callbacks
local function central_event_handler(app_name, event_type, app_object)
  local callback_count = 0
  for _ in pairs(registered_callbacks) do
    callback_count = callback_count + 1
  end

  log(string.format("Broadcasting event: %s - %s to %d callbacks", app_name or "nil", event_type, callback_count))

  -- Call all registered callbacks
  for module_name, callback in pairs(registered_callbacks) do
    local success, error_msg = pcall(callback, app_name, event_type, app_object)
    if not success then
      log(string.format("Error in %s callback: %s", module_name, error_msg))
    end
  end
end

-- Start the global watcher if not already running
local function ensure_watcher_running()
  if global_watcher then
    return
  end

  global_watcher = watcher.new(central_event_handler)
  global_watcher:start()
  log("Global application watcher started")
end

-- Stop the global watcher if no callbacks are registered
local function maybe_stop_watcher()
  if global_watcher and next(registered_callbacks) == nil then
    global_watcher:stop()
    global_watcher = nil
    log("Global application watcher stopped (no more callbacks)")
  end
end

-- ------------------------------------------------------------------
-- API
-- ------------------------------------------------------------------

M.config = {}

function M.setup(user_config)
  M.config = utils.tbl_deep_extend("force", default_config, user_config or {})
end

-- Register a callback for application events
-- @param module_name string: Unique identifier for the module
-- @param callback function: Function to call with (app_name, event_type, app_object)
function M.register(module_name, callback)
  if type(module_name) ~= "string" then
    error("module_name must be a string")
  end

  if type(callback) ~= "function" then
    error("callback must be a function")
  end

  registered_callbacks[module_name] = callback
  ensure_watcher_running()

  log(string.format("Registered callback for module: %s", module_name))
end

-- Unregister a callback
-- @param module_name string: Module identifier to unregister
function M.unregister(module_name)
  if registered_callbacks[module_name] then
    registered_callbacks[module_name] = nil
    log(string.format("Unregistered callback for module: %s", module_name))

    maybe_stop_watcher()
  end
end

-- Get list of registered modules
function M.get_registered_modules()
  local modules = {}
  for module_name, _ in pairs(registered_callbacks) do
    table.insert(modules, module_name)
  end
  return modules
end

-- Force restart the watcher (useful for debugging)
function M.restart()
  if global_watcher then
    global_watcher:stop()
    global_watcher = nil
  end

  if next(registered_callbacks) then
    ensure_watcher_running()
    log("Watcher restarted")
  end
end

-- Clean up everything
function M.cleanup()
  if global_watcher then
    global_watcher:stop()
    global_watcher = nil
  end

  registered_callbacks = {}
  log("AppWatcherManager cleaned up")
end

return M
