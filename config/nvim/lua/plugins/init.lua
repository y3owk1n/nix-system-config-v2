local mod_root = "plugins"
local mod_path = vim.fn.stdpath("config") .. "/lua/" .. mod_root

local modules = {}
local mod_map = {}

-- Step 1: Discover and require plugin modules
for _, file in
  ipairs(vim.fs.find(function(name)
    return name:sub(-4) == ".lua"
  end, { type = "file", limit = math.huge, path = mod_path }))
do
  local rel = file:sub(#mod_path + 2, -5):gsub("/", ".")
  if rel ~= "init" then
    local name = mod_root .. "." .. rel
    local ok, mod = pcall(require, name)

    if ok then
      if type(mod) == "function" then
        mod = { setup = mod }
      end

      if type(mod) == "table" and mod.setup and mod.enabled ~= false then
        local entry = {
          name = name,
          setup = mod.setup,
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
      vim.notify("Failed to load " .. name .. "\n\n" .. mod, vim.log.levels.ERROR)
    end
  end
end

-- Step 2: Priority-aware topological sort
local visited = {}
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

local function safe_setup(mod)
  if mod.loaded then
    return
  end
  mod.loaded = true
  local ok, err = pcall(mod.setup)
  if not ok then
    vim.notify("Setup failed for " .. mod.name .. "\n\n" .. err, vim.log.levels.ERROR)
  end
end

-- Step 4: Setup all modules in resolved order
for _, mod in ipairs(sorted) do
  local lazy = mod.lazy
  if not lazy then
    -- Eager load if no lazy field
    safe_setup(mod)
    eagerly_loaded = eagerly_loaded + 1
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

    if lazy.cmd then
      local cmd = lazy.cmd

      if type(cmd) == "string" then
        cmd = { cmd }
      end

      for _, value in ipairs(cmd) do
        vim.api.nvim_create_user_command(value, function()
          safe_setup(mod)
        end, {})
      end
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

    if lazy.keys then
      vim.keymap.set("n", lazy.keys, function()
        safe_setup(mod)
      end, { once = true })
    end

    if lazy.on_lsp_attach then
      vim.api.nvim_create_autocmd("LspAttach", {
        once = true,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          local allowed_clients = lazy.on_lsp_attach

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

vim.g.loaded_plugins_count = eagerly_loaded
