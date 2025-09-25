local M = {}

-- Configuration
M.config = {
  repo_dir = os.getenv("HOME") .. "/.hammerspoon-pack/plugins",
  spoon_dir = os.getenv("HOME") .. "/.hammerspoon-pack/Spoons",
  state_dir = os.getenv("HOME") .. "/.hammerspoon-pack/state",
  git = {
    spoon_repo = "https://github.com/Hammerspoon/Spoons.git",
    timeout = 60,
  },
  auto_install = true,
  auto_cleanup = true,
  log_level = "info",
}

-- Internal state
local plugins = {}
local spoons_repo_cloned = false
local state_file_name = "state.lua"

-- Log levels
local LOG_LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }
local function should_log(level)
  return LOG_LEVELS[level] >= LOG_LEVELS[M.config.log_level]
end

-- Utility functions
local function log(level, msg, ...)
  if not should_log(level) then
    return
  end
  local message = string.format(msg, ...)
  local timestamp = os.date("%H:%M:%S")
  print(string.format("[%s pack.hs:%s] %s", timestamp, level:upper(), message))
end

local function normalize_path(path)
  path = path:gsub("^~", os.getenv("HOME") or "~")
  path = path:gsub("/+$", "")
  return path
end

local function path_exists(path)
  path = normalize_path(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function dir_exists(path)
  path = normalize_path(path)
  local ok, how, code = os.execute(string.format('[ -d "%s" ]', path))
  return ok == true and code == 0
end

local function mkdir_p(path)
  path = normalize_path(path)
  local success, err = os.execute(string.format("mkdir -p '%s'", path))
  if not success then
    log("error", "Failed to create directory %s: %s", path, err or "unknown error")
  end
  return success
end

local function exec(cmd, timeout, cwd)
  timeout = timeout or 10

  local full_cmd = cmd
  if cwd then
    full_cmd = string.format("cd '%s' && %s", normalize_path(cwd), cmd)
  end

  log("debug", "Executing: %s", full_cmd)

  local handle = io.popen(full_cmd .. " 2>&1")
  if not handle then
    return false, "Failed to execute command", 1
  end

  local result = handle:read("*all") or ""
  local success, exit_type, exit_code = handle:close()

  result = result:gsub("^%s*(.-)%s*$", "%1")

  if not success then
    log("debug", "Command failed with exit code %s: %s", exit_code or "unknown", result)
  else
    log("debug", "Command succeeded: %s", result:sub(1, 100) .. (result:len() > 100 and "..." or ""))
  end

  return success, result, exit_code
end

-- Git operations
local function git_clone(url, path, branch)
  local parent_dir = path:match("(.+)/[^/]+$")
  if parent_dir and not dir_exists(parent_dir) then
    mkdir_p(parent_dir)
  end

  local cmd = string.format(
    "git clone --depth 1 %s '%s' '%s'",
    branch and string.format("--branch '%s'", branch) or "",
    url,
    path
  )

  log("info", "Cloning %s to %s%s", url, path, branch and " (branch: " .. branch .. ")" or "")
  return exec(cmd, M.config.git.timeout)
end

local function git_pull(path)
  if not dir_exists(path .. "/.git") then
    log("warn", "Directory %s is not a git repository", path)
    return false, "Not a git repository"
  end

  log("info", "Updating %s", path)
  return exec("git pull --ff-only", M.config.git.timeout, path)
end

-- Table serialization for state saving
local function serialize_table(t, indent, max_depth)
  indent = indent or ""
  max_depth = max_depth or 10

  if max_depth <= 0 then
    return "{ --[[max depth reached]] }"
  end

  if type(t) ~= "table" then
    if type(t) == "string" then
      return string.format("%q", t)
    elseif type(t) == "boolean" or type(t) == "number" then
      return tostring(t)
    elseif type(t) == "function" then
      return "function() --[[function]] end"
    else
      return string.format("%q", tostring(t))
    end
  end

  local result = "{\n"
  local sorted_keys = {}

  for k in pairs(t) do
    table.insert(sorted_keys, k)
  end
  table.sort(sorted_keys, function(a, b)
    return tostring(a) < tostring(b)
  end)

  for _, k in ipairs(sorted_keys) do
    local v = t[k]
    local key = type(k) == "string" and string.match(k, "^[%a_][%w_]*$") and k
      or string.format("[%s]", serialize_table(k, "", 1))
    result = result .. indent .. "  " .. key .. " = " .. serialize_table(v, indent .. "  ", max_depth - 1) .. ",\n"
  end
  result = result .. indent .. "}"
  return result
end

local function table_length(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- State management
local function save_plugin_state()
  local state = {}
  for name, plugin in pairs(plugins) do
    state[name] = {
      name = plugin.name,
      dir = plugin.dir,
      dependencies = plugin.dependencies,
      spoon = plugin.spoon,
      url = plugin.url,
      branch = plugin.branch,
      installed_at = os.time(),
    }
  end

  mkdir_p(M.config.state_dir)
  local config_file_path = M.config.state_dir .. "/" .. state_file_name

  local file, err = io.open(config_file_path, "w")
  if file then
    file:write("-- Auto-generated plugin state - do not edit manually\n")
    file:write("-- Generated at: " .. os.date() .. "\n")
    file:write("return " .. serialize_table(state) .. "\n")
    file:close()
    log("debug", "Saved plugin state to %s (%d plugins)", config_file_path, table_length(state))
    return true
  else
    log("error", "Failed to save plugin state to %s: %s", config_file_path, err or "unknown error")
    return false
  end
end

local function load_plugin_state()
  local config_file_path = M.config.state_dir .. "/" .. state_file_name

  if not path_exists(config_file_path) then
    log("debug", "No previous plugin state file found at %s", config_file_path)
    return {}
  end

  local chunk, err = loadfile(config_file_path)
  if chunk then
    local success, state = pcall(chunk)
    if success and type(state) == "table" then
      log("debug", "Loaded plugin state from %s (%d plugins)", config_file_path, table_length(state))
      return state
    else
      log("warn", "Failed to load plugin state: %s", tostring(state))
    end
  else
    log("warn", "Failed to parse plugin state file: %s", err or "unknown error")
  end

  local backup_path = config_file_path .. ".backup." .. os.time()
  os.execute(string.format("cp '%s' '%s'", config_file_path, backup_path))
  log("info", "Backed up corrupted state file to %s", backup_path)

  return {}
end

-- Directory scanning for plugin files
local function scan_plugin_directory(dir_path)
  dir_path = normalize_path(dir_path)

  if not dir_exists(dir_path) then
    log("debug", "Plugin directory not found: %s", dir_path)
    return {}
  end

  log("info", "Scanning for plugin configs in: %s", dir_path)

  local files = {}
  local handle = io.popen(string.format('find "%s" -name "*.lua" -type f', dir_path))

  if handle then
    for file in handle:lines() do
      table.insert(files, file)
    end
    handle:close()
  end

  local plugins = {}
  local loaded_count = 0

  for _, file_path in ipairs(files) do
    local relative_path = file_path:match(".+/(.+)%.lua$") or file_path
    log("debug", "Loading plugin config from %s", relative_path)

    local chunk, err = loadfile(file_path)
    if chunk then
      local success, plugin_spec = pcall(chunk)
      if success then
        -- Handle function returns
        if type(plugin_spec) == "function" then
          success, plugin_spec = pcall(plugin_spec)
        end

        if success and type(plugin_spec) == "table" then
          -- Auto-detect plugin name from filename if not specified
          if not plugin_spec.name and not plugin_spec[1] then
            local filename = file_path:match(".+/(.+)%.lua$") or file_path:match("([^/]+)%.lua$")
            plugin_spec.name = filename
          end

          table.insert(plugins, plugin_spec)
          loaded_count = loaded_count + 1
          log("debug", "Loaded plugin: %s", plugin_spec.name or plugin_spec[1] or "unnamed")
        else
          log("error", "Plugin file %s must return a table: %s", relative_path, tostring(plugin_spec))
        end
      else
        log("error", "Failed to execute plugin file %s: %s", relative_path, tostring(plugin_spec))
      end
    else
      log("error", "Failed to parse plugin file %s: %s", relative_path, err or "unknown")
    end
  end

  log("info", "Loaded %d plugin configurations from %d files", loaded_count, #files)
  return plugins
end

-- Spoon operations
local function copy_spoon(spoon_name, source_path, dest_path)
  local parent_dir = dest_path:match("(.+)/[^/]+$")
  if parent_dir then
    mkdir_p(parent_dir)
  end

  local source_spoon = source_path .. "/" .. spoon_name .. ".spoon"
  if not dir_exists(source_spoon) then
    return false, "Source spoon directory not found: " .. source_spoon
  end

  log("info", "Copying %s.spoon to %s", spoon_name, dest_path)
  return exec(string.format("cp -r '%s' '%s'", source_spoon, dest_path), 10)
end

local function get_spoon_path(spoon_name)
  return M.config.spoon_dir .. "/" .. spoon_name .. ".spoon"
end

local function safe_remove(path)
  path = normalize_path(path)

  if not path_exists(path) and not dir_exists(path) then
    return true
  end

  local is_link = os.execute(string.format('[ -L "%s" ]', path)) == true
  local cmd = is_link and string.format('rm "%s"', path:gsub('"', '\\"'))
    or string.format('rm -rf "%s"', path:gsub('"', '\\"'))

  log("debug", "Removing %s (symlink: %s)", path, is_link)
  local ok, how, code = os.execute(cmd)

  if not ok then
    log("warn", "Failed to remove %s: exit code %s", path, code or "unknown")
  end

  return ok, how, code
end

local function create_spoon_symlink(spoon_name, target_path)
  local symlink_path = get_spoon_path(spoon_name)
  target_path = normalize_path(target_path)

  safe_remove(symlink_path)
  mkdir_p(symlink_path:match("(.+)/[^/]+$"))

  log("info", "Creating symlink: %s -> %s", symlink_path, target_path)
  return hs.fs.link(target_path, symlink_path, true)
end

-- Plugin spec normalization
local function normalize_plugin_spec(spec)
  if type(spec) == "string" then
    return { name = spec }
  end

  local plugin = {
    name = spec[1] or spec.name,
    url = spec.url,
    branch = spec.branch,
    dir = spec.dir,
    spoon = spec.spoon or false,
    config = spec.config,
    dependencies = spec.dependencies or {},
    enabled = spec.enabled ~= false,
  }

  if not plugin.name then
    error("Plugin spec missing required 'name' field")
  end

  -- Auto-detect spoon if no URL or dir specified
  if not plugin.spoon and not plugin.url and not plugin.dir then
    plugin.spoon = true
  end

  return plugin
end

-- Repository management
local function ensure_spoons_repo()
  if spoons_repo_cloned then
    return true
  end

  local spoons_temp = M.config.repo_dir .. "/spoons-repo"

  if not dir_exists(spoons_temp) then
    local success, err = git_clone(M.config.git.spoon_repo, spoons_temp)
    if not success then
      log("error", "Failed to clone Spoons repository: %s", err or "unknown error")
      return false
    end
  end

  spoons_repo_cloned = true
  return true
end

-- Plugin installation
local function install_plugin(plugin)
  if not plugin.enabled then
    log("debug", "Skipping disabled plugin %s", plugin.name)
    return true
  end

  if plugin.spoon then
    if not ensure_spoons_repo() then
      return false
    end

    local spoons_temp = M.config.repo_dir .. "/spoons-repo"
    local spoon_source = spoons_temp .. "/Source/" .. plugin.name
    local spoon_path = get_spoon_path(plugin.name)

    if not dir_exists(spoon_source .. ".spoon") then
      log("error", "Spoon %s not found in repository", plugin.name)
      return false
    end

    local success, err = copy_spoon(plugin.name, spoons_temp .. "/Source", spoon_path)
    if not success then
      log("error", "Failed to install spoon %s: %s", plugin.name, err or "unknown error")
      return false
    end
  else
    if plugin.dir then
      -- Local plugin - create symlink
      if not dir_exists(plugin.dir) then
        log("error", "Local plugin directory not found: %s", plugin.dir)
        return false
      end

      local symlink_success, symlink_err = create_spoon_symlink(plugin.name, plugin.dir)
      if not symlink_success then
        log("error", "Failed to create symlink for plugin %s: %s", plugin.name, symlink_err or "unknown error")
        return false
      end
    elseif plugin.url then
      -- Git plugin
      local target_path = get_spoon_path(plugin.name)
      local success, err = git_clone(plugin.url, target_path, plugin.branch)
      if not success then
        log("error", "Failed to install plugin %s: %s", plugin.name, err or "unknown error")
        return false
      end
    else
      log("error", "Plugin %s has no URL or directory specified", plugin.name)
      return false
    end
  end

  log("info", "Successfully installed %s", plugin.name)
  return true
end

local function update_plugin(plugin)
  local spoon_path = get_spoon_path(plugin.name)

  if not dir_exists(spoon_path) then
    log("warn", "Plugin %s not installed, installing...", plugin.name)
    return install_plugin(plugin)
  end

  if plugin.spoon then
    if not ensure_spoons_repo() then
      return false
    end

    local spoons_temp = M.config.repo_dir .. "/spoons-repo"
    local success, err = git_pull(spoons_temp)
    if not success then
      log("warn", "Failed to update Spoons repository: %s", err or "unknown error")
    end

    safe_remove(spoon_path)
    return install_plugin(plugin)
  elseif plugin.url then
    local success, err = git_pull(spoon_path)
    if not success then
      log("error", "Failed to update plugin %s: %s", plugin.name, err or "unknown error")
      return false
    end
  elseif plugin.dir then
    local symlink_success, symlink_err = create_spoon_symlink(plugin.name, plugin.dir)
    if not symlink_success then
      log("warn", "Failed to update symlink for plugin %s: %s", plugin.name, symlink_err or "unknown error")
      return false
    end
  end

  log("info", "Successfully updated %s", plugin.name)
  return true
end

-- Plugin loading with dependency resolution
local function load_plugin(plugin, loading_stack)
  loading_stack = loading_stack or {}

  -- Detect circular dependencies
  if loading_stack[plugin.name] then
    local cycle = {}
    local found = false
    for name in pairs(loading_stack) do
      if found or name == plugin.name then
        found = true
        table.insert(cycle, name)
      end
    end
    table.insert(cycle, plugin.name)
    log("error", "Circular dependency detected: %s", table.concat(cycle, " -> "))
    return false
  end

  if not plugin.enabled then
    log("debug", "Skipping disabled plugin %s", plugin.name)
    return true
  end

  loading_stack[plugin.name] = true

  -- Load dependencies first
  for _, dep_spec in ipairs(plugin.dependencies) do
    local dep = normalize_plugin_spec(dep_spec)
    if not load_plugin(dep, loading_stack) then
      log("error", "Failed to load dependency %s for %s", dep.name, plugin.name)
      loading_stack[plugin.name] = nil
      return false
    end
  end

  local spoon_path = get_spoon_path(plugin.name)

  if not dir_exists(spoon_path) then
    if M.config.auto_install then
      log("info", "Plugin %s not found, installing...", plugin.name)
      if not install_plugin(plugin) then
        loading_stack[plugin.name] = nil
        return false
      end
    else
      log("error", "Plugin %s not installed and auto_install is disabled", plugin.name)
      loading_stack[plugin.name] = nil
      return false
    end
  end

  -- Load the spoon
  local load_success, load_error = pcall(hs.loadSpoon, plugin.name)
  if not load_success then
    log("error", "Failed to load spoon %s: %s", plugin.name, load_error or "unknown error")
    loading_stack[plugin.name] = nil
    return false
  end

  -- Run configuration
  if type(plugin.config) == "function" then
    local config_success, config_error = pcall(plugin.config)
    if not config_success then
      log("error", "Failed to configure plugin %s: %s", plugin.name, config_error or "unknown error")
      loading_stack[plugin.name] = nil
      return false
    end
  end

  loading_stack[plugin.name] = nil
  log("info", "Successfully loaded %s", plugin.name)
  return true
end

-- Public API
function M:init(spec)
  print("Initializing pack")
  spec = spec or {}

  -- Merge user config
  if spec.config then
    for k, v in pairs(spec.config) do
      if type(v) == "table" and type(M.config[k]) == "table" then
        for sub_k, sub_v in pairs(v) do
          M.config[k][sub_k] = sub_v
        end
      else
        M.config[k] = v
      end
    end
  end

  -- Create directories
  mkdir_p(M.config.repo_dir)
  mkdir_p(M.config.spoon_dir)
  mkdir_p(M.config.state_dir)

  -- Setup Hammerspoon load path
  package.path = package.path .. ";" .. M.config.spoon_dir .. "/?.spoon/init.lua"

  -- Handle plugin sources
  plugins = {}

  -- If directory is specified, scan it for plugin files
  if spec.dir then
    local dir_plugins = scan_plugin_directory(spec.dir)
    for _, plugin_spec in ipairs(dir_plugins) do
      local success, plugin = pcall(normalize_plugin_spec, plugin_spec)
      if success then
        plugins[plugin.name] = plugin
      else
        log("error", "Failed to normalize plugin spec: %s", plugin or "unknown error")
      end
    end
  end

  -- Add inline plugins
  if spec.plugins then
    for _, plugin_spec in ipairs(spec.plugins) do
      local success, plugin = pcall(normalize_plugin_spec, plugin_spec)
      if success then
        plugins[plugin.name] = plugin
      else
        log("error", "Failed to normalize plugin spec: %s", plugin or "unknown error")
      end
    end
  end

  log("info", "Configured %d plugins", table_length(plugins))

  -- Cleanup if enabled
  if M.config.auto_cleanup then
    M.clean()
  end

  -- Load all plugins
  local loaded_count = 0
  local failed_count = 0

  for name, plugin in pairs(plugins) do
    if load_plugin(plugin) then
      loaded_count = loaded_count + 1
    else
      failed_count = failed_count + 1
    end
  end

  log("info", "Plugin loading complete: %d loaded, %d failed", loaded_count, failed_count)
  save_plugin_state()
end

function M.update(name)
  local previous_state = load_plugin_state()

  if name then
    local plugin = plugins[name] or previous_state[name]
    if not plugin then
      log("error", "Plugin %s not found", name)
      return false
    end
    plugin = normalize_plugin_spec(plugin)
    return update_plugin(plugin)
  else
    local success = true
    local updated_count = 0

    for plugin_name, plugin in pairs(previous_state) do
      plugin = normalize_plugin_spec(plugin)
      if update_plugin(plugin) then
        updated_count = updated_count + 1
      else
        success = false
      end
    end

    log("info", "Update complete: %d plugins updated", updated_count)
    return success
  end
end

function M.clean()
  log("info", "Cleaning unused plugins...")

  local previous_state = load_plugin_state()
  local current_plugins = {}

  for name, plugin in pairs(plugins) do
    current_plugins[name] = true
  end

  local cleaned_count = 0

  for old_name, old_plugin in pairs(previous_state) do
    if not current_plugins[old_name] then
      log("info", "Removing unused plugin %s", old_name)

      local spoon_path = get_spoon_path(old_plugin.name)
      local ok, _, _ = safe_remove(spoon_path)

      if ok then
        cleaned_count = cleaned_count + 1
        log("info", "Removed plugin: %s", spoon_path)
      else
        log("error", "Failed to remove %s", spoon_path)
      end
    end
  end

  if cleaned_count > 0 then
    log("info", "Cleanup complete: removed %d plugins", cleaned_count)
  else
    log("info", "No unused plugins found")
  end

  return cleaned_count
end

function M.list()
  log("info", "Configured plugins (%d total):", table_length(plugins))
  for name, plugin in pairs(plugins) do
    local spoon_path = get_spoon_path(plugin.name)
    local status = dir_exists(spoon_path) and "✓ installed" or "✗ not installed"
    local type_str = plugin.spoon and "spoon" or "plugin"
    local enabled_str = plugin.enabled and "" or " (disabled)"
    log("info", "  %s (%s): %s%s", name, type_str, status, enabled_str)
  end
end

function M.status()
  local installed = 0
  local total = table_length(plugins)

  for name, plugin in pairs(plugins) do
    if dir_exists(get_spoon_path(plugin.name)) then
      installed = installed + 1
    end
  end

  log("info", "Status: %d/%d plugins installed", installed, total)
  return { installed = installed, total = total }
end

return M
