local M = {}

local Modules = {}
local Utils = {}
local Lazy = {}

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

-- keeps the order in which modules were successfully resolved
---@type PluginModule.ResolutionEntry[]
local resolution_order = {}

local waiting_for = {}

local ASYNC_SLICE_MS = 16

-----------------------------------------------------------------------------//
-- Utilities
-----------------------------------------------------------------------------//

Utils.log = {
  warn = function(msg)
    vim.notify(msg, vim.log.levels.WARN)
  end,
  error = function(msg)
    vim.notify(msg, vim.log.levels.ERROR)
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
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil
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
    return true, vim.fn.expand(src)
  end

  -- Check if it's in the format "local:plugin-name"
  local plugin_name = src:match("^local:(.+)")
  if plugin_name then
    local local_path = M.config.local_dev_config.base_dir .. "/" .. plugin_name
    return true, vim.fn.expand(local_path)
  end

  return false
end

-- Show a visual timeline of plugin resolution.
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
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Hacky way to update vim.pack all at once
function Utils.update_all_packages()
  -- Filter out local dev plugins from updates
  local remote_registry = {}
  for _, reg in ipairs(registry_map) do
    local is_local, _ = Utils.is_local_dev_plugin(reg)
    if not is_local then
      table.insert(remote_registry, reg)
    end
  end

  if #remote_registry > 0 then
    vim.pack.add(remote_registry)
    local plugins = vim.pack.get()
    local names = {}
    for _, p in ipairs(plugins) do
      local is_local, _ = Utils.is_local_dev_plugin(p.spec.src)
      if not is_local then
        table.insert(names, p.spec.name)
      end
    end
    if #names > 0 then
      vim.pack.update(names)
    end
  end
end

---Remove all packages from vim.pack
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
    vim.notify("No plugins to remove")
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

  local lines = { "Plugin status:" }
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
    table.insert(lines, string.format("%2d. %s%s%s", i, entry.name, dev_status, status_suffix))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

---Refresh all local development plugins
function Utils.refresh_local_dev_plugins()
  local refreshed = 0
  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local, local_path = Utils.is_local_dev_plugin(reg)
        if is_local and local_path then
          if Utils.setup_local_dev_plugin(reg, local_path) then
            refreshed = refreshed + 1
          end
        end
      end
    end
  end
  vim.notify(("Refreshed %d local development plugins"):format(refreshed))
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
function Utils.cleanup_orphaned_local_dev_plugins()
  local pack_path = vim.fn.stdpath("data") .. "/site/pack/local"
  local start_path = pack_path .. "/start"
  local opt_path = pack_path .. "/opt"

  if not Utils.path_exists(pack_path) then
    vim.notify("No local pack directory found, nothing to clean up")
    return
  end

  local active_plugins = Utils.get_active_local_dev_plugins()
  local removed_count = 0
  local removed_plugins = {}

  -- Check both start and opt directories
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
            local plugin_path = dir_path .. "/" .. name
            local stat = vim.uv.fs_lstat(plugin_path)

            -- Check if it's a symlink (our local dev plugins) or if it's not in active list
            local is_symlink = stat and stat.type == "link"
            local is_orphaned = not active_plugins[name]

            -- Only remove symlinks that are orphaned, or ask about regular directories
            if is_symlink and is_orphaned then
              local success = vim.fn.delete(plugin_path, "rf")
              if success == 0 then
                removed_count = removed_count + 1
                table.insert(removed_plugins, name)
                vim.notify(("Removed orphaned local dev plugin: %s"):format(name))
              else
                Utils.log.error(("Failed to remove: %s"):format(plugin_path))
              end
            elseif is_orphaned and not is_symlink then
              -- For non-symlink directories, let user decide
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
                  vim.notify(("Removed orphaned plugin directory: %s"):format(name))
                else
                  Utils.log.error(("Failed to remove: %s"):format(plugin_path))
                end
              elseif choice == 3 then
                break -- Skip all remaining
              end
            end
          end
        end
      end
    end
  end

  if removed_count > 0 then
    vim.notify(("Cleanup complete: removed %d orphaned plugins"):format(removed_count))
    if #removed_plugins > 0 then
      vim.notify(("Removed plugins: %s"):format(table.concat(removed_plugins, ", ")))
    end
    vim.notify("Restart Neovim to ensure clean state")
  else
    vim.notify("No orphaned local dev plugins found")
  end
end

function Utils.print_failed_plugins()
  local failed = vim.tbl_filter(function(m)
    return m.failed
  end, sorted_modules)
  if #failed == 0 then
    vim.notify("No failed plugins ✓")
    return
  end

  local lines = { string.format("Failed plugins (%d):", #failed) }
  for i, mod in ipairs(failed) do
    table.insert(lines, string.format("%2d. %s: %s", i, mod.name, mod.failure_reason or "unknown"))
    if mod.retry_count and mod.retry_count > 0 then
      table.insert(lines, string.format("     (retried %d times)", mod.retry_count))
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
end

function Utils.print_plugin_health()
  -- Health check
  local issues = {}
  local warnings = 0

  -- Check for failed modules
  for _, mod in ipairs(sorted_modules) do
    if mod.failed then
      table.insert(issues, string.format("✗ %s: %s", mod.name, mod.failure_reason or "unknown error"))
    end

    -- Check load times
    if mod.loaded and mod.load_time_ms and mod.load_time_ms > 100 then
      warnings = warnings + 1
      if warnings <= 5 then -- Don't spam too many warnings
        table.insert(issues, string.format("⚠ %s: slow load time (%.2fms)", mod.name, mod.load_time_ms))
      end
    end
  end

  -- Check for missing local dev plugins
  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local, local_path = Utils.is_local_dev_plugin(reg)
        if is_local and local_path and not Utils.path_exists(local_path) then
          table.insert(issues, string.format("✗ Local plugin path missing: %s", local_path))
        end
      end
    end
  end

  if #issues == 0 then
    vim.notify("All plugins healthy ✓", vim.log.levels.INFO)
  else
    local lines = { "Plugin health issues found:" }
    vim.list_extend(lines, issues)
    if warnings > 5 then
      table.insert(lines, string.format("... and %d more performance warnings", warnings - 5))
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
  end
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

  local files = vim.fs.find(function(name)
    return name:sub(-4) == ".lua"
  end, { type = "file", limit = math.huge, path = mod_base_path })

  for _, file in ipairs(files) do
    local rel = file:sub(#mod_base_path + 2, -5):gsub("/", ".")
    if rel ~= "init" then
      local path = M.config.mod_root .. "." .. rel
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
        -- log.warn(("Plugin %s is disabled"):format(path))
        goto continue
      end

      local name = mod.name or path
      if Utils.argv_cmds()[name:lower()] then
        mod.lazy = false
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

      -- Set up "after" watchers during discovery
      for _, after_name in ipairs(entry.after) do
        waiting_for[after_name] = waiting_for[after_name] or {}
        table.insert(waiting_for[after_name], entry)
      end

      for _, reg in ipairs(entry.registry) do
        table.insert(registry_map, reg)
      end
      ::continue::
    end
  end

  _discovered_modules = modules
  return modules
end

-----------------------------------------------------------------------------//
-- Topological sort  (Kahn's algorithm – O(n+m))
-----------------------------------------------------------------------------//

---Topologically sort plugin modules (Kahn's algorithm).
---@param mods PluginModule.Resolved[]
function Modules.sort(mods)
  -- Build adjacency
  local in_degree, rev = {}, {}
  for _, m in ipairs(mods) do
    in_degree[m.name] = 0
  end

  -- Handle `requires`
  for _, m in ipairs(mods) do
    for _, req in ipairs(m.requires) do
      local dep = mod_map[req] or mod_map[M.config.mod_root .. "." .. req]
      if dep then
        in_degree[m.name] = in_degree[m.name] + 1
        rev[dep.name] = rev[dep.name] or {}
        table.insert(rev[dep.name], m)
      else
        Utils.log.warn(("Missing dependency %s for %s"):format(req, m.name))
      end
    end
  end

  -- Priority queue (min-heap on priority)
  ---@type PluginModule.Resolved[]
  local pq = {}
  for _, m in ipairs(mods) do
    if in_degree[m.name] == 0 then
      table.insert(pq, m)
    end
  end
  table.sort(pq, function(a, b)
    return a.priority < b.priority
  end)

  ---@type PluginModule.Resolved[]
  local out = {}
  while #pq > 0 do
    local cur = table.remove(pq, 1)
    table.insert(out, cur)
    for _, next_mod in ipairs(rev[cur.name] or {}) do
      in_degree[next_mod.name] = in_degree[next_mod.name] - 1
      if in_degree[next_mod.name] == 0 then
        table.insert(pq, next_mod)
        table.sort(pq, function(a, b)
          return a.priority < b.priority
        end)
      end
    end
  end

  sorted_modules = out
end

-----------------------------------------------------------------------------//
-- Safe setup with improved error recovery
-----------------------------------------------------------------------------//

---Safely setup a plugin module with improved error recovery.
---@param mod PluginModule.Resolved
---@param parent? PluginModule.Resolved|nil nil if this is the root module, this is just to visualize the timeline
---@return boolean success, string? error_message
function Modules.setup_one(mod, parent)
  if mod.loaded then
    return true
  end

  if mod.failed then
    return false, "Module previously failed"
  end

  -- Only check "requires" dependencies for startup
  local failed_deps = {}
  for _, dep_name in ipairs(mod.requires) do
    local dep = mod_map[dep_name] or mod_map[M.config.mod_root .. "." .. dep_name]
    if not dep then
      table.insert(failed_deps, dep_name)
    else
      local dep_ok, dep_err = Modules.setup_one(dep, mod) -- recursive, but safe: list is topo-sorted
      if not dep_ok then
        table.insert(failed_deps, string.format("%s (%s)", dep_name, dep_err or "unknown error"))
      end
    end
  end

  -- If any dependencies failed, mark this module as failed but continue with others
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

  -- If registry setup had errors but we can still try to require the module
  if #errors > 0 then
    Utils.log.warn(string.format("Registry issues for %s: %s", mod.name, table.concat(errors, "; ")))
    -- Don't return false yet - maybe the module can still be required
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

  -- Validate that the module has a setup function
  if type(data.setup) ~= "function" then
    local error_msg = "Module does not export a setup function"
    Utils.log.error(string.format("Module %s: %s", mod.name, error_msg))
    mod.failed = true
    mod.failure_reason = error_msg
    return false, error_msg
  end

  -- run setup with timeout protection
  local setup_ok, setup_err
  if M.config.setup_timeout and M.config.setup_timeout > 0 then
    -- Add timeout protection if configured
    local timeout_ms = M.config.setup_timeout
    local timed_out = false

    local timer = vim.uv.new_timer()
    if timer and timeout_ms then
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

  -- Trigger any "after" modules
  Modules.trigger_after_modules(mod.name)

  -- Log success with any warnings
  if #errors > 0 then
    Utils.log.warn(string.format("Module %s loaded with warnings (%.2fms)", mod.name, ms))
  end

  return true
end

---Safely setup a module asynchronously with improved error recovery.
---@param mod PluginModule.Resolved
---@param parent? PluginModule.Resolved|nil nil if this is the root module, this is just to visualize the timeline
---@param on_done? fun(success: boolean, error?: string)
function Modules.async_setup_one(mod, parent, on_done)
  if mod.loaded then
    if on_done then
      on_done(true)
    end
    return true
  end

  if mod.failed then
    if on_done then
      on_done(false, mod.failure_reason)
    end
    return false
  end

  local co = coroutine.create(function()
    local errors = {}

    -- Handle hard dependencies (requires) - must succeed
    local failed_deps = {}
    for _, dep_name in ipairs(mod.requires) do
      local dep = mod_map[dep_name] or mod_map[M.config.mod_root .. "." .. dep_name]
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

    -- Handle soft dependencies (after) - don't fail if they fail
    local after_warnings = {}
    for _, after_name in ipairs(mod.after) do
      local after_mod = mod_map[after_name] or mod_map[M.config.mod_root .. "." .. after_name]
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

    -- 2. setup for local dev or just packadd
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

    -- 3. require + setup in slices
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

    -- Validate setup function
    if type(data.setup) ~= "function" then
      local error_msg = "Module does not export a setup function"
      mod.failed = true
      mod.failure_reason = error_msg
      Utils.log.error(string.format("Async module %s: %s", mod.name, error_msg))
      return false, error_msg
    end

    -- Run setup with slice yielding
    local setup_start = vim.uv.hrtime()
    local setup_ok, setup_err = pcall(data.setup)

    if not setup_ok then
      local error_msg = string.format("Async setup failed: %s", setup_err)
      mod.failed = true
      mod.failure_reason = error_msg
      Utils.log.error(string.format("Async module %s: %s", mod.name, error_msg))

      return false, error_msg
    end

    -- Check if we should yield after setup (if it took too long)
    local setup_duration = (vim.uv.hrtime() - setup_start) / 1e6
    if setup_duration > ASYNC_SLICE_MS then
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

    -- Trigger any "after" modules
    Modules.trigger_after_modules(mod.name)

    -- Log with any warnings
    if #errors > 0 then
      Utils.log.warn(string.format("Async module %s loaded with warnings (%.2fms)", mod.name, ms))
    end

    return true
  end)

  local function tick()
    local co_ok, success_or_err, error_msg = coroutine.resume(co)

    if not co_ok then
      -- Coroutine itself failed (programming error)
      local full_error = string.format("Coroutine error in %s: %s", mod.name, debug.traceback(co, success_or_err))
      Utils.log.error(full_error)
      mod.failed = true
      mod.failure_reason = success_or_err
      if on_done then
        on_done(false, success_or_err)
      end
      return
    end

    if coroutine.status(co) == "dead" then
      -- Coroutine completed
      local success = success_or_err
      if success then
        if on_done then
          on_done(true)
        end
      else
        if on_done then
          on_done(false, error_msg)
        end
      end
    else
      -- Coroutine yielded, schedule next tick
      vim.defer_fn(tick, 0)
    end
  end

  tick()
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
    plugin_name = vim.fn.fnamemodify(local_path, ":t")
  elseif registry_entry.name then
    plugin_name = registry_entry.name
  else
    plugin_name = vim.fn.fnamemodify(local_path, ":t")
  end

  local pack_path = vim.fn.stdpath("data") .. "/site/pack/local/start/" .. plugin_name

  -- Remove existing installation if it exists
  if Utils.path_exists(pack_path) then
    vim.fn.delete(pack_path, "rf")
  end

  -- Create parent directory
  vim.fn.mkdir(vim.fn.fnamemodify(pack_path, ":h"), "p")

  -- Create symlink or copy
  if M.config.local_dev_config.use_symlinks then
    -- Create symlink (faster for development)
    local success = vim.uv.fs_symlink(local_path, pack_path)
    if not success then
      Utils.log.error(("Failed to create symlink from %s to %s"):format(local_path, pack_path))
      return false
    end
  else
    -- Copy directory (safer but slower)
    local cmd = string.format("cp -r %s %s", vim.fn.shellescape(local_path), vim.fn.shellescape(pack_path))
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      Utils.log.error(("Failed to copy local plugin: %s\nError: %s"):format(cmd, result))
      return false
    end
  end

  -- Add to runtimepath immediately so it can be loaded
  vim.opt.runtimepath:prepend(pack_path)

  return true
end

-----------------------------------------------------------------------------//
-- After-load handling
-----------------------------------------------------------------------------//

-- Function to trigger modules waiting for a specific plugin
function Modules.trigger_after_modules(loaded_module_name)
  local waiters = waiting_for[loaded_module_name]
  if not waiters then
    return
  end

  for _, waiter in ipairs(waiters) do
    if not waiter.loaded and not waiter.failed then
      -- Check if ALL "after" dependencies are now satisfied
      local all_after_loaded = true
      for _, after_name in ipairs(waiter.after) do
        local after_mod = mod_map[after_name] or mod_map[M.config.mod_root .. "." .. after_name]
        if after_mod and not after_mod.loaded then
          all_after_loaded = false
          break
        end
      end

      if all_after_loaded then
        vim.schedule(function()
          if waiter.async then
            Modules.async_setup_one(waiter)
          else
            Modules.setup_one(waiter)
          end
        end)
      end
    end
  end
end

-----------------------------------------------------------------------------//
-- Lazy-load wiring
-----------------------------------------------------------------------------//

---Setup the plugin module when an event is triggered.
---@param mod PluginModule.Resolved
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
      callback = function()
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
function Lazy.setup_ft_handler(mod)
  local fts = Utils.string_or_table(mod.lazy.ft)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = fts,
    once = true,
    callback = function()
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
function Lazy.setup_keymap_handler(mod)
  local keys = Utils.string_or_table(mod.lazy.keys)
  local potential_keys = { "n", "v", "x", "o" }

  for _, key in ipairs(keys) do
    vim.keymap.set(potential_keys, key, function()
      pcall(vim.keymap.del, potential_keys, key)

      local success_fn = function()
        vim.schedule(function()
          vim.api.nvim_feedkeys(vim.keycode(key), "m", false)
        end)
      end

      if mod.async then
        Modules.async_setup_one(mod, nil, success_fn)
      else
        if Modules.setup_one(mod) then
          success_fn()
        end
      end
    end, { noremap = true, silent = true, desc = "Lazy: " .. mod.name })
  end
end

---Setup the plugin module when a command is executed.
---@param mod PluginModule.Resolved
function Lazy.setup_cmd_handler(mod)
  local cmds = Utils.string_or_table(mod.lazy.cmd)
  for _, name in ipairs(cmds) do
    vim.api.nvim_create_user_command(name, function(opts)
      local success_fn = function()
        vim.schedule(function()
          vim.cmd((opts.bang and "%s! %s" or "%s %s"):format(name, opts.args))
        end)
      end

      if mod.async then
        Modules.async_setup_one(mod, nil, success_fn)
      else
        if Modules.setup_one(mod) then
          success_fn()
        end
      end
    end, { bang = true, nargs = "*" })
  end
end

function Lazy.setup_on_lsp_attach_handler(mod)
  local allowed = Utils.string_or_table(mod.lazy.on_lsp_attach)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and vim.tbl_contains(allowed, client.name) then
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
function Lazy.lazy_handlers(mod)
  local l = mod.lazy
  if type(l) ~= "table" then
    return
  end

  if l.event then
    Lazy.setup_event_handler(mod)
  end

  if l.ft then
    Lazy.setup_ft_handler(mod)
  end

  if l.keys then
    Lazy.setup_keymap_handler(mod)
  end

  if l.cmd then
    Lazy.setup_cmd_handler(mod)
  end

  if l.on_lsp_attach then
    Lazy.setup_on_lsp_attach_handler(mod)
  end
end

-----------------------------------------------------------------------------//
-- Install (vim.pack.add)
-----------------------------------------------------------------------------//

---Install all installable (vim.pack) discovered modules so that we don't have to install one by one.
---@return nil
function Modules.install_modules()
  local remote_registry = {}

  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local = Utils.is_local_dev_plugin(reg)
        if not is_local then
          table.insert(remote_registry, reg)
        end
      end
    end
  end

  if #remote_registry > 0 then
    vim.pack.add(remote_registry, {
      confirm = false,
      load = function() end,
    })
  end
end

-----------------------------------------------------------------------------//
-- Setup with improved error recovery
-----------------------------------------------------------------------------//

---Setup all discovered modules
---@return nil
function Modules.setup_modules()
  for _, mod in ipairs(sorted_modules) do
    -- Skip modules that have "after" dependencies - they'll be triggered later
    local has_after_deps = #mod.after > 0

    if not has_after_deps then
      if mod.lazy then
        Lazy.lazy_handlers(mod)
      else
        if mod.async then
          Modules.async_setup_one(mod)
        else
          Modules.setup_one(mod)
        end
      end
    else
      -- For modules with "after" dependencies, check if all are already loaded
      local all_after_loaded = true
      for _, after_name in ipairs(mod.after) do
        local after_mod = mod_map[after_name] or mod_map[M.config.mod_root .. "." .. after_name]
        if not after_mod or not after_mod.loaded then
          all_after_loaded = false
          break
        end
      end

      if all_after_loaded then
        -- All "after" deps are already loaded, load immediately
        if mod.lazy then
          Lazy.lazy_handlers(mod)
        else
          if mod.async then
            Modules.async_setup_one(mod)
          else
            Modules.setup_one(mod)
          end
        end
      end
      -- Otherwise, the module will be triggered when its dependencies load
    end
  end
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
      vim.notify(string.format("Retried %d modules", retried))
    end
  end, { desc = "Retry failed plugins" })
  vim.keymap.set("n", "<leader>pi", "", { desc = "info" })
  vim.keymap.set("n", "<leader>pis", Utils.print_plugin_status, { desc = "Plugin status" })
  vim.keymap.set("n", "<leader>pir", Utils.print_resolution_timeline, { desc = "Plugin resolution" })
  vim.keymap.set("n", "<leader>pif", Utils.print_failed_plugins, { desc = "Show failed plugins" })
  vim.keymap.set("n", "<leader>pih", Utils.print_plugin_health, { desc = "Plugin health check" })
end

-----------------------------------------------------------------------------//
-- Setup Autocmd
-----------------------------------------------------------------------------//

local function setup_post_update_autocmd()
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local data = ev.data

      if data.kind == "update" or data.kind == "install" then
        vim.schedule(function()
          local name = data.spec.name

          for _, mod in ipairs(sorted_modules) do
            if mod.name == name and mod.post_pack_changed then
              mod.post_pack_changed()
              break
            end
          end
        end)
      end
    end,
  })
end

local function setup_deferred_autocmd()
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      -- Schedule so it runs after all VimEnter autocommands
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
  setup_timeout = nil, -- No timeout by default, set to number of ms to enable
  max_retries = 1, -- Number of retry attempts for failed modules
  local_dev_config = {
    base_dir = vim.fn.expand("~/Dev"),
    use_symlinks = true,
  },
}

---@type PluginModule.Config
M.config = {}

---Initialize the plugin manager.
---@param user_config? PluginModule.Config
---@return nil
function M.setup(user_config)
  if did_setup then
    return
  end

  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})
  mod_base_path = vim.fn.stdpath("config") .. M.config.path_to_mod_root .. M.config.mod_root

  local modules = Modules.discover()
  Modules.sort(modules)
  setup_deferred_autocmd()
  setup_post_update_autocmd()
  Modules.install_modules()
  Modules.setup_modules()
  setup_keymaps()

  did_setup = true
end

---@return PluginModule.Resolved[]
function M.get_plugins(query)
  if query == nil then
    return sorted_modules
  end
  local out = {}
  for _, m in ipairs(sorted_modules) do
    if m.loaded == query then
      table.insert(out, m)
    end
  end
  return out
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

  -- Reset failure state
  mod.failed = false
  mod.failure_reason = nil
  mod.loaded = false

  Utils.log.warn(("Retrying module %s (attempt %d/%d)"):format(mod_name, mod.retry_count, M.config.max_retries))

  local success, error_msg
  if mod.async then
    Modules.async_setup_one(mod, nil, function(ok, err)
      if ok then
        Utils.log.warn(("Module %s loaded successfully on retry"):format(mod_name))
      else
        Utils.log.error(("Module %s failed again: %s"):format(mod_name, err))
      end
    end)
    return true -- async, so we return true for now
  else
    success, error_msg = Modules.setup_one(mod)
    if success then
      Utils.log.warn(("Module %s loaded successfully on retry"):format(mod_name))
    else
      Utils.log.error(("Module %s failed again: %s"):format(mod_name, error_msg))
    end
    return success
  end
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
    vim.notify("No failed modules to retry")
    return 0
  end

  vim.notify(("Retrying %d failed modules..."):format(#failed_modules))

  local retried = 0
  for _, mod_name in ipairs(failed_modules) do
    if M.retry_module(mod_name) then
      retried = retried + 1
    end
  end

  return retried
end

return M
