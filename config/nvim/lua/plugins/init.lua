local M = {}

-----------------------------------------------------------------------------//
-- 0.  Public contract
-----------------------------------------------------------------------------//
M.init = nil
M.setup_keymaps = nil
M.get_plugins = nil
-----------------------------------------------------------------------------//

-----------------------------------------------------------------------------//
-- 1.  State
-----------------------------------------------------------------------------//
local mod_root = "plugins"
local mod_base_path = vim.fn.stdpath("config") .. "/lua/" .. mod_root

---@type table<string, PluginModule.Resolved>
local mod_map = {}
---@type PluginModule.Resolved[]
local sorted_modules = {}
---@type (string|vim.pack.Spec)[]
local registry_map = {}

-- Caches
---@type PluginModule.Resolved[]
local _discovered_modules = nil
---@type table<string, boolean>
local _argv_cmds = nil

-----------------------------------------------------------------------------//
-- 2.  Utilities
-----------------------------------------------------------------------------//
local log = {
  warn = function(msg)
    vim.notify(msg, vim.log.levels.WARN)
  end,
  error = function(msg)
    vim.notify(msg, vim.log.levels.ERROR)
  end,
}

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

---@param x string|string[]
---@return string[]
local function string_or_table(x)
  if type(x) == "string" then
    return { x }
  end
  return x
end

-----------------------------------------------------------------------------//
-- 3.  Discovery
-----------------------------------------------------------------------------//
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
      if not success or type(mod) ~= "table" or type(mod.setup) ~= "function" or mod.enabled == false then
        log.warn(("Plugin %s does not export valid setup"):format(path))
        goto continue
      end

      local name = mod.name or path
      if argv_cmds()[name:lower()] then
        mod.lazy = false
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
-- 4.  Topological sort  (Kahn’s algorithm – O(n+m))
-----------------------------------------------------------------------------//
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
-- 5.  Safe setup
-----------------------------------------------------------------------------//
---@param mod PluginModule.Resolved
---@return boolean
local function setup_one(mod)
  if mod.loaded then
    return true
  end

  -- 1. Ensure every declared dependency is loaded first
  for _, dep_name in ipairs(mod.requires) do
    local dep = mod_map[dep_name] or mod_map[mod_root .. "." .. dep_name]
    if not dep then
      log.warn(("Missing dependency %s for %s"):format(dep_name, mod.name))
      return false
    end
    if not setup_one(dep) then -- recursive, but safe: list is topo-sorted
      return false -- abort on first failure
    end
  end

  -- 2. Install & run the plugin itself
  vim.pack.add(mod.registry)
  local ok, data = pcall(require, mod.path)
  if not ok then
    log.error(("Failed to require %s: %s"):format(mod.name, data))
    return false
  end
  local setup_ok, err = pcall(data.setup)
  if not setup_ok then
    log.error(("Setup failed for %s: %s"):format(mod.name, err))
    return false
  end

  mod.loaded = true
  return true
end

-----------------------------------------------------------------------------//
-- 6.  Lazy-load wiring
-----------------------------------------------------------------------------//
---@param mod PluginModule.Resolved
local function wire_lazy(mod)
  local l = mod.lazy
  if type(l) ~= "table" then
    return
  end

  if l.event then
    local events = string_or_table(l.event)
    vim.api.nvim_create_autocmd(events, {
      once = true,
      callback = function()
        setup_one(mod)
      end,
    })
  end

  if l.ft then
    local fts = string_or_table(l.ft)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = fts,
      once = true,
      callback = function()
        setup_one(mod)
      end,
    })
  end

  if l.keys then
    local keys = string_or_table(l.keys)
    for _, key in ipairs(keys) do
      vim.keymap.set({ "n", "v", "x", "o" }, key, function()
        pcall(vim.keymap.del, { "n", "v", "x", "o" }, key)
        if setup_one(mod) then
          vim.schedule(function()
            vim.api.nvim_feedkeys(vim.keycode(key), "m", false)
          end)
        end
      end, { noremap = true, silent = true, desc = "Lazy: " .. mod.name })
    end
  end

  if l.cmd then
    local cmds = string_or_table(l.cmd)
    for _, name in ipairs(cmds) do
      vim.api.nvim_create_user_command(name, function(opts)
        if setup_one(mod) then
          vim.schedule(function()
            vim.cmd((opts.bang and "%s! %s" or "%s %s"):format(name, opts.args))
          end)
        end
      end, { bang = true, nargs = "*" })
    end
  end

  if l.on_lsp_attach then
    local allowed = string_or_table(l.on_lsp_attach)
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and vim.tbl_contains(allowed, client.name) then
          setup_one(mod)
        end
      end,
    })
  end
end

-----------------------------------------------------------------------------//
-- 7.  Setup
-----------------------------------------------------------------------------//
---@return nil
function M.setup_modules()
  for _, mod in ipairs(sorted_modules) do
    if mod.lazy then
      wire_lazy(mod)
    else
      setup_one(mod)
    end
  end
end

-----------------------------------------------------------------------------//
-- 8.  Keymaps
-----------------------------------------------------------------------------//
---@return nil
function M.setup_keymaps()
  vim.keymap.set("n", "<leader>p", "", { desc = "plugins" })

  vim.keymap.set("n", "<leader>pu", function()
    vim.pack.add(registry_map)
    local plugins = vim.pack.get()
    local names = vim.tbl_map(function(p)
      return p.spec.name
    end, plugins)
    vim.pack.update(names)
  end, { desc = "Update plugins" })

  vim.keymap.set("n", "<leader>pI", function()
    vim.notify(vim.inspect(vim.pack.get()))
  end, { desc = "Pack info" })

  vim.keymap.set("n", "<leader>pX", function()
    local plugins = vim.pack.get()
    local names = vim.tbl_map(function(p)
      return p.spec.name
    end, plugins)
    vim.pack.del(names)
  end, { desc = "Clear all plugins" })

  vim.keymap.set("n", "<leader>pi", function()
    local loaded = M.get_plugins(true)
    local not_loaded = M.get_plugins(false)
    vim.notify(
      string.format(
        "Loaded [%d]:\n%s\n\nNot loaded [%d]:\n%s",
        #loaded,
        table.concat(loaded, "\n"),
        #not_loaded,
        table.concat(not_loaded, "\n")
      )
    )
  end, { desc = "Plugin status" })
end

-----------------------------------------------------------------------------//
-- 9.  Public API
-----------------------------------------------------------------------------//
---@return nil
function M.init()
  local modules = discover()
  sort_modules(modules)
  M.setup_modules()
  M.setup_keymaps()
end

---@return PluginModule.Resolved[]
function M.get_plugins(query)
  if query == nil then
    return sorted_modules
  end
  local out = {}
  for _, m in ipairs(sorted_modules) do
    if m.loaded == query then
      table.insert(out, m.name)
    end
  end
  return out
end

return M
