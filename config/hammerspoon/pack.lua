local M = {}

-- Examples
-- pack.setup({
--   config = {
--     -- Plugins stored outside .hammerspoon directory (not git tracked)
--     repo_dir = os.getenv("HOME") .. "/.hammerspoon-pack/plugins",
--     spoon_dir = os.getenv("HOME") .. "/.hammerspoon-pack/Spoons",
--     state_dir = os.getenv("HOME") .. "/.hammerspoon-pack/state",
--
--     -- Alternative locations you might prefer:
--     -- root = os.getenv("HOME") .. "/.cache/hammerspoon/plugins",
--     -- root = "/opt/hammerspoon/plugins", -- System-wide
--     -- root = os.getenv("HOME") .. "/Library/Application Support/Hammerspoon/plugins", -- macOS standard
--
--     auto_install = true,
--     auto_cleanup = true,
--   },
--
--   plugins = {
--     -- Official Spoons from the Spoons repository
--     -- {
--     --   name = "AClock",
--     --   spoon = true,
--     --   config = function()
--     --     spoon.AClock:init()
--     --     spoon.AClock:show()
--     --   end,
--     -- },
--
--     -- {
--     --   name = "Caffeine",
--     --   spoon = true,
--     --   config = function()
--     --     spoon.Caffeine:bindHotkeys({ toggle = { { "cmd", "shift" }, "c" } })
--     --     spoon.Caffeine:start()
--     --   end,
--     -- },
--
--     -- Custom plugins from GitHub
--     -- {
--     --   name = "Vifari", -- GitHub repo
--     --   url = "https://github.com/dzirtusss/vifari.git",
--     --   config = function()
--     --     -- Custom configuration for this plugin
--     --     spoon.Vifari:start()
--     --   end,
--     -- },
--     --
--     -- {
--     --   name = "another-user/window-manager",
--     --   url = "https://github.com/another-user/window-manager.git",
--     --   config = function()
--     --     -- Plugin configuration
--     --   end,
--     -- },
--
--     -- Local development plugin
--     -- {
--     --   name = "Vimnav",
--     --   dir = os.getenv("HOME") .. "/.hammerspoon/custom-plugins/Vimnav",
--     --   config = function()
--     --     -- Local plugin config
--     --
--     --     ---@type Hs.Vimnav.Config
--     --     ---@diagnostic disable-next-line: missing-fields
--     --     local vimnavConfig = {
--     --       excludedApps = {
--     --         "Terminal",
--     --         "Ghostty",
--     --         "Screen Sharing",
--     --         "RustDesk",
--     --       },
--     --     }
--     --
--     --     spoon.Vimnav:init(vimnavConfig)
--     --     spoon.Vimnav:start()
--     --   end,
--     -- },
--
--     -- Plugin with dependencies
--     -- {
--     --   name = "complex-plugin/main",
--     --   dependencies = {
--     --     "helper-plugin/utils",
--     --     { name = "UtilSpoon", spoon = true },
--     --   },
--     --   config = function()
--     --     -- This plugin and its dependencies will be loaded
--     --   end,
--     -- },
--   },
-- })

-- Manual commands you can run in the Hammerspoon console:
-- pack.update()                  -- Update all plugins
-- pack.update("AClock")         -- Update specific plugin
-- pack.clean()                  -- Remove unused plugins

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
  auto_cleanup = true, -- Automatically remove unused plugins
}

-- Internal state
local plugins = {}
local spoons_repo_cloned = false
local state_file_name = "state.lua"

-- Utility functions
local function log(level, msg, ...)
  local message = string.format(msg, ...)
  print(string.format("[pack.hs:%s] %s", level:upper(), message))
end

local function path_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function dir_exists(path)
  local clean = path:gsub("/+$", "")
  local ok, how, code = os.execute(string.format('[ -d "%s" ]', clean))

  -- success if exit status is 0
  return ok == true and code == 0
end

local function mkdir_p(path)
  os.execute(string.format("mkdir -p '%s'", path))
end

local function exec(cmd, timeout)
  timeout = timeout or 10
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return false, "Failed to execute command"
  end
  local result = handle:read("*all")
  local success = handle:close()
  return success, result
end

local function git_clone(url, path)
  local parent_dir = path:match("(.+)/[^/]+$")
  if parent_dir then
    mkdir_p(parent_dir)
  end
  local cmd = string.format("git clone '%s' '%s'", url, path)
  log("info", "Cloning %s to %s", url, path)
  return exec(cmd, M.config.git.timeout)
end

local function git_pull(path)
  local cmd = string.format("cd '%s' && git pull", path)
  log("info", "Updating %s", path)
  return exec(cmd, M.config.git.timeout)
end

local function serialize_table(t, indent)
  indent = indent or ""
  if type(t) ~= "table" then
    if type(t) == "string" then
      return string.format("%q", t)
    elseif type(t) == "boolean" then
      return tostring(t)
    else
      return tostring(t)
    end
  end

  local result = "{\n"
  for k, v in pairs(t) do
    local key = type(k) == "string" and string.format("[%q]", k) or string.format("[%s]", k)
    result = result .. indent .. "  " .. key .. " = " .. serialize_table(v, indent .. "  ") .. ",\n"
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

local function save_plugin_state()
  local state = {}
  for name, plugin in pairs(plugins) do
    state[name] = {
      name = plugin.name,
      dir = plugin.dir,
      dependencies = plugin.dependencies,
      spoon = plugin.spoon,
      url = plugin.url,
    }
  end

  local config_file_path = M.config.state_dir .. "/" .. state_file_name

  local file = io.open(config_file_path, "w")
  if file then
    file:write("-- Auto-generated plugin state - do not edit manually\n")
    file:write("return " .. serialize_table(state) .. "\n")
    file:close()
    log("debug", "Saved plugin state to %s (%d plugins)", config_file_path, table_length(state))
  else
    log("error", "Failed to save plugin state to %s", config_file_path)
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
      log("warn", "Failed to load plugin state: %s", state or "invalid format")
    end
  else
    log("warn", "Failed to parse plugin state file: %s", err)
  end
  return {}
end

local function copy_spoon(spoon_name, source_path, dest_path)
  mkdir_p(dest_path:match("(.+)/[^/]+$"))
  local cmd = string.format("cp -r '%s/%s.spoon' '%s'", source_path, spoon_name, dest_path)
  log("info", "Copying %s.spoon to %s", spoon_name, dest_path)
  return exec(cmd, 5)
end

local function get_spoon_path(spoon_name)
  local spoon_root = M.config.spoon_dir
  local spoon_path = spoon_root .. "/" .. spoon_name .. ".spoon"

  return spoon_path
end

local function safe_remove(path)
  -- strip any trailing slash; test -L fails if it ends with /
  local clean = path:gsub("/+$", "")
  -- first check if it's a symlink
  local is_link = os.execute(string.format('[ -L "%s" ]', clean)) == true

  local cmd
  if is_link then
    -- remove only the link
    cmd = string.format('/bin/rm "%s"', clean:gsub('"', '\\"'))
  else
    -- remove file or directory recursively
    cmd = string.format('/bin/rm -rf "%s"', clean:gsub('"', '\\"'))
  end

  local ok, how, code = os.execute(cmd)
  return ok, how, code
end

local function create_spoon_symlink(spoon_name, target_path)
  local symlink_path = get_spoon_path(spoon_name)

  -- Remove existing symlink or directory
  safe_remove(symlink_path)

  log("info", "Creating symlink: %s -> %s", symlink_path, target_path)
  return hs.fs.link(target_path, symlink_path, true)
end

local function normalize_plugin_spec(spec)
  if type(spec) == "string" then
    return { name = spec }
  end

  local plugin = {}
  plugin.name = spec[1] or spec.name
  plugin.url = spec.url
  plugin.branch = spec.branch
  plugin.dir = spec.dir
  plugin.spoon = spec.spoon -- true if it's a spoon from the official repo
  plugin.config = spec.config
  plugin.dependencies = spec.dependencies or {}

  -- Determine plugin directory and URL
  -- plugin.dir = M.config.spoon_dir .. "/" .. plugin.name .. ".spoon"
  -- if plugin.spoon then
  --   plugin.dir = M.config.spoon_root .. "/" .. plugin.name .. ".spoon"
  -- else
  --   if not plugin.dir then
  --     plugin.dir = M.config.root .. "/" .. plugin.name:gsub("/", "--")
  --   end
  -- end

  return plugin
end

local function ensure_spoons_repo()
  if spoons_repo_cloned then
    return true
  end

  local spoons_temp = M.config.repo_dir .. "/spoons-repo"

  if not dir_exists(spoons_temp) then
    local success, err = git_clone(M.config.git.spoon_repo, spoons_temp)
    if not success then
      log("error", "Failed to clone Spoons repository: %s", err)
      return false
    end
  end

  spoons_repo_cloned = true
  return true
end

local function install_plugin(plugin)
  if plugin.spoon then
    -- Install from official Spoons repository
    if not ensure_spoons_repo() then
      return false
    end

    local spoons_temp = M.config.repo_dir .. "/spoons-repo"
    local spoon_source = spoons_temp .. "/Source/" .. plugin.name

    if not dir_exists(spoon_source .. ".spoon") then
      log("error", "Spoon %s not found in repository", plugin.name)
      return false
    end

    local dir = plugin.dir

    if not dir then
      dir = get_spoon_path(plugin.name)
    end

    local success, err = copy_spoon(plugin.name, spoons_temp .. "/Source", dir)
    if not success then
      log("error", "Failed to install spoon %s: %s", plugin.name, err)
      return false
    end
  else
    -- Install from git repository
    if not plugin.url then
      if not plugin.dir then
        log("error", "No URL or directory specified for plugin %s", plugin.name)
        return false
      end

      local spoon_path = get_spoon_path(plugin.name)

      if not dir_exists(spoon_path) then
        -- symlink dir
        local symlink_success, symlink_err = create_spoon_symlink(plugin.name, plugin.dir)
        if not symlink_success then
          log("warn", "Failed to create symlink for spoon %s: %s", plugin.name, symlink_err)
        end
      end

      return true
    end

    local dir = plugin.dir

    if plugin.url then
      dir = get_spoon_path(plugin.name)
    end

    local success, err = git_clone(plugin.url, dir)
    if not success then
      log("error", "Failed to install plugin %s: %s", plugin.name, err)
      return false
    end
  end

  log("info", "Successfully installed %s", plugin.name)
  return true
end

local function update_plugin(plugin)
  if not dir_exists(plugin.dir) then
    log("warn", "Plugin %s not installed, installing...", plugin.name)
    return install_plugin(plugin)
  end

  if plugin.spoon then
    -- Update spoon by reinstalling from repo
    if not ensure_spoons_repo() then
      return false
    end

    -- First update the spoons repo
    local spoons_temp = M.config.repo_dir .. "/spoons-repo"
    local success, err = git_pull(spoons_temp)
    if not success then
      log("warn", "Failed to update Spoons repository: %s", err)
    end

    local spoon_path = get_spoon_path(plugin.name)

    -- Remove old version and reinstall
    safe_remove(spoon_path)

    local success = install_plugin(plugin)

    return success
  else
    -- Update git repository
    local success, err = git_pull(plugin.dir)
    if not success then
      log("error", "Failed to update plugin %s: %s", plugin.name, err)
      return false
    end
  end

  log("info", "Successfully updated %s", plugin.name)
  return true
end

local function load_plugin(plugin)
  -- Load dependencies first
  for _, dep_spec in ipairs(plugin.dependencies) do
    local dep = normalize_plugin_spec(dep_spec)
    if not load_plugin(dep) then
      log("error", "Failed to load dependency %s for %s", dep.name, plugin.name)
      return false
    end
  end

  local spoon_path = get_spoon_path(plugin.name)

  -- Check if plugin is installed
  if not dir_exists(spoon_path) then
    if M.config.auto_install then
      log("info", "Plugin %s not found, installing...", plugin.name)
      if not install_plugin(plugin) then
        return false
      end
    else
      log("error", "Plugin %s not installed and auto_install is disabled", plugin.name)
      return false
    end
  end

  if type(plugin.config) == "function" then
    hs.loadSpoon(plugin.name)

    plugin.config()
  end

  return true
end

-- Plugin management
function M.setup(spec)
  -- Merge user config
  if spec.config then
    for k, v in pairs(spec.config) do
      M.config[k] = v
    end
  end

  -- Create directories
  mkdir_p(M.config.repo_dir)
  mkdir_p(M.config.spoon_dir)
  mkdir_p(M.config.state_dir)

  -- Setup path detection for custom location
  package.path = package.path .. ";" .. M.config.spoon_dir .. "/?.spoon/init.lua"

  -- Process plugin specs
  if spec.plugins then
    for _, plugin_spec in ipairs(spec.plugins) do
      local plugin = normalize_plugin_spec(plugin_spec)
      plugins[plugin.name] = plugin
    end
  end

  if M.config.auto_cleanup then
    log("debug", "Auto-cleanup enabled")
    M.clean()
  end

  -- Load all plugins
  for name, plugin in pairs(plugins) do
    load_plugin(plugin)
  end

  save_plugin_state()
end

function M.update(name)
  local previous_state = load_plugin_state()

  if name then
    local plugin = previous_state[name]
    if not plugin then
      log("error", "Plugin %s not found in configuration", name)
      return false
    end
    return update_plugin(plugin)
  else
    -- Update all plugins
    local success = true
    for _, plugin in pairs(previous_state) do
      if not update_plugin(plugin) then
        success = false
      end
    end
    return success
  end
end

function M.clean()
  log("info", "Cleaning unused plugins...")

  local previous_state = load_plugin_state()
  local current_plugins = {}

  -- Build current plugin set
  for name, plugin in pairs(plugins) do
    current_plugins[name] = true
  end

  log("debug", "Previous plugins: %d, Current plugins: %d", table_length(previous_state), table_length(current_plugins))

  local cleaned_count = 0

  -- Remove plugins that are no longer in config
  for old_name, old_plugin in pairs(previous_state) do
    if not current_plugins[old_name] then
      log("info", "Cleanup: removing unused plugin %s", old_name)

      -- Remove plugin directory
      local spoon_path = get_spoon_path(old_plugin.name)

      local ok, how, code = safe_remove(spoon_path)

      if ok then
        cleaned_count = cleaned_count + 1
        log("info", "Removed plugin directory: %s", spoon_path)
      else
        log("error", "Failed to remove %s: type=%s code=%s", spoon_path, tostring(how), tostring(code))
      end
    end
  end

  if cleaned_count > 0 then
    log("info", "Cleanup: removed %d unused plugins", cleaned_count)
  else
    log("info", "Cleanup: no unused plugins found")
  end
end

function M.list()
  log("info", "Configured plugins:")
  for name, plugin in pairs(plugins) do
    local status = dir_exists(plugin.dir) and "installed" or "not installed"
    local type_str = plugin.spoon and "spoon" or "plugin"
    log("info", "  %s (%s): %s", name, type_str, status)
  end
end

return M
