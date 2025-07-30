local mod_root = "plugins"
local mod_path = vim.fn.stdpath("config") .. "/lua/" .. mod_root

---@type PluginModule.Resolved[]
local modules = {}
---@type PluginModule.Resolved[]
local mod_map = {}

local function get_plus_commands()
  local commands = {}
  for _, arg in ipairs(vim.v.argv) do
    local cmd = arg:match("^%+(.+)")
    if cmd then
      table.insert(commands, cmd)
    end
  end
  return commands
end

local function string_includes_cmds(str)
  local cmds = get_plus_commands()
  for _, cmd in ipairs(cmds) do
    str = str:lower()
    cmd = cmd:lower()
    if cmd:match(str) then
      return true
    end
  end
end

-- Step 1: Discover and require plugin modules
for _, file in
  ipairs(vim.fs.find(function(name)
    return name:sub(-4) == ".lua"
  end, { type = "file", limit = math.huge, path = mod_path }))
do
  local rel = file:sub(#mod_path + 2, -5):gsub("/", ".")
  if rel ~= "init" then
    local path = mod_root .. "." .. rel
    local name = path
    local full_path = vim.fn.fnamemodify(file, ":p") -- get absolute path
    local ok, chunk = pcall(loadfile, full_path)

    if ok and chunk then
      local env = {}
      setfenv(chunk, env)

      local success, mod = pcall(chunk)
      if success and type(mod) == "table" and mod.setup and mod.enabled ~= false then
        if mod.name then
          name = mod.name
        end

        -- if neovim starts with +cmd, disable lazy loading
        if string_includes_cmds(name) then
          mod.lazy = false
        end

        ---@type PluginModule.Resolved
        local entry = {
          name = name,
          path = path,
          setup = mod.setup, -- will be replaced later
          priority = mod.priority or 1000,
          requires = mod.requires or {},
          lazy = mod.lazy or false,
          loaded = false,
        }
        table.insert(modules, entry)

        mod_map[name] = entry
      else
        vim.notify("Plugin " .. name .. " does not export a valid setup()", vim.log.levels.WARN)
      end
    else
      vim.notify("Failed to load metadata for " .. name .. "\n\n" .. tostring(chunk), vim.log.levels.ERROR)
    end
  end
end

-- Step 2: Priority-aware topological sort
---@type table<string, "temp"|true>
local visited = {}
---@type PluginModule.Resolved[]
local sorted = {}

local function visit(mod)
  if visited[mod.name] == "temp" then
    vim.notify("Cyclic dependency detected: " .. mod.name, vim.log.levels.ERROR)
    return
  end
  if visited[mod.name] then
    return
  end

  visited[mod.name] = "temp"

  -- Sort dependencies by priority before visiting
  local deps = {}
  for _, req in ipairs(mod.requires) do
    local dep = mod_map[mod_root .. "." .. req] or mod_map[req]
    if dep then
      table.insert(deps, dep)
    else
      vim.notify("Missing dependency: " .. req .. " (required by " .. mod.name .. ")", vim.log.levels.WARN)
    end
  end
  table.sort(deps, function(a, b)
    return a.priority < b.priority
  end)

  for _, dep in ipairs(deps) do
    visit(dep)
  end

  visited[mod.name] = true
  table.insert(sorted, mod)
end

-- Step 3: Visit all modules
table.sort(modules, function(a, b)
  return a.priority < b.priority
end)

for _, mod in ipairs(modules) do
  visit(mod)
end

local eagerly_loaded = 0

---@param mod PluginModule.Resolved
---@return boolean loaded
local function safe_setup(mod)
  if mod.loaded then
    return true
  end

  local depends_on = mod.requires

  if depends_on and #depends_on > 0 then
    for _, dep in ipairs(depends_on) do
      local dep_mod = mod_map[dep]
      if not dep_mod then
        vim.notify("Missing dependency: " .. dep .. " (required by " .. mod.name .. ")", vim.log.levels.WARN)
        return false
      end
      safe_setup(dep_mod)
    end
  end

  local require_ok, require_data = pcall(require, mod.path)
  if not require_ok then
    vim.notify("Failed to load plugin " .. mod.name .. "\n\n" .. tostring(require_data), vim.log.levels.ERROR)
    return false
  end
  local ok, err = pcall(require_data.setup)
  if not ok then
    vim.notify("Setup failed for " .. mod.name .. "\n\n" .. err, vim.log.levels.ERROR)
    return false
  end
  mod.loaded = true
  eagerly_loaded = eagerly_loaded + 1
  return true
end

-- Step 4: Setup all modules in resolved order
for _, mod in ipairs(sorted) do
  local lazy = mod.lazy
  if not lazy then
    -- Eager load if no lazy field
    safe_setup(mod)
  else
    -- Lazy load
    if lazy.event then
      vim.api.nvim_create_autocmd(lazy.event, {
        once = true,
        callback = function()
          safe_setup(mod)
        end,
      })
    end

    if lazy.ft then
      vim.api.nvim_create_autocmd("FileType", {
        pattern = lazy.ft,
        once = true,
        callback = function()
          safe_setup(mod)
        end,
      })
    end

    if lazy.on_lsp_attach then
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          local allowed_clients = lazy.on_lsp_attach or {}

          if type(allowed_clients) == "string" then
            allowed_clients = { allowed_clients }
          end

          if not client or not vim.tbl_contains(allowed_clients, client.name) then
            return
          end

          safe_setup(mod)
        end,
      })
    end
  end
end

--- setup some global variables for other plugins to use
vim.g.loaded_plugins_count = eagerly_loaded
vim.g.total_plugins_count = #sorted

--- setup some keymaps for plugin management
vim.keymap.set("n", "<leader>p", "", { desc = "plugins" })
vim.keymap.set("n", "<leader>pu", function()
  vim.pack.update()
end, { desc = "Update plugins" })

vim.keymap.set("n", "<leader>pi", function()
  local copy = vim.deepcopy(sorted)

  -- Get a list of loaded plugins
  local loaded = {}
  for _, mod in ipairs(copy) do
    if mod.loaded then
      table.insert(loaded, mod.name)
    end
  end

  --- Get a list of not yet loaded plugins
  local not_loaded = {}
  for _, mod in ipairs(copy) do
    if not mod.loaded then
      table.insert(not_loaded, mod.name)
    end
  end

  vim.notify("Loaded:\n" .. table.concat(loaded, "\n") .. "\n\nNot loaded: " .. table.concat(not_loaded, "\n"))
end, { desc = "Plugin status" })
