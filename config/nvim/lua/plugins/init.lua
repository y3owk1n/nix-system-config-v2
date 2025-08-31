local M = {}

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

-----------------------------------------------------------------------------//
-- Utilities
-----------------------------------------------------------------------------//

local log = {
  warn = function(msg)
    vim.notify(msg, vim.log.levels.WARN)
  end,
  error = function(msg)
    vim.notify(msg, vim.log.levels.ERROR)
  end,
}

---Parse `vim.v.argv` to extract `+command` CLI flags.
---@return table<string, boolean>
local function argv_cmds()
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
local function string_or_table(x)
  if type(x) == "string" then
    return { x }
  end
  return x
end

---Check if a path exists
---@param path string
---@return boolean
local function path_exists(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil
end

---Check if a registry entry is a local development plugin
---@param registry_entry string|vim.pack.Spec
---@return boolean, string?
---@usage [[
---Eligible formats for local dev plugins:
---1. A string path starting with:
---   - `./` (relative path in current dir)
---   - `/`  (absolute path)
---   - `~`  (home-relative path)
---   Example: "./my-plugin", "~/projects/my-plugin", "/Users/me/dev/my-plugin"
---
---2. A string in the format:
---   - `"local:<plugin-name>"`
---   This will be resolved into a path:
---   `M.config.local_dev_config.base_dir .. "/" .. plugin_name`
---   Example: "local:my-plugin"
---
---3. A table spec (`vim.pack.Spec`) with a `src` field
---   - Same rules as above apply to `src`
---   Example:
---     { src = "./my-plugin" }
---     { src = "local:my-plugin" }
---@usage ]]
local function is_local_dev_plugin(registry_entry)
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

---Setup a local development plugin
---@param registry_entry string|vim.pack.Spec
---@param local_path string
---@return boolean success
local function setup_local_dev_plugin(registry_entry, local_path)
  if not path_exists(local_path) then
    log.error(("Local plugin path does not exist: %s"):format(local_path))
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
  if path_exists(pack_path) then
    vim.fn.delete(pack_path, "rf")
  end

  -- Create parent directory
  vim.fn.mkdir(vim.fn.fnamemodify(pack_path, ":h"), "p")

  -- Create symlink or copy
  if M.config.local_dev_config.use_symlinks then
    -- Create symlink (faster for development)
    local success = vim.uv.fs_symlink(local_path, pack_path)
    if not success then
      log.error(("Failed to create symlink from %s to %s"):format(local_path, pack_path))
      return false
    end
  else
    -- Copy directory (safer but slower)
    local cmd = string.format("cp -r %s %s", vim.fn.shellescape(local_path), vim.fn.shellescape(pack_path))
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      log.error(("Failed to copy local plugin: %s\nError: %s"):format(cmd, result))
      return false
    end
  end

  -- Add to runtimepath immediately so it can be loaded
  vim.opt.runtimepath:prepend(pack_path)

  return true
end

-- keeps the order in which modules were successfully resolved
---@type PluginModule.ResolutionEntry[]
local resolution_order = {}

-- Show a visual timeline of plugin resolution.
local function print_resolution_timeline()
  local lines = { "Resolution sequence:" }
  for i, entry in ipairs(resolution_order) do
    table.insert(
      lines,
      string.format(
        "%2d. [%s] %-30s %-20s %.2f ms",
        i,
        entry.async and "async" or "sync",
        entry.name,
        entry.parent and entry.parent.name or "-",
        entry.ms
      )
    )
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Hacky way to update vim.pack all at once
--
-- NOTE: just doing `vim.pack.update()` does not work for lazy loading plugins, it only update the one that are active
-- so we need to manually provide the list of plugins to update
-- but even if we do that, if lazy loaded plugins rely on the `version` field, it will not get included (maybe a bug?)
-- and the update will always force to main, which is not ideal.
-- to work around this, we manually `vim.pack.add` everything so that things work properly
-- remember to restart nvim afterwards
local function update_all_packages()
  -- Filter out local dev plugins from updates
  local remote_registry = {}
  for _, reg in ipairs(registry_map) do
    local is_local, _ = is_local_dev_plugin(reg)
    if not is_local then
      table.insert(remote_registry, reg)
    end
  end

  if #remote_registry > 0 then
    vim.pack.add(remote_registry)
    local plugins = vim.pack.get()
    local names = {}
    for _, p in ipairs(plugins) do
      local is_local, _ = is_local_dev_plugin(p.spec.src)
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
local function remove_all_packages()
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
local function sync_packages()
  local plugins = vim.pack.get()

  -- normalize the registry map to a list of strings src
  ---@type string[]
  local normalized_registry_map = {}
  for _, p in ipairs(registry_map) do
    local is_local, _ = is_local_dev_plugin(p)
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
local function print_plugin_status()
  local loaded = M.get_plugins(true)
  local not_loaded = M.get_plugins(false)

  local lines = { "Plugin status:" }
  table.insert(lines, string.format("Loaded [%s]:", #loaded))
  for i, entry in ipairs(loaded) do
    local dev_status = ""
    if entry.registry then
      for _, reg in ipairs(entry.registry) do
        local is_local = is_local_dev_plugin(reg)
        if is_local then
          dev_status = " [LOCAL DEV]"
          break
        end
      end
    end
    table.insert(lines, string.format("%2d. %s%s", i, entry.name, dev_status))
  end

  table.insert(lines, string.format("Not loaded [%s]:", #not_loaded))
  for i, entry in ipairs(not_loaded) do
    local dev_status = ""
    if entry.registry then
      for _, reg in ipairs(entry.registry) do
        local is_local = is_local_dev_plugin(reg)
        if is_local then
          dev_status = " [LOCAL DEV]"
          break
        end
      end
    end
    table.insert(lines, string.format("%2d. %s%s", i, entry.name, dev_status))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

---Refresh all local development plugins
local function refresh_local_dev_plugins()
  local refreshed = 0
  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local, local_path = is_local_dev_plugin(reg)
        if is_local and local_path then
          if setup_local_dev_plugin(reg, local_path) then
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
local function get_active_local_dev_plugins()
  local active_plugins = {}
  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local, local_path = is_local_dev_plugin(reg)
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
local function cleanup_orphaned_local_dev_plugins()
  local pack_path = vim.fn.stdpath("data") .. "/site/pack/local"
  local start_path = pack_path .. "/start"
  local opt_path = pack_path .. "/opt"

  if not path_exists(pack_path) then
    vim.notify("No local pack directory found, nothing to clean up")
    return
  end

  local active_plugins = get_active_local_dev_plugins()
  local removed_count = 0
  local removed_plugins = {}

  -- Check both start and opt directories
  for _, dir_path in ipairs({ start_path, opt_path }) do
    if path_exists(dir_path) then
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
                log.error(("Failed to remove: %s"):format(plugin_path))
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
                  log.error(("Failed to remove: %s"):format(plugin_path))
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

-----------------------------------------------------------------------------//
-- Discovery
-----------------------------------------------------------------------------//

---Discover plugin modules from filesystem
---@return PluginModule.Resolved[]
local function discover()
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
        log.error(("Bad file %s: %s"):format(file, chunk))
        goto continue
      end

      local env = setmetatable({ vim = vim }, { __index = _G })
      setfenv(chunk, env)
      local success, mod = pcall(chunk)
      if not success or type(mod) ~= "table" or type(mod.setup) ~= "function" then
        log.warn(("Plugin %s does not export valid setup"):format(path))
        goto continue
      end

      if mod.enabled == false then
        -- log.warn(("Plugin %s is disabled"):format(path))
        goto continue
      end

      local name = mod.name or path
      if argv_cmds()[name:lower()] then
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
        lazy = mod.lazy or false,
        loaded = false,
        registry = mod.registry or {},
        async = parse_boolean(mod.async, true),
        post_pack_changed = mod.post_pack_changed or nil,
      }

      table.insert(modules, entry)
      mod_map[name] = entry
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
-- Topological sort  (Kahn’s algorithm – O(n+m))
-----------------------------------------------------------------------------//

---Topologically sort plugin modules (Kahn’s algorithm).
---@param mods PluginModule.Resolved[]
local function sort_modules(mods)
  -- Build adjacency
  local in_degree, rev = {}, {}
  for _, m in ipairs(mods) do
    in_degree[m.name] = 0
  end
  for _, m in ipairs(mods) do
    for _, req in ipairs(m.requires) do
      local dep = mod_map[req] or mod_map[M.config.mod_root .. "." .. req]
      if dep then
        in_degree[m.name] = in_degree[m.name] + 1
        rev[dep.name] = rev[dep.name] or {}
        table.insert(rev[dep.name], m)
      else
        log.warn(("Missing dependency %s for %s"):format(req, m.name))
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
-- Safe setup
-----------------------------------------------------------------------------//

---Safely setup a plugin module.
---@param mod PluginModule.Resolved
---@param parent? PluginModule.Resolved|nil nil if this is the root module, this is just to visualize the timeline
---@return boolean
local function setup_one(mod, parent)
  if mod.loaded then
    return true
  end

  -- ensure every declared dependency is loaded first
  for _, dep_name in ipairs(mod.requires) do
    local dep = mod_map[dep_name] or mod_map[M.config.mod_root .. "." .. dep_name]
    if not dep then
      log.warn(("Missing dependency %s for %s"):format(dep_name, mod.name))
      return false
    end
    if not setup_one(dep, mod) then -- recursive, but safe: list is topo-sorted
      return false -- abort on first failure
    end
  end

  -- start measuring
  local t0 = vim.uv.hrtime()

  -- setup for local dev or just packadd
  if mod.registry then
    for _, reg in ipairs(mod.registry) do
      local is_local, local_path = is_local_dev_plugin(reg)
      if is_local and local_path then
        setup_local_dev_plugin(reg, local_path)
      else
        pcall(function()
          vim.cmd.packadd(reg.name)
        end)
      end
    end
  end

  -- require the module
  local ok, data = pcall(require, mod.path)
  if not ok then
    log.error(("Failed to require %s: %s"):format(mod.name, data))
    return false
  end

  -- run setup
  local setup_ok, err = pcall(data.setup)
  if not setup_ok then
    log.error(("Setup failed for %s: %s"):format(mod.name, err))
    return false
  end

  -- stop measuring and add to resolution order
  local ms = (vim.uv.hrtime() - t0) / 1e6
  table.insert(resolution_order, { async = false, name = mod.name, ms = ms, parent = parent })

  mod.loaded = true
  return true
end

local ASYNC_SLICE_MS = 16

---Safely setup a module asynchronously.
---@param mod PluginModule.Resolved
---@param parent? PluginModule.Resolved|nil nil if this is the root module, this is just to visualize the timeline
---@param on_done? fun()
local function async_setup_one(mod, parent, on_done)
  if mod.loaded then
    return true
  end

  local co = coroutine.create(function()
    -- 1. synchronous deps (tiny & safe)
    for _, dep_name in ipairs(mod.requires) do
      local dep = mod_map[dep_name] or mod_map[M.config.mod_root .. "." .. dep_name]
      if dep and not dep.loaded then
        -- recurse synchronously (dependencies are cheap)
        local ok = setup_one(dep, mod)
        if not ok then
          return false
        end
      end
    end

    -- 2. setup for local dev or just packadd
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local, local_path = is_local_dev_plugin(reg)
        if is_local and local_path then
          setup_local_dev_plugin(reg, local_path)
        else
          pcall(function()
            vim.cmd.packadd(reg.name)
          end)
        end
      end
    end

    -- 3. require + setup in slices
    local ok, data = pcall(require, mod.path)
    if not ok then
      log.error(("require failed %s: %s"):format(mod.name, data))
      return false
    end

    -- start measuring
    local t0 = vim.uv.hrtime()

    if type(data.setup) == "function" then
      local setup_ok, err = pcall(data.setup)
      if not setup_ok then
        log.error(("setup failed %s: %s"):format(mod.name, err))
        return false
      end
      if (vim.uv.hrtime() - t0) / 1e6 > ASYNC_SLICE_MS then
        coroutine.yield() -- yield to UI
      end
    end

    local ms = (vim.uv.hrtime() - t0) / 1e6
    table.insert(resolution_order, { async = true, name = mod.name, ms = ms, parent = parent })

    mod.loaded = true

    -- vim.notify(("Loaded %s in %.2fms"):format(mod.name, ms), vim.log.levels.INFO)

    return true
  end)

  local function tick()
    local ok, err = coroutine.resume(co)
    if coroutine.status(co) ~= "dead" then
      vim.defer_fn(tick, 0)
    elseif ok then
      if on_done and type(on_done) == "function" then
        on_done()
      end
    elseif not ok then
      -- full traceback to the error
      log.error(("Async setup error %s:\n%s"):format(mod.name, debug.traceback(co, err)))
    end
  end
  tick()
end

-----------------------------------------------------------------------------//
-- Lazy-load wiring
-----------------------------------------------------------------------------//

---Setup the plugin module when an event is triggered.
---@param mod PluginModule.Resolved
local function setup_event_handler(mod)
  local events = string_or_table(mod.lazy.event)

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
          async_setup_one(mod)
        else
          setup_one(mod)
        end
      end,
    })
  else
    vim.api.nvim_create_autocmd(events, {
      once = true,
      callback = function()
        if mod.async then
          async_setup_one(mod)
        else
          setup_one(mod)
        end
      end,
    })
  end
end

---Setup the plugin module when a filetype is detected.
---@param mod PluginModule.Resolved
local function setup_ft_handler(mod)
  local fts = string_or_table(mod.lazy.ft)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = fts,
    once = true,
    callback = function()
      if mod.async then
        async_setup_one(mod)
      else
        setup_one(mod)
      end
    end,
  })
end

---Setup the plugin module when a key is pressed.
---@param mod PluginModule.Resolved
local function setup_keymap_handler(mod)
  local keys = string_or_table(mod.lazy.keys)
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
        async_setup_one(mod, nil, success_fn)
      else
        if setup_one(mod) then
          success_fn()
        end
      end
    end, { noremap = true, silent = true, desc = "Lazy: " .. mod.name })
  end
end

---Setup the plugin module when a command is executed.
---@param mod PluginModule.Resolved
local function setup_cmd_handler(mod)
  local cmds = string_or_table(mod.lazy.cmd)
  for _, name in ipairs(cmds) do
    vim.api.nvim_create_user_command(name, function(opts)
      local success_fn = function()
        vim.schedule(function()
          vim.cmd((opts.bang and "%s! %s" or "%s %s"):format(name, opts.args))
        end)
      end

      if mod.async then
        async_setup_one(mod, nil, success_fn)
      else
        if setup_one(mod) then
          success_fn()
        end
      end
    end, { bang = true, nargs = "*" })
  end
end

local function setup_on_lsp_attach_handler(mod)
  local allowed = string_or_table(mod.lazy.on_lsp_attach)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and vim.tbl_contains(allowed, client.name) then
        if mod.async then
          async_setup_one(mod)
        else
          setup_one(mod)
        end
      end
    end,
  })
end

---Handle lazy-loading of a plugin module.
---@param mod PluginModule.Resolved
local function lazy_handlers(mod)
  local l = mod.lazy
  if type(l) ~= "table" then
    return
  end

  if l.event then
    setup_event_handler(mod)
  end

  if l.ft then
    setup_ft_handler(mod)
  end

  if l.keys then
    setup_keymap_handler(mod)
  end

  if l.cmd then
    setup_cmd_handler(mod)
  end

  if l.on_lsp_attach then
    setup_on_lsp_attach_handler(mod)
  end
end

-----------------------------------------------------------------------------//
-- Install (vim.pack.add)
-----------------------------------------------------------------------------//

---Install all installable (vim.pack) discovered modules so that we don't have to install one by one.
---@return nil
local function install_modules()
  local remote_registry = {}

  for _, mod in ipairs(sorted_modules) do
    if mod.registry then
      for _, reg in ipairs(mod.registry) do
        local is_local = is_local_dev_plugin(reg)
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
-- Setup
-----------------------------------------------------------------------------//

---Setup all discovered modules either by lazy-loading or by calling `setup()` directly
---@return nil
local function setup_modules()
  for _, mod in ipairs(sorted_modules) do
    if mod.lazy then
      lazy_handlers(mod)
    else
      if mod.async then
        async_setup_one(mod)
      else
        setup_one(mod)
      end
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
  vim.keymap.set("n", "<leader>pu", update_all_packages, { desc = "[vim.pack] Update plugins" })
  vim.keymap.set("n", "<leader>px", remove_all_packages, { desc = "[vim.pack] Clear all plugins" })
  vim.keymap.set("n", "<leader>ps", sync_packages, { desc = "[vim.pack] Sync deleted packages" })
  vim.keymap.set("n", "<leader>pi", print_plugin_status, { desc = "Plugin status" })
  vim.keymap.set("n", "<leader>pr", print_resolution_timeline, { desc = "Plugin resolution" })
  vim.keymap.set("n", "<leader>pd", refresh_local_dev_plugins, { desc = "[local] Refresh local dev plugins" })
  vim.keymap.set(
    "n",
    "<leader>pc",
    cleanup_orphaned_local_dev_plugins,
    { desc = "[local] Cleanup orphaned local dev plugins" }
  )
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
  local_dev_config = {
    base_dir = vim.fn.expand("~/Dev"), -- customize this path
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

  local modules = discover()
  sort_modules(modules)
  setup_deferred_autocmd()
  setup_post_update_autocmd()
  install_modules()
  setup_modules()
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

return M
