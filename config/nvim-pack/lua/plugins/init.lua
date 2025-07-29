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

-- Step 4: Setup all modules in resolved order
for _, mod in ipairs(sorted) do
  local ok, err = pcall(mod.setup)
  if not ok then
    vim.notify("Setup failed for " .. mod.name .. "\n\n" .. err, vim.log.levels.ERROR)
  end
end
