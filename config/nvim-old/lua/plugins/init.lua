local M = {}

-----------------------------------------------------------------------------//
-- Configuration
-----------------------------------------------------------------------------//

local mod_root = "plugins"
local mod_base_path = vim.fn.stdpath("config") .. "/lua/" .. mod_root

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
  vim.pack.add(registry_map)
  local plugins = vim.pack.get()
  local names = vim.tbl_map(function(p)
    return p.spec.name
  end, plugins)
  vim.pack.update(names)
end

---Remove all packages from vim.pack
local function remove_all_packages()
  local plugins = vim.pack.get()
  local names = vim.tbl_map(function(p)
    return p.spec.name
  end, plugins)
  vim.pack.del(names)
end

---Synchronize packages from registry to the vim.pack.
local function sync_packages()
  local plugins = vim.pack.get()

  -- normalize the registry map to a list of strings src
  ---@type string[]
  local normalized_registry_map = {}
  for _, p in ipairs(registry_map) do
    if type(p) == "string" then
      table.insert(normalized_registry_map, p)
    end
    table.insert(normalized_registry_map, p.src)
  end

  -- loop through all plugins and remove those that are not in the registry
  ---@type string[]
  local to_remove = {}
  for _, p in ipairs(plugins) do
    local src = p.spec.src
    if not vim.tbl_contains(normalized_registry_map, src) then
      table.insert(to_remove, p.spec.name)
    end
  end

  vim.pack.del(to_remove)
end

---Print loaded and not-loaded plugin status.
local function print_plugin_status()
  local loaded = M.get_plugins(true)
  local not_loaded = M.get_plugins(false)

  local lines = { "Plugin status:" }
  table.insert(lines, string.format("Loaded [%s]:", #loaded))
  for i, entry in ipairs(loaded) do
    table.insert(lines, string.format("%2d. %s", i, entry.name))
  end

  table.insert(lines, string.format("Not loaded [%s]:", #not_loaded))
  for i, entry in ipairs(not_loaded) do
    table.insert(lines, string.format("%2d. %s", i, entry.name))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
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
      local path = mod_root .. "." .. rel
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
      local dep = mod_map[req] or mod_map[mod_root .. "." .. req]
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
    local dep = mod_map[dep_name] or mod_map[mod_root .. "." .. dep_name]
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

  -- install from vim.pack
  if mod.registry then
    vim.pack.add(mod.registry, {
      confirm = false,
    })
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
      local dep = mod_map[dep_name] or mod_map[mod_root .. "." .. dep_name]
      if dep and not dep.loaded then
        -- recurse synchronously (dependencies are cheap)
        local ok = setup_one(dep, mod)
        if not ok then
          return false
        end
      end
    end

    -- 2. install via vim.pack (already async)
    if mod.registry then
      vim.pack.add(mod.registry, {
        confirm = false,
      })
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
  vim.keymap.set("n", "<leader>pu", update_all_packages, { desc = "Update plugins" })
  vim.keymap.set("n", "<leader>px", remove_all_packages, { desc = "Clear all plugins" })
  vim.keymap.set("n", "<leader>ps", sync_packages, { desc = "Sync deleted packages" })
  vim.keymap.set("n", "<leader>pi", print_plugin_status, { desc = "Plugin status" })
  vim.keymap.set("n", "<leader>pr", print_resolution_timeline, { desc = "Plugin resolution" })
end

-----------------------------------------------------------------------------//
-- Public API
-----------------------------------------------------------------------------//

---Initialize the plugin manager.
---@return nil
function M.init()
  local modules = discover()
  sort_modules(modules)
  setup_modules()
  setup_keymaps()
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
