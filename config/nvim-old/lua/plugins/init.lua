local M = {}

local Modules = {}
local Utils = {}
local Lazy = {}

---Simple min-heap implementation for priority queue
---@class PriorityQueue
---@field private heap PluginModule.Resolved[]
---@field private size number
local PriorityQueue = {}

-----------------------------------------------------------------------------//
-- Configuration
-----------------------------------------------------------------------------//

---@type string
local mod_base_path

---@type boolean
local did_setup = false

-----------------------------------------------------------------------------//
-- State & caches
-----------------------------------------------------------------------------//

---A table of all discovered modules with its name as key for better lookup
---@type table<string, PluginModule.Resolved>
local mod_map = {}

---A list of all discovered modules, sorted by dependency and priority
---@type PluginModule.Resolved[]
local sorted_modules = {}

---A list of all registries from the discovered modules and can be used to add them to vim.pack
---@type (string|vim.pack.Spec)[]
local registry_map = {}

---Cache discovered modules
---@type PluginModule.Resolved[]
local _discovered_modules = nil

---Cache argv commands
---@type table<string, boolean>
local _argv_cmds = nil

---Cache expanded paths to avoid repeated fs calls
---@type table<string, {expanded: string, exists: boolean}>
local _path_cache = {}

-- keeps the order in which modules were successfully resolved
---@type PluginModule.ResolutionEntry[]
local resolution_order = {}

---Waiting for a module to load
---@type table<string, PluginModule.Resolved[]>
local waiting_for_module = {}

---Active coroutines for cleanup tracking
---@type table<thread, {mod: PluginModule.Resolved, start_time: number, cleanup_done: boolean}>
local active_coroutines = {}

---Coroutines by module name for easy lookup
---@type table<string, thread[]>
local module_coroutines = {}

---Cleanup timers to prevent memory leaks
---@type table<thread, uv.uv_timer_t>
local cleanup_timers = {}

-- Configuration constants
local DEFAULT_ASYNC_SLICE_MS = 16
local DEFAULT_SETUP_TIMEOUT = 5000
local DEFAULT_MAX_RETRIES = 2

local LOG_LEVELS = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

-----------------------------------------------------------------------------//
-- Utilities
-----------------------------------------------------------------------------//

Utils.log = {
  level = LOG_LEVELS.INFO, -- Default log level

  debug = function(msg)
    if Utils.log.level <= LOG_LEVELS.DEBUG then
      vim.notify("[PLUGIN MOD] " .. msg, vim.log.levels.DEBUG)
    end
  end,

  info = function(msg)
    if Utils.log.level <= LOG_LEVELS.INFO then
      vim.notify("[PLUGIN MOD] " .. msg, vim.log.levels.INFO)
    end
  end,

  warn = function(msg)
    if Utils.log.level <= LOG_LEVELS.WARN then
      vim.notify("[PLUGIN MOD] " .. msg, vim.log.levels.WARN)
    end
  end,

  error = function(msg)
    if Utils.log.level <= LOG_LEVELS.ERROR then
      vim.notify("[PLUGIN MOD] " .. msg, vim.log.levels.ERROR)
    end
  end,
}

---Parse `vim.v.argv` to extract `+command` CLI flags.
---@return table<string, boolean>
function Utils.argv_cmds()
  if _argv_cmds then
    return _argv_cmds
  end
  ---@type table<string, boolean>
  _argv_cmds = {}
  for _, arg in ipairs(vim.v.argv) do
    local cmd = arg:match("^%+(.+)")
    if cmd then
      _argv_cmds[cmd:lower()] = true
    end
  end
  return _argv_cmds
end

---Convert a string or a table of strings to a table of strings
---@param x string|string[]
---@return string[]
function Utils.string_or_table(x)
  if type(x) == "string" then
    return { x }
  end
  return x
end

---Check if a path exists
---@param path string
---@return boolean
function Utils.path_exists(path)
  local cached = _path_cache[path]
  if cached ~= nil then
    return cached.exists
  end

  local stat = vim.uv.fs_stat(path)
  local exists = stat ~= nil
  vim.tbl_deep_extend("force", _path_cache, { [path] = { exists = exists } })
  return exists
end

---Get expanded path with caching
---@param path string
---@return string
function Utils.expand_path(path)
  local cached = _path_cache[path]
  if cached then
    return cached.expanded
  end

  local expanded = vim.fn.expand(path)
  vim.tbl_deep_extend("force", _path_cache, { [path] = { expanded = expanded } })
  return expanded
end

---Validate configuration on setup
---@param config PluginModule.Config
---@return boolean valid, string? error_message
function Utils.validate_config(config)
  if not config.mod_root or type(config.mod_root) ~= "string" then
    return false, "mod_root must be a non-empty string"
  end

  if config.setup_timeout and (type(config.setup_timeout) ~= "number" or config.setup_timeout <= 0) then
    return false, "setup_timeout must be a positive number"
  end

  if config.max_retries and (type(config.max_retries) ~= "number" or config.max_retries < 0) then
    return false, "max_retries must be a non-negative number"
  end

  if config.async_slice_ms and (type(config.async_slice_ms) ~= "number" or config.async_slice_ms <= 0) then
    return false, "async_slice_ms must be a positive number"
  end

  return true
end

---Check if a registry entry is a local development plugin
---@param registry_entry string|vim.pack.Spec
---@return boolean, string?
function Utils.is_local_dev_plugin(registry_entry)
  local src
  if type(registry_entry) == "string" then
    src = registry_entry
  elseif type(registry_entry) == "table" and registry_entry.src then
    src = registry_entry.src
  else
    return false
  end

  -- Check if it's a local path (starts with ./, /, or ~)
  if src:match("^[./~]") then
    return true, Utils.expand_path(src)
  end

  -- Check if it's in the format "local:plugin-name"
  local plugin_name = src:match("^local:(.+)")
  if plugin_name then
    local local_path = string.format("%s/%s", M.config.local_dev_config.base_dir, plugin_name)
    return true, Utils.expand_path(local_path)
  end

  return false
end

---Show a visual timeline of plugin resolution.
---@return nil
function Utils.print_resolution_timeline()
  local lines = { "Resolution sequence:" }
  for i, entry in ipairs(resolution_order) do
    local error_suffix = ""
    if entry.errors and #entry.errors > 0 then
      error_suffix = " ⚠"
    end
    local after_info = ""
    if entry.after and #entry.after > 0 then
      after_info = string.format(" after: [%s]", table.concat(entry.after, ", "))
    end
    table.insert(
      lines,
      string.format(
        "%2d. [%s] %-25s %-5s %.2f ms%s %-20s",
        i,
        entry.async and "async" or "sync",
        entry.name,
        entry.parent and entry.parent.name or "-",
        entry.ms,
        error_suffix,
        after_info
      )
    )
  end
  Utils.log.info(table.concat(lines, "\n"))
end

---Hacky way to update vim.pack all at once
---@return nil
function Utils.update_all_packages()
  vim.pack.update()
end

---Remove all packages from vim.pack
---@return nil
function Utils.remove_all_packages()
  local plugins = vim.pack.get()
  local names = vim.tbl_map(function(p)
    return p.spec.name
  end, plugins)
  local choice = vim.fn.confirm("Remove all packages from vim.pack?", "&Yes\n&No", 2)
  if choice == 1 then
    vim.pack.del(names)
  end
end

---Synchronize packages from registry to the vim.pack.
---@return nil
function Utils.sync_packages()
  local plugins = vim.pack.get()

  -- normalize the registry map to a list of strings src
  ---@type string[]
  local normalized_registry_map = {}
  for _, p in ipairs(registry_map) do
    local is_local, _ = Utils.is_local_dev_plugin(p)
    if not is_local then
      table.insert(normalized_registry_map, p.name)
    end
  end

  -- loop through all plugins and remove those that are not in the registry
  ---@type string[]
  local to_remove = {}
  for _, p in ipairs(plugins) do
    local name = p.spec.name
    if not vim.tbl_contains(normalized_registry_map, name) then
      table.insert(to_remove, name)
    end
  end

  if #to_remove <= 0 then
    Utils.log.info("No plugins to remove")
    return
  end

  --- show more info about what to be removed
  local lines = {}
  for _, p in ipairs(to_remove) do
    table.insert(lines, string.format("%s", p))
  end

  local choice = vim.fn.confirm(
    "To be removed plugins:\n\n" .. table.concat(lines, "\n") .. "\nRemove these plugins? (y/N): ",
    "&Yes\n&No",
    2
  )
  if choice == 1 then
    vim.pack.del(to_remove)
  end
end

---Print loaded and not-loaded plugin status.
function Utils.print_plugin_status()
  local loaded = M.get_plugins(true)
  local not_loaded = M.get_plugins(false)

  local lines = { string.format("Plugin status (Total: %d):", #sorted_modules) }
  table.insert(lines, string.format("Loaded [%s]:", #loaded))
  for i, entry in ipairs(loaded) do
    local dev_status = ""
    if entry.registry then
      for _, reg in ipairs(entry.registry) do
        local is_local = Utils.is_local_dev_plugin(reg)
        if is_local then
          dev_status = " [LOCAL DEV]"
          break
        end
      end
    end
    local time_info = entry.load_time_ms and string.format(" (%.2fms)", entry.load_time_ms) or ""
    table.insert(lines, string.format("%2d. %s%s%s", i, entry.name, dev_status, time_info))
  end

  table.insert(lines, string.format("Not loaded [%s]:", #not_loaded))
  for i, entry in ipairs(not_loaded) do
    local dev_status = ""
    local status_suffix = ""
    if entry.failed then
      status_suffix = " [FAILED]"
    elseif entry.lazy then
      status_suffix = " [LAZY]"
    end
    if entry.registry then
      for _, reg in ipairs(entry.registry) do
        local is_local = Utils.is_local_dev_plugin(reg)
        if is_local then
          dev_status = " [LOCAL DEV]"
          break
        end
      end
    end
    table.insert(lines, string.format("  %2d. %s%s%s", i, entry.name, dev_status, status_suffix))
  end

  Utils.log.info(table.concat(lines, "\n"))
end

---Refresh all local development plugins
---@return nil
function Utils.refresh_local_dev_plugins()
  local refreshed = 0
  local failed = 0

  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local, local_path = Utils.is_local_dev_plugin(reg)
        if is_local and local_path then
          if Utils.setup_local_dev_plugin(reg, local_path) then
            refreshed = refreshed + 1
          else
            failed = failed + 1
          end
        end
      end
    end
  end

  if failed > 0 then
    Utils.log.warn(string.format("Refreshed %d local development plugins (%d failed)", refreshed, failed))
  else
    Utils.log.info(string.format("Refreshed %d local development plugins", refreshed))
  end
end

---Get all currently active local dev plugins from the registry
---@return table<string, boolean> plugin_names Set of active local dev plugin names
function Utils.get_active_local_dev_plugins()
  local active_plugins = {}
  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local, local_path = Utils.is_local_dev_plugin(reg)
        if is_local and local_path then
          local plugin_name
          if type(reg) == "string" then
            if reg:match("^local:(.+)") then
              plugin_name = reg:match("^local:(.+)")
            else
              plugin_name = vim.fn.fnamemodify(vim.fn.expand(reg), ":t")
            end
          elseif reg.name then
            plugin_name = reg.name
          else
            plugin_name = vim.fn.fnamemodify(local_path, ":t")
          end
          active_plugins[plugin_name] = true
        end
      end
    end
  end
  return active_plugins
end

---Clean up orphaned local development plugins
---@return nil
function Utils.cleanup_orphaned_local_dev_plugins()
  local pack_path = string.format("%s/site/pack/local", vim.fn.stdpath("data"))
  local start_path = string.format("%s/start", pack_path)
  local opt_path = string.format("%s/opt", pack_path)

  if not Utils.path_exists(pack_path) then
    Utils.log.info("No local pack directory found, nothing to clean up")
    return
  end

  local active_plugins = Utils.get_active_local_dev_plugins()
  local removed_count = 0
  local removed_plugins = {}

  -- check both start and opt directories
  for _, dir_path in ipairs({ start_path, opt_path }) do
    if Utils.path_exists(dir_path) then
      local handle = vim.uv.fs_scandir(dir_path)
      if handle then
        while true do
          local name, type = vim.uv.fs_scandir_next(handle)
          if not name then
            break
          end

          if type == "directory" or type == "link" then
            local plugin_path = string.format("%s/%s", dir_path, name)
            local stat = vim.uv.fs_lstat(plugin_path)

            -- check if it's a symlink (our local dev plugins) or if it's not in active list
            local is_symlink = stat and stat.type == "link"
            local is_orphaned = not active_plugins[name]

            -- only remove symlinks that are orphaned, or ask about regular directories
            if is_symlink and is_orphaned then
              local success = vim.fn.delete(plugin_path, "rf")
              if success == 0 then
                removed_count = removed_count + 1
                table.insert(removed_plugins, name)
                Utils.log.info(string.format("Removed orphaned local dev plugin: %s", name))
              else
                Utils.log.error(("Failed to remove: %s"):format(plugin_path))
              end
            elseif is_orphaned and not is_symlink then
              -- for non-symlink directories, let user decide
              local choice = vim.fn.confirm(
                ("Found orphaned plugin directory: %s\nThis doesn't appear to be a symlink. Remove it?"):format(name),
                "&Yes\n&No\n&Skip All",
                2
              )
              if choice == 1 then
                local success = vim.fn.delete(plugin_path, "rf")
                if success == 0 then
                  removed_count = removed_count + 1
                  table.insert(removed_plugins, name)
                  Utils.log.info(string.format("Removed orphaned plugin directory: %s", name))
                else
                  Utils.log.error(("Failed to remove: %s"):format(plugin_path))
                end
              elseif choice == 3 then
                break -- skip all remaining
              end
            end
          end
        end
      end
    end
  end

  if removed_count > 0 then
    Utils.log.info(string.format("Cleanup complete: removed %d orphaned plugins", removed_count))
    if #removed_plugins > 0 then
      Utils.log.info(string.format("Removed plugins: %s", table.concat(removed_plugins, ", ")))
    end
    Utils.log.info("Restart Neovim to ensure clean state")
  else
    Utils.log.info("No orphaned local dev plugins found")
  end
end

---Print failed plugins
---@return nil
function Utils.print_failed_plugins()
  local failed = vim.tbl_filter(function(m)
    return m.failed
  end, sorted_modules)
  if #failed == 0 then
    Utils.log.info("No failed plugins ✓")
    return
  end

  local lines = { string.format("Failed plugins (%d):", #failed) }
  for i, mod in ipairs(failed) do
    local retry_info = ""
    if mod.retry_count and mod.retry_count > 0 then
      retry_info = string.format(" (retried %d times)", mod.retry_count)
    end
    table.insert(lines, string.format("  %2d. %s: %s%s", i, mod.name, mod.failure_reason or "unknown", retry_info))
  end
  Utils.log.warn(table.concat(lines, "\n"))
end

---Print plugin health
---@return nil
function Utils.print_plugin_health()
  local issues = {}
  local warnings = 0
  local slow_threshold = M.config.slow_load_threshold or 100

  -- check for failed modules
  local failed_count = 0
  for _, mod in ipairs(sorted_modules) do
    if mod.failed then
      failed_count = failed_count + 1
      table.insert(issues, string.format("✗ %s: %s", mod.name, mod.failure_reason or "unknown error"))
    end

    -- check load times
    if mod.loaded and mod.load_time_ms and mod.load_time_ms > slow_threshold then
      warnings = warnings + 1
      if warnings <= 5 then -- Don't spam too many warnings
        table.insert(issues, string.format("⚠ %s: slow load time (%.2fms)", mod.name, mod.load_time_ms))
      end
    end
  end

  -- check for missing local dev plugins
  local missing_local = 0
  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local, local_path = Utils.is_local_dev_plugin(reg)
        if is_local and local_path and not Utils.path_exists(local_path) then
          missing_local = missing_local + 1
          table.insert(issues, string.format("✗ Local plugin path missing: %s", local_path))
        end
      end
    end
  end

  -- health summary
  local health_lines = {
    string.format("Plugin Health Summary (Total: %d plugins)", #sorted_modules),
    string.format("  ✓ Loaded: %d", #M.get_plugins(true)),
    string.format("  ✗ Failed: %d", failed_count),
    string.format("  ⚠ Slow loading (>%dms): %d", slow_threshold, warnings),
    string.format("  📁 Missing local paths: %d", missing_local),
  }

  if #issues == 0 then
    table.insert(health_lines, "All plugins healthy ✓")
    Utils.log.info(table.concat(health_lines, "\n"))
  else
    table.insert(health_lines, "\nIssues found:")
    vim.list_extend(health_lines, issues)
    if warnings > 5 then
      table.insert(health_lines, string.format("... and %d more performance warnings", warnings - 5))
    end
    Utils.log.warn(table.concat(health_lines, "\n"))
  end
end

-----------------------------------------------------------------------------//
-- Priority queue
-----------------------------------------------------------------------------//

PriorityQueue.__index = PriorityQueue

---Priority queue constructor
---@return PriorityQueue
function PriorityQueue.new()
  return setmetatable({
    heap = {},
    size = 0,
  }, PriorityQueue)
end

---Push an item onto the priority queue
---@param item PluginModule.Resolved
---@return nil
function PriorityQueue:push(item)
  self.size = self.size + 1
  self.heap[self.size] = item
  self:bubble_up(self.size)
end

---Pop an item from the priority queue
---@return PluginModule.Resolved?
function PriorityQueue:pop()
  if self.size == 0 then
    return nil
  end

  local min = self.heap[1]
  self.heap[1] = self.heap[self.size]
  self.heap[self.size] = nil
  self.size = self.size - 1

  if self.size > 0 then
    self:bubble_down(1)
  end

  return min
end

---Bubble up an item in the priority queue
---@param index number
---@return nil
function PriorityQueue:bubble_up(index)
  if index <= 1 then
    return
  end

  local parent_index = math.floor(index / 2)
  if self.heap[parent_index].priority > self.heap[index].priority then
    self.heap[parent_index], self.heap[index] = self.heap[index], self.heap[parent_index]
    self:bubble_up(parent_index)
  end
end

---Bubble down an item in the priority queue
---@param index number
---@return nil
function PriorityQueue:bubble_down(index)
  local left_child = 2 * index
  local right_child = 2 * index + 1
  local smallest = index

  if left_child <= self.size and self.heap[left_child].priority < self.heap[smallest].priority then
    smallest = left_child
  end

  if right_child <= self.size and self.heap[right_child].priority < self.heap[smallest].priority then
    smallest = right_child
  end

  if smallest ~= index then
    self.heap[index], self.heap[smallest] = self.heap[smallest], self.heap[index]
    self:bubble_down(smallest)
  end
end

---Check if the priority queue is empty
---@return boolean
function PriorityQueue:is_empty()
  return self.size == 0
end

-----------------------------------------------------------------------------//
-- Coroutine resource management
-----------------------------------------------------------------------------//

---Register a coroutine for tracking
---@param co thread
---@param mod PluginModule.Resolved
---@return nil
local function register_coroutine(co, mod)
  active_coroutines[co] = {
    mod = mod,
    start_time = vim.uv.hrtime(),
    cleanup_done = false,
  }

  -- Track by module name
  module_coroutines[mod.name] = module_coroutines[mod.name] or {}
  table.insert(module_coroutines[mod.name], co)

  Utils.log.debug(string.format("Registered coroutine for module %s", mod.name))
end

---Cleanup resources for a coroutine
---@param co thread
---@param mod PluginModule.Resolved
---@return nil
local function cleanup_coroutine_resources(co, mod)
  if not co then
    return
  end

  local co_info = active_coroutines[co]
  if not co_info then
    -- already cleaned up or never registered
    return
  end

  if co_info.cleanup_done then
    Utils.log.debug(string.format("Coroutine for module %s already cleaned up", mod.name))
    return
  end

  local status = coroutine.status(co)
  local runtime_ms = (vim.uv.hrtime() - co_info.start_time) / 1e6

  Utils.log.debug(
    string.format("Cleaning up coroutine for module %s (status: %s, runtime: %.2fms)", mod.name, status, runtime_ms)
  )

  -- mark as cleaned up to prevent double cleanup
  co_info.cleanup_done = true

  -- remove from active coroutines tracking
  active_coroutines[co] = nil

  -- remove from module coroutines list
  if module_coroutines[mod.name] then
    for i, tracked_co in ipairs(module_coroutines[mod.name]) do
      if tracked_co == co then
        table.remove(module_coroutines[mod.name], i)
        break
      end
    end

    -- clean up empty module entry
    if #module_coroutines[mod.name] == 0 then
      module_coroutines[mod.name] = nil
    end
  end

  -- clean up any associated cleanup timer
  local timer = cleanup_timers[co]
  if timer then
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    cleanup_timers[co] = nil
  end

  -- if coroutine is still suspended, we can't force-kill it in Lua,
  -- but we can ensure we never resume it again by clearing references
  if status == "suspended" then
    Utils.log.warn(
      string.format(
        "Coroutine for module %s was still suspended during cleanup - this may indicate a stuck operation",
        mod.name
      )
    )
  end

  -- additional cleanup based on module state
  if mod.failed and status ~= "dead" then
    Utils.log.warn(
      string.format("Module %s failed but coroutine is still %s - potential resource leak", mod.name, status)
    )
  end
end

---Set up a cleanup timeout for a coroutine to prevent infinite hanging
---@param co thread
---@param mod PluginModule.Resolved
---@param timeout_ms number
---@return nil
local function setup_coroutine_timeout(co, mod, timeout_ms)
  local timer = vim.uv.new_timer()
  if not timer then
    Utils.log.warn(string.format("Failed to create timeout timer for module %s", mod.name))
    return
  end

  cleanup_timers[co] = timer

  timer:start(timeout_ms, 0, function()
    local status = coroutine.status(co)
    if status == "suspended" then
      Utils.log.error(
        string.format("Coroutine for module %s timed out after %dms (status: %s)", mod.name, timeout_ms, status)
      )

      -- mark module as failed due to timeout
      mod.failed = true
      mod.failure_reason = string.format("Async setup timed out after %dms", timeout_ms)

      -- force cleanup
      cleanup_coroutine_resources(co, mod)
    end
  end)
end

-----------------------------------------------------------------------------//
-- Discovery
-----------------------------------------------------------------------------//

---Discover plugin modules from filesystem
---@return PluginModule.Resolved[]
function Modules.discover()
  if _discovered_modules then
    return _discovered_modules
  end

  ---@type PluginModule.Resolved
  local modules = {}

  local discovery_start = vim.uv.hrtime()

  local files = vim.fs.find(function(name)
    return name:sub(-4) == ".lua"
  end, { type = "file", limit = math.huge, path = mod_base_path })

  Utils.log.debug(string.format("Found %d Lua files in %s", #files, mod_base_path))

  for _, file in ipairs(files) do
    local rel = file:sub(#mod_base_path + 2, -5):gsub("/", ".")
    if rel ~= "init" then
      local path = string.format("%s.%s", M.config.mod_root, rel)
      local ok, chunk = pcall(loadfile, file)
      if not ok or type(chunk) ~= "function" then
        Utils.log.error(("Bad file %s: %s"):format(file, chunk))
        goto continue
      end

      local env = setmetatable({ vim = vim }, { __index = _G })
      setfenv(chunk, env)
      local success, mod = pcall(chunk)
      if not success or type(mod) ~= "table" or type(mod.setup) ~= "function" then
        Utils.log.warn(("Plugin %s does not export valid setup"):format(path))
        goto continue
      end

      if mod.enabled == false then
        Utils.log.debug(string.format("Plugin %s is disabled", path))
        goto continue
      end

      local name = mod.name or path
      if Utils.argv_cmds()[name:lower()] then
        mod.lazy = false
        Utils.log.debug(string.format("Plugin %s forced to load via CLI", name))
      end

      ---@param x boolean|nil
      ---@param default boolean
      local function parse_boolean(x, default)
        if x == nil then
          return default
        end

        if type(x) == "boolean" then
          return x
        end

        return default
      end

      ---@type PluginModule.Resolved
      local entry = {
        name = name,
        path = path,
        setup = mod.setup,
        priority = mod.priority or 1000,
        requires = mod.requires or {},
        after = mod.after or {},
        lazy = mod.lazy or false,
        loaded = false,
        registry = mod.registry or {},
        async = parse_boolean(mod.async, true),
        post_pack_changed = mod.post_pack_changed or nil,
        failed = false,
        retry_count = 0,
      }

      table.insert(modules, entry)
      mod_map[name] = entry

      -- set up "after" watchers during discovery
      for _, after_name in ipairs(entry.after) do
        waiting_for_module[after_name] = waiting_for_module[after_name] or {}
        table.insert(waiting_for_module[after_name], entry)
      end

      for _, reg in ipairs(entry.registry) do
        table.insert(registry_map, reg)
      end
      ::continue::
    end
  end

  local discovery_ms = (vim.uv.hrtime() - discovery_start) / 1e6
  Utils.log.debug(string.format("Plugin discovery completed in %.2fms, found %d modules", discovery_ms, #modules))

  _discovered_modules = modules
  return modules
end

-----------------------------------------------------------------------------//
-- Topological sort with cycle detection
-----------------------------------------------------------------------------//

---Topologically sort plugin modules with cycle detection.
---@param mods PluginModule.Resolved[]
---@return boolean success
---@return string? error_message
function Modules.sort(mods)
  local in_degree = {}
  local rev = {}
  local visiting = {}
  local visited = {}

  -- initialize in_degree
  for _, m in ipairs(mods) do
    in_degree[m.name] = 0
    visited[m.name] = false
  end

  -- cycle detection DFS
  local function has_cycle(node_name, path)
    if visiting[node_name] then
      return true, path -- Found cycle
    end
    if visited[node_name] then
      return false
    end

    visiting[node_name] = true
    table.insert(path, node_name)

    local node = mod_map[node_name]
    if node then
      for _, dep_name in ipairs(node.requires) do
        local dep_node = mod_map[dep_name] or mod_map[string.format("%s.%s", M.config.mod_root, dep_name)]
        if dep_node then
          local cycle_found, cycle_path = has_cycle(dep_node.name, vim.deepcopy(path))
          if cycle_found then
            return true, cycle_path
          end
        end
      end
    end

    visiting[node_name] = false
    visited[node_name] = true
    table.remove(path)
    return false
  end

  -- check for cycles
  for _, m in ipairs(mods) do
    if not visited[m.name] then
      local cycle_found, cycle_path = has_cycle(m.name, {})
      if cycle_found and cycle_path then
        return false, string.format("Dependency cycle detected: %s", table.concat(cycle_path, " -> "))
      end
    end
  end

  -- build dependency graph
  for _, m in ipairs(mods) do
    for _, req in ipairs(m.requires) do
      local dep = mod_map[req] or mod_map[string.format("%s.%s", M.config.mod_root, req)]
      if dep then
        in_degree[m.name] = in_degree[m.name] + 1
        rev[dep.name] = rev[dep.name] or {}
        table.insert(rev[dep.name], m)
      else
        Utils.log.warn(string.format("Missing dependency %s for %s", req, m.name))
      end
    end
  end

  -- use priority queue for efficient sorting
  local pq = PriorityQueue.new()
  for _, m in ipairs(mods) do
    if in_degree[m.name] == 0 then
      pq:push(m)
    end
  end

  local out = {}
  while not pq:is_empty() do
    local cur = pq:pop()
    table.insert(out, cur)
    if cur and cur.name then
      for _, next_mod in ipairs(rev[cur.name] or {}) do
        in_degree[next_mod.name] = in_degree[next_mod.name] - 1
        if in_degree[next_mod.name] == 0 then
          pq:push(next_mod)
        end
      end
    end
  end

  if #out ~= #mods then
    return false, string.format("Topological sort failed: expected %d modules, got %d", #mods, #out)
  end

  sorted_modules = out
  return true
end

-----------------------------------------------------------------------------//
-- Safe setup
-----------------------------------------------------------------------------//

---Safely setup a plugin module
---@param mod PluginModule.Resolved
---@param parent? PluginModule.Resolved|nil nil if this is the root module, this is just to visualize the timeline
---@return boolean success, string? error_message
function Modules.setup_one(mod, parent)
  if mod.loaded then
    return true
  end

  if mod.failed then
    return false, string.format("Module previously failed: %s", mod.failure_reason or "unknown")
  end

  -- only check "requires" dependencies for startup
  local failed_deps = {}
  for _, dep_name in ipairs(mod.requires) do
    local dep = mod_map[dep_name] or mod_map[string.format("%s.%s", M.config.mod_root, dep_name)]
    if not dep then
      table.insert(failed_deps, dep_name)
    else
      local dep_ok, dep_err = Modules.setup_one(dep, mod) -- recursive, but safe: list is topo-sorted
      if not dep_ok then
        table.insert(failed_deps, string.format("%s (%s)", dep_name, dep_err or "unknown error"))
      end
    end
  end

  -- if any dependencies failed, mark this module as failed but continue with others
  if #failed_deps > 0 then
    local error_msg = string.format("Failed dependencies: %s", table.concat(failed_deps, ", "))
    Utils.log.error(string.format("Cannot load %s: %s", mod.name, error_msg))
    mod.failed = true
    mod.failure_reason = error_msg
    return false, error_msg
  end

  -- start measuring
  local t0 = vim.uv.hrtime()
  local errors = {}

  -- setup for local dev or just packadd
  if mod.registry then
    for i, reg in ipairs(mod.registry) do
      local is_local, local_path = Utils.is_local_dev_plugin(reg)
      if is_local and local_path then
        local ok = Utils.setup_local_dev_plugin(reg, local_path)
        if not ok then
          table.insert(errors, string.format("Failed to setup local dev plugin %d", i))
        end
      else
        local ok, err = pcall(function()
          vim.cmd.packadd(reg.name or reg)
        end)
        if not ok then
          table.insert(errors, string.format("Failed to packadd %s: %s", reg.name or reg, err))
        end
      end
    end
  end

  -- if registry setup had errors but we can still try to require the module
  if #errors > 0 then
    Utils.log.warn(string.format("Registry issues for %s: %s", mod.name, table.concat(errors, "; ")))
    -- don't return false yet - maybe the module can still be required
  end

  -- require the module
  local ok, data = pcall(require, mod.path)
  if not ok then
    local error_msg = string.format("Failed to require: %s", data)
    Utils.log.error(string.format("Module %s: %s", mod.name, error_msg))
    mod.failed = true
    mod.failure_reason = error_msg
    return false, error_msg
  end

  -- validate that the module has a setup function
  if type(data.setup) ~= "function" then
    local error_msg = "Module does not export a setup function"
    Utils.log.error(string.format("Module %s: %s", mod.name, error_msg))
    mod.failed = true
    mod.failure_reason = error_msg
    return false, error_msg
  end

  -- run setup with timeout protection
  local setup_ok, setup_err
  local timeout_ms = M.config.setup_timeout

  if timeout_ms and timeout_ms > 0 then
    local timed_out = false
    local timer = vim.uv.new_timer()

    if timer then
      timer:start(timeout_ms, 0, function()
        timed_out = true
        timer:stop()
        timer:close()
      end)
    end

    setup_ok, setup_err = pcall(data.setup)

    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end

    if timed_out then
      setup_ok = false
      setup_err = string.format("Setup timed out after %dms", timeout_ms)
    end
  else
    setup_ok, setup_err = pcall(data.setup)
  end

  if not setup_ok then
    local error_msg = string.format("Setup failed: %s", setup_err)
    Utils.log.error(string.format("Module %s: %s", mod.name, error_msg))
    mod.failed = true
    mod.failure_reason = error_msg

    return false, error_msg
  end

  -- stop measuring and add to resolution order
  local ms = (vim.uv.hrtime() - t0) / 1e6
  table.insert(resolution_order, {
    async = false,
    name = mod.name,
    ms = ms,
    parent = parent,
    errors = #errors > 0 and errors or nil,
    after = mod.after,
  })

  mod.loaded = true
  mod.load_time_ms = ms

  -- trigger any "after" modules
  Modules.trigger_after_modules(mod.name)

  if #errors > 0 then
    Utils.log.warn(string.format("Module %s loaded with warnings (%.2fms)", mod.name, ms))
  else
    Utils.log.debug(string.format("Module %s loaded successfully (%.2fms)", mod.name, ms))
  end

  return true
end

---Safely setup a module asynchronously
---@param mod PluginModule.Resolved
---@param parent? PluginModule.Resolved|nil nil if this is the root module, this is just to visualize the timeline
---@param on_done? fun(success: boolean, error?: string)
---@return boolean success
function Modules.async_setup_one(mod, parent, on_done)
  if mod.loaded then
    if on_done then
      vim.schedule(function()
        on_done(true)
      end)
    end
    return true
  end

  if mod.failed then
    if on_done then
      vim.schedule(function()
        on_done(false, mod.failure_reason)
      end)
    end
    return false
  end

  local async_slice_ms = M.config.async_slice_ms or DEFAULT_ASYNC_SLICE_MS
  local setup_timeout_ms = M.config.setup_timeout or DEFAULT_SETUP_TIMEOUT

  local co = coroutine.create(function()
    local errors = {}

    -- handle hard dependencies (requires) - must succeed
    local failed_deps = {}
    for _, dep_name in ipairs(mod.requires) do
      local dep = mod_map[dep_name] or mod_map[string.format("%s.%s", M.config.mod_root, dep_name)]
      if not dep then
        table.insert(failed_deps, dep_name)
      elseif not dep.loaded then
        -- recurse synchronously (dependencies are cheap)
        local ok, err = Modules.setup_one(dep, mod)
        if not ok then
          table.insert(failed_deps, string.format("%s (%s)", dep_name, err or "unknown error"))
        end
      end
    end

    -- handle soft dependencies (after) - don't fail if they fail
    local after_warnings = {}
    for _, after_name in ipairs(mod.after) do
      local after_mod = mod_map[after_name] or mod_map[string.format("%s.%s", M.config.mod_root, after_name)]
      if after_mod then
        local after_ok, after_err = Modules.setup_one(after_mod, mod)
        if not after_ok then
          table.insert(after_warnings, string.format("%s (%s)", after_name, after_err or "unknown error"))
        end
      end
    end

    if #failed_deps > 0 then
      local error_msg = string.format("Failed dependencies: %s", table.concat(failed_deps, ", "))
      mod.failed = true
      mod.failure_reason = error_msg
      Utils.log.error(string.format("Cannot async load %s: %s", mod.name, error_msg))
      return false, error_msg
    end

    if #after_warnings > 0 then
      Utils.log.warn(string.format("Soft dependency warnings for %s: %s", mod.name, table.concat(after_warnings, "; ")))
    end

    -- setup for local dev or just packadd
    if mod.registry then
      for i, reg in ipairs(mod.registry) do
        local is_local, local_path = Utils.is_local_dev_plugin(reg)
        if is_local and local_path then
          local ok = Utils.setup_local_dev_plugin(reg, local_path)
          if not ok then
            table.insert(errors, string.format("Failed to setup local dev plugin %d", i))
          end
        else
          local ok, err = pcall(function()
            vim.cmd.packadd(reg.name or reg)
          end)
          if not ok then
            table.insert(errors, string.format("Failed to packadd %s: %s", reg.name or reg, err))
          end
        end

        -- Yield periodically during registry setup
        if i % 3 == 0 then
          coroutine.yield()
        end
      end
    end

    -- require modules
    local ok, data = pcall(require, mod.path)
    if not ok then
      local error_msg = string.format("Failed to require: %s", data)
      mod.failed = true
      mod.failure_reason = error_msg
      Utils.log.error(string.format("Async module %s: %s", mod.name, error_msg))
      return false, error_msg
    end

    -- start measuring
    local t0 = vim.uv.hrtime()

    -- validate setup function
    if type(data.setup) ~= "function" then
      local error_msg = "Module does not export a setup function"
      mod.failed = true
      mod.failure_reason = error_msg
      Utils.log.error(string.format("Async module %s: %s", mod.name, error_msg))
      return false, error_msg
    end

    -- run setup with slice yielding
    local setup_start = vim.uv.hrtime()
    local setup_ok, setup_err = pcall(data.setup)

    if not setup_ok then
      local error_msg = string.format("Async setup failed: %s", setup_err)
      mod.failed = true
      mod.failure_reason = error_msg
      Utils.log.error(string.format("Async module %s: %s", mod.name, error_msg))

      return false, error_msg
    end

    -- check if we should yield after setup (if it took too long)
    local setup_duration = (vim.uv.hrtime() - setup_start) / 1e6
    if setup_duration > async_slice_ms then
      coroutine.yield() -- yield to UI
    end

    local ms = (vim.uv.hrtime() - t0) / 1e6
    table.insert(resolution_order, {
      async = true,
      name = mod.name,
      ms = ms,
      parent = parent,
      errors = #errors > 0 and errors or nil,
      after = mod.after,
    })

    mod.loaded = true
    mod.load_time_ms = ms

    -- trigger any "after" modules
    Modules.trigger_after_modules(mod.name)

    if #errors > 0 then
      Utils.log.warn(string.format("Async module %s loaded with warnings (%.2fms)", mod.name, ms))
    else
      Utils.log.debug(string.format("Async module %s loaded successfully (%.2fms)", mod.name, ms))
    end

    return true
  end)

  -- register coroutine for tracking
  register_coroutine(co, mod)
  setup_coroutine_timeout(co, mod, setup_timeout_ms)

  local function tick()
    local co_info = active_coroutines[co]
    if not co_info or co_info.cleanup_done then
      return
    end

    local co_ok, success_or_err, error_msg = coroutine.resume(co)

    if not co_ok then
      local full_error = string.format("Coroutine error in %s: %s", mod.name, debug.traceback(co, success_or_err))
      Utils.log.error(full_error)
      mod.failed = true
      mod.failure_reason = success_or_err
      cleanup_coroutine_resources(co, mod)
      if on_done then
        vim.schedule(function()
          on_done(false, success_or_err)
        end)
      end
      return
    end

    if coroutine.status(co) == "dead" then
      -- coroutine completed
      local success = success_or_err
      cleanup_coroutine_resources(co, mod)
      if success then
        if on_done then
          vim.schedule(function()
            on_done(true)
          end)
        end
      else
        if on_done then
          vim.schedule(function()
            on_done(false, error_msg)
          end)
        end
      end
    else
      -- coroutine yielded, schedule next tick
      vim.defer_fn(tick, 1)
    end
  end

  tick()
  return true
end

---Setup a local development plugin
---@param registry_entry string|vim.pack.Spec
---@param local_path string
---@return boolean success
function Utils.setup_local_dev_plugin(registry_entry, local_path)
  if not Utils.path_exists(local_path) then
    Utils.log.error(("Local plugin path does not exist: %s"):format(local_path))
    return false
  end

  local plugin_name
  if type(registry_entry) == "string" then
    if registry_entry:match("^local:(.+)") then
      plugin_name = registry_entry:match("^local:(.+)")
    else
      plugin_name = vim.fn.fnamemodify(local_path, ":t")
    end
  elseif registry_entry.name then
    plugin_name = registry_entry.name
  else
    plugin_name = vim.fn.fnamemodify(local_path, ":t")
  end

  local pack_path = string.format("%s/site/pack/local/start/%s", vim.fn.stdpath("data"), plugin_name)

  -- remove existing installation if it exists
  if Utils.path_exists(pack_path) then
    local success = vim.fn.delete(pack_path, "rf")
    if success ~= 0 then
      Utils.log.error(string.format("Failed to remove existing plugin path: %s", pack_path))
      return false
    end
  end

  -- create parent directory
  local parent_dir = vim.fn.fnamemodify(pack_path, ":h")
  vim.fn.mkdir(parent_dir, "p")

  -- create symlink or copy
  if M.config.local_dev_config.use_symlinks then
    -- create symlink
    local success = vim.uv.fs_symlink(local_path, pack_path)
    if not success then
      Utils.log.error(("Failed to create symlink from %s to %s"):format(local_path, pack_path))
      return false
    end
    Utils.log.debug(string.format("Created symlink: %s -> %s", pack_path, local_path))
  else
    -- copy directory
    local cmd = string.format("cp -r %s %s", vim.fn.shellescape(local_path), vim.fn.shellescape(pack_path))
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      Utils.log.error(("Failed to copy local plugin: %s\nError: %s"):format(cmd, result))
      return false
    end
    Utils.log.debug(string.format("Copied local plugin: %s -> %s", local_path, pack_path))
  end

  -- add to runtimepath immediately so it can be loaded
  vim.opt.runtimepath:prepend(pack_path)

  return true
end

-----------------------------------------------------------------------------//
-- After-load handling
-----------------------------------------------------------------------------//

---Function to trigger modules waiting for a specific plugin
---@param loaded_module_name string
---@return nil
function Modules.trigger_after_modules(loaded_module_name)
  local waiters = waiting_for_module[loaded_module_name]
  if not waiters then
    return
  end

  Utils.log.debug(string.format("Triggering %d modules waiting for %s", #waiters, loaded_module_name))

  for _, waiter in ipairs(waiters) do
    if not waiter.loaded and not waiter.failed then
      -- check if ALL "after" dependencies are now satisfied
      local all_after_loaded = true
      local missing_after = {}

      for _, after_name in ipairs(waiter.after) do
        local after_mod = mod_map[after_name] or mod_map[string.format("%s.%s", M.config.mod_root, after_name)]
        if after_mod and not after_mod.loaded then
          all_after_loaded = false
          table.insert(missing_after, after_name)
        end
      end

      if all_after_loaded then
        Utils.log.debug(string.format("All after dependencies satisfied for %s, loading now", waiter.name))
        vim.schedule(function()
          if waiter.async then
            Modules.async_setup_one(waiter)
          else
            Modules.setup_one(waiter)
          end
        end)
      else
        Utils.log.debug(
          string.format("Module %s still waiting for: %s", waiter.name, table.concat(missing_after, ", "))
        )
      end
    end
  end
end

-----------------------------------------------------------------------------//
-- Lazy-load handling
-----------------------------------------------------------------------------//

---Setup the plugin module when an event is triggered.
---@param mod PluginModule.Resolved
---@return nil
function Lazy.setup_event_handler(mod)
  local events = Utils.string_or_table(mod.lazy.event)

  local has_very_lazy = false
  for _, event in ipairs(events) do
    if event == "VeryLazy" then
      has_very_lazy = true
      break
    end
  end

  if has_very_lazy then
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        Utils.log.debug(string.format("VeryLazy event triggered for %s", mod.name))
        if mod.async then
          Modules.async_setup_one(mod)
        else
          Modules.setup_one(mod)
        end
      end,
    })
  else
    vim.api.nvim_create_autocmd(events, {
      once = true,
      callback = function(args)
        Utils.log.debug(string.format("Event %s triggered for %s", args.event, mod.name))
        if mod.async then
          Modules.async_setup_one(mod)
        else
          Modules.setup_one(mod)
        end
      end,
    })
  end
end

---Setup the plugin module when a filetype is detected.
---@param mod PluginModule.Resolved
---@return nil
function Lazy.setup_ft_handler(mod)
  local fts = Utils.string_or_table(mod.lazy.ft)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = fts,
    once = true,
    callback = function(args)
      Utils.log.debug(string.format("FileType %s triggered for %s", args.match, mod.name))
      if mod.async then
        Modules.async_setup_one(mod)
      else
        Modules.setup_one(mod)
      end
    end,
  })
end

---Setup the plugin module when a key is pressed.
---@param mod PluginModule.Resolved
---@return nil
function Lazy.setup_keymap_handler(mod)
  local keys = Utils.string_or_table(mod.lazy.keys)
  local potential_keys = { "n", "v", "x", "o" }

  for _, key in ipairs(keys) do
    vim.keymap.set(potential_keys, key, function()
      Utils.log.debug(string.format("Key %s pressed for %s", key, mod.name))

      pcall(vim.keymap.del, potential_keys, key)

      -- actual keymap function to be called after setup
      local success_fn = function()
        vim.schedule(function()
          vim.api.nvim_feedkeys(vim.keycode(key), "m", false)
        end)
      end

      if mod.async then
        Modules.async_setup_one(mod, nil, function(success, err)
          if success then
            success_fn()
          else
            Utils.log.error(string.format("Failed to load %s on key press: %s", mod.name, err or "unknown"))
          end
        end)
      else
        local ok, err = Modules.setup_one(mod)
        if ok then
          success_fn()
        else
          Utils.log.error(string.format("Failed to load %s on key press: %s", mod.name, err or "unknown"))
        end
      end
    end, { noremap = true, silent = true, desc = "Lazy: " .. mod.name })
  end
end

---Setup the plugin module when a command is executed.
---@param mod PluginModule.Resolved
---@return nil
function Lazy.setup_cmd_handler(mod)
  local cmds = Utils.string_or_table(mod.lazy.cmd)
  for _, name in ipairs(cmds) do
    vim.api.nvim_create_user_command(name, function(opts)
      Utils.log.debug(string.format("Command %s executed for %s", name, mod.name))

      -- actual command function to be called after setup
      local success_fn = function()
        vim.schedule(function()
          local cmd_str = opts.bang and string.format("%s! %s", name, opts.args)
            or string.format("%s %s", name, opts.args)
          vim.cmd(cmd_str)
        end)
      end

      if mod.async then
        Modules.async_setup_one(mod, nil, function(success, err)
          if success then
            success_fn()
          else
            Utils.log.error(string.format("Failed to load %s on command: %s", mod.name, err or "unknown"))
          end
        end)
      else
        local ok, err = Modules.setup_one(mod)
        if ok then
          success_fn()
        else
          Utils.log.error(string.format("Failed to load %s on command: %s", mod.name, err or "unknown"))
        end
      end
    end, { bang = true, nargs = "*" })
  end
end

---Setup the plugin module when an LSP client attaches.
---@param mod PluginModule.Resolved
---@return nil
function Lazy.setup_on_lsp_attach_handler(mod)
  local allowed = Utils.string_or_table(mod.lazy.on_lsp_attach)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and vim.tbl_contains(allowed, client.name) then
        Utils.log.debug(string.format("LSP %s attached, loading %s", client.name, mod.name))
        if mod.async then
          Modules.async_setup_one(mod)
        else
          Modules.setup_one(mod)
        end
      end
    end,
  })
end

---Handle lazy-loading of a plugin module.
---@param mod PluginModule.Resolved
---@return nil
function Lazy.lazy_handlers(mod)
  local l = mod.lazy
  if type(l) ~= "table" then
    return
  end

  local handlers_set = 0
  if l.event then
    Lazy.setup_event_handler(mod)
    handlers_set = handlers_set + 1
  end

  if l.ft then
    Lazy.setup_ft_handler(mod)
    handlers_set = handlers_set + 1
  end

  if l.keys then
    Lazy.setup_keymap_handler(mod)
    handlers_set = handlers_set + 1
  end

  if l.cmd then
    Lazy.setup_cmd_handler(mod)
    handlers_set = handlers_set + 1
  end

  if l.on_lsp_attach then
    Lazy.setup_on_lsp_attach_handler(mod)
    handlers_set = handlers_set + 1
  end

  if handlers_set == 0 then
    Utils.log.warn(string.format("Module %s has lazy=true but no lazy handlers configured", mod.name))
  end
end

-----------------------------------------------------------------------------//
-- Install (vim.pack.add)
-----------------------------------------------------------------------------//

---Install all installable (vim.pack) discovered modules so that we don't have to install one by one.
---@return nil
function Modules.install_modules()
  local remote_registry = {}
  local local_count = 0

  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local = Utils.is_local_dev_plugin(reg)
        if not is_local then
          table.insert(remote_registry, reg)
        else
          local_count = local_count + 1
        end
      end
    end
  end

  Utils.log.debug(string.format("Found %d remote plugins, %d local plugins", #remote_registry, local_count))

  if #remote_registry > 0 then
    local install_start = vim.uv.hrtime()
    vim.pack.add(remote_registry, {
      confirm = false,
      load = function() end,
    })
    local install_ms = (vim.uv.hrtime() - install_start) / 1e6
    Utils.log.debug(string.format("Added %d remote plugins to pack in %.2fms", #remote_registry, install_ms))
  end
end

-----------------------------------------------------------------------------//
-- Setup modules
-----------------------------------------------------------------------------//

---Setup all discovered modules
---@return nil
function Modules.setup_modules()
  local immediate_count = 0
  local lazy_count = 0
  local after_count = 0

  for _, mod in ipairs(sorted_modules) do
    -- skip modules that have "after" dependencies - they'll be triggered later
    local has_after_deps = #mod.after > 0

    if not has_after_deps then
      if mod.lazy then
        Lazy.lazy_handlers(mod)
        lazy_count = lazy_count + 1
      else
        if mod.async then
          Modules.async_setup_one(mod)
        else
          Modules.setup_one(mod)
        end
        immediate_count = immediate_count + 1
      end
    else
      -- for modules with "after" dependencies, check if all are already loaded
      local all_after_loaded = true
      for _, after_name in ipairs(mod.after) do
        local after_mod = mod_map[after_name] or mod_map[string.format("%s.%s", M.config.mod_root, after_name)]
        if not after_mod or not after_mod.loaded then
          all_after_loaded = false
          break
        end
      end

      if all_after_loaded then
        -- all "after" deps are already loaded, load immediately
        if mod.lazy then
          Lazy.lazy_handlers(mod)
          lazy_count = lazy_count + 1
        else
          if mod.async then
            Modules.async_setup_one(mod)
          else
            Modules.setup_one(mod)
          end
          immediate_count = immediate_count + 1
        end
      else
        after_count = after_count + 1
      end
      -- otherwise, the module will be triggered when its dependencies load
    end
  end

  Utils.log.debug(
    string.format("Module setup: %d immediate, %d lazy, %d waiting for deps", immediate_count, lazy_count, after_count)
  )
end

-----------------------------------------------------------------------------//
-- Keymaps
-----------------------------------------------------------------------------//

---Setup keymaps for plugin management.
---@return nil
local function setup_keymaps()
  vim.keymap.set("n", "<leader>p", "", { desc = "plugins" })
  vim.keymap.set("n", "<leader>pu", Utils.update_all_packages, { desc = "[vim.pack] Update plugins" })
  vim.keymap.set("n", "<leader>px", Utils.remove_all_packages, { desc = "[vim.pack] Clear all plugins" })
  vim.keymap.set("n", "<leader>ps", Utils.sync_packages, { desc = "[vim.pack] Sync deleted packages" })
  vim.keymap.set("n", "<leader>pd", Utils.refresh_local_dev_plugins, { desc = "[local] Refresh local dev plugins" })
  vim.keymap.set(
    "n",
    "<leader>pc",
    Utils.cleanup_orphaned_local_dev_plugins,
    { desc = "[local] Cleanup orphaned local dev plugins" }
  )
  vim.keymap.set("n", "<leader>pr", function()
    local retried = M.retry_failed_modules()
    if retried > 0 then
      Utils.log.info(string.format("Retried %d modules", retried))
    end
  end, { desc = "Retry failed plugins" })
  vim.keymap.set("n", "<leader>pi", "", { desc = "info" })
  vim.keymap.set("n", "<leader>pis", Utils.print_plugin_status, { desc = "Plugin status" })
  vim.keymap.set("n", "<leader>pir", Utils.print_resolution_timeline, { desc = "Plugin resolution" })
  vim.keymap.set("n", "<leader>pif", Utils.print_failed_plugins, { desc = "Show failed plugins" })
  vim.keymap.set("n", "<leader>pih", Utils.print_plugin_health, { desc = "Plugin health check" })
  vim.keymap.set("n", "<leader>pl", function()
    Utils.log.level = Utils.log.level == LOG_LEVELS.DEBUG and LOG_LEVELS.INFO or LOG_LEVELS.DEBUG
    Utils.log.info(string.format("Debug logging %s", Utils.log.level == LOG_LEVELS.DEBUG and "enabled" or "disabled"))
  end, { desc = "Toggle debug logging" })
end

-----------------------------------------------------------------------------//
-- Setup Autocmd
-----------------------------------------------------------------------------//

---Setup post-update autocmd for `PackChanged` event
---@return nil
local function setup_post_update_autocmd()
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local data = ev.data

      if data.kind == "update" or data.kind == "install" then
        vim.schedule(function()
          local name = data.spec.name
          Utils.log.debug(string.format("Pack changed event for %s (%s)", name, data.kind))

          for _, mod in ipairs(sorted_modules) do
            if mod.name == name and mod.post_pack_changed then
              Utils.log.debug(string.format("Running post_pack_changed for %s", name))
              local ok, err = pcall(mod.post_pack_changed)
              if not ok then
                Utils.log.error(string.format("post_pack_changed failed for %s: %s", name, err))
              end
              break
            end
          end
        end)
      end
    end,
  })
end

---Setup deferred autocmd to trigger `VeryLazy` event
---@return nil
local function setup_deferred_autocmd()
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      -- Schedule so it runs after all VimEnter autocommands
      Utils.log.debug("Triggering VeryLazy event")
      vim.schedule(function()
        vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
      end)
    end,
  })
end

-----------------------------------------------------------------------------//
-- Public API
-----------------------------------------------------------------------------//

---@type PluginModule.Config
local default_config = {
  mod_root = "plugins",
  path_to_mod_root = "/lua/",
  setup_timeout = DEFAULT_SETUP_TIMEOUT,
  max_retries = DEFAULT_MAX_RETRIES,
  async_slice_ms = DEFAULT_ASYNC_SLICE_MS,
  slow_load_threshold = 100,
  log_level = "INFO", -- DEBUG, INFO, WARN, ERROR
  local_dev_config = {
    base_dir = vim.fn.expand("~/Dev"),
    use_symlinks = true,
  },
}

---@type PluginModule.Config
M.config = {}

---Initialize the plugin manager.
---@param user_config? PluginModule.Config
---@return boolean success, string? error_message
function M.setup(user_config)
  if did_setup then
    return true
  end

  local config = vim.tbl_deep_extend("force", default_config, user_config or {})
  local config_ok, config_err = Utils.validate_config(config)
  if not config_ok then
    Utils.log.error(string.format("Invalid configuration: %s", config_err))
    return false, config_err
  end

  M.config = config

  if config.log_level then
    local level_map = {
      DEBUG = LOG_LEVELS.DEBUG,
      INFO = LOG_LEVELS.INFO,
      WARN = LOG_LEVELS.WARN,
      ERROR = LOG_LEVELS.ERROR,
    }
    Utils.log.level = level_map[config.log_level:upper()] or LOG_LEVELS.INFO
  end

  mod_base_path = string.format("%s%s%s", vim.fn.stdpath("config"), M.config.path_to_mod_root, M.config.mod_root)

  Utils.log.debug(string.format("Plugin manager setup starting, mod_base_path: %s", mod_base_path))

  local setup_start = vim.uv.hrtime()

  local modules = Modules.discover()

  if #modules == 0 then
    Utils.log.warn("No plugin modules discovered")
    did_setup = true
    return true
  end

  local sort_ok, sort_err = Modules.sort(modules)
  if not sort_ok then
    Utils.log.error(string.format("Failed to sort modules: %s", sort_err))
    return false, sort_err
  end

  setup_deferred_autocmd()
  setup_post_update_autocmd()
  Modules.install_modules()
  Modules.setup_modules()
  setup_keymaps()

  local setup_ms = (vim.uv.hrtime() - setup_start) / 1e6
  Utils.log.debug(string.format("Plugin manager setup completed in %.2fms", setup_ms))

  did_setup = true
  return true
end

---Get a list of plugins
---@param query? boolean|fun(PluginModule.Resolved):boolean|PluginModule.Resolved[]
---@return PluginModule.Resolved[]
function M.get_plugins(query)
  if query == nil then
    return sorted_modules
  end
  if type(query) == "boolean" then
    return vim.tbl_filter(function(m)
      return m.loaded == query
    end, sorted_modules)
  end

  if type(query) == "function" then
    return vim.tbl_filter(query, sorted_modules)
  end

  return sorted_modules
end

---Get plugin statistics
---@return table stats
function M.get_stats()
  local stats = {
    total = #sorted_modules,
    loaded = 0,
    failed = 0,
    lazy = 0,
    local_dev = 0,
    avg_load_time = 0,
    slowest_plugin = nil,
    total_load_time = 0,
  }

  local load_times = {}

  for _, mod in ipairs(sorted_modules) do
    if mod.loaded then
      stats.loaded = stats.loaded + 1
      if mod.load_time_ms then
        table.insert(load_times, mod.load_time_ms)
        stats.total_load_time = stats.total_load_time + mod.load_time_ms
        if not stats.slowest_plugin or mod.load_time_ms > stats.slowest_plugin.load_time_ms then
          stats.slowest_plugin = mod
        end
      end
    end

    if mod.failed then
      stats.failed = stats.failed + 1
    end

    if mod.lazy then
      stats.lazy = stats.lazy + 1
    end

    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        if Utils.is_local_dev_plugin(reg) then
          stats.local_dev = stats.local_dev + 1
          break
        end
      end
    end
  end

  if #load_times > 0 then
    stats.avg_load_time = stats.total_load_time / #load_times
  end

  return stats
end

---Retry loading a failed module
---@param mod_name string
---@return boolean success
function M.retry_module(mod_name)
  local mod = mod_map[mod_name]
  if not mod then
    Utils.log.error(("Module not found: %s"):format(mod_name))
    return false
  end

  if not mod.failed then
    Utils.log.warn(("Module %s has not failed"):format(mod_name))
    return true
  end

  mod.retry_count = (mod.retry_count or 0) + 1
  if mod.retry_count > M.config.max_retries then
    Utils.log.error(("Module %s exceeded max retries (%d)"):format(mod_name, M.config.max_retries))
    return false
  end

  -- reset failure state
  mod.failed = false
  mod.failure_reason = nil
  mod.loaded = false

  -- exponential backoff delay
  local delay_ms = math.min(100 * (2 ^ (mod.retry_count - 1)), 2000)

  Utils.log.warn(
    string.format(
      "Retrying module %s (attempt %d/%d) after %dms delay",
      mod_name,
      mod.retry_count,
      M.config.max_retries,
      delay_ms
    )
  )

  vim.defer_fn(function()
    local success, error_msg
    if mod.async then
      Modules.async_setup_one(mod, nil, function(ok, err)
        if ok then
          Utils.log.debug(string.format("Module %s loaded successfully on retry %d", mod_name, mod.retry_count))
        else
          Utils.log.error(string.format("Module %s failed again on retry %d: %s", mod_name, mod.retry_count, err))
        end
      end)
      return true -- async, so we return true for now
    else
      success, error_msg = Modules.setup_one(mod)
      if success then
        Utils.log.debug(string.format("Module %s loaded successfully on retry %d", mod_name, mod.retry_count))
      else
        Utils.log.error(string.format("Module %s failed again on retry %d: %s", mod_name, mod.retry_count, error_msg))
      end
      return success
    end
  end, delay_ms)

  return true
end

---Retry all failed modules
---@return number retried_count
function M.retry_failed_modules()
  local failed_modules = {}
  for _, mod in ipairs(sorted_modules) do
    if mod.failed then
      table.insert(failed_modules, mod.name)
    end
  end

  if #failed_modules == 0 then
    Utils.log.info("No failed modules to retry")
    return 0
  end

  Utils.log.info(string.format("Retrying %d failed modules...", #failed_modules))

  local retried = 0
  for _, mod_name in ipairs(failed_modules) do
    if M.retry_module(mod_name) then
      retried = retried + 1
    end
  end

  return retried
end

---Force reload a specific module
---@param mod_name string
---@return boolean success, string? error_message
function M.reload_module(mod_name)
  local mod = mod_map[mod_name]
  if not mod then
    Utils.log.error(string.format("Module not found: %s", mod_name))
    return false, "Module not found"
  end

  Utils.log.info(string.format("Force reloading module: %s", mod_name))

  -- clear package cache
  package.loaded[mod.path] = nil

  -- reset module state
  mod.loaded = false
  mod.failed = false
  mod.failure_reason = nil
  mod.load_time_ms = nil

  -- attempt reload
  if mod.async then
    Modules.async_setup_one(mod, nil, function(ok, err)
      if ok then
        Utils.log.info(string.format("Module %s reloaded successfully", mod_name))
      else
        Utils.log.error(string.format("Module %s reload failed: %s", mod_name, err))
      end
    end)
    return true
  else
    return Modules.setup_one(mod)
  end
end

return M
