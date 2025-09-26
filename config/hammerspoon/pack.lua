---@diagnostic disable: undefined-global

local M = {}

M.__index = M

M.name = "pack"

local _utils = require("utils")

local Utils = {}
local Git = {}
local Spoons = {}
local Lockfile = {}
local Plugins = {}

-- ------------------------------------------------------------------
-- Internal state
-- ------------------------------------------------------------------

local log
local configuredPlugins = {}
local spoonsRepoCloned = false
local lockfileName = "pack-lock.lua"
local lockfilePath = hs.configdir .. "/" .. lockfileName

-- ------------------------------------------------------------------
-- Configuration
-- ------------------------------------------------------------------

---@type Hs.Pack.Config
local defaultConfig = {
  dir = hs.configdir .. "/pack",
  repoDir = os.getenv("HOME") .. "/.local/state/hammerspoon/pack/plugins",
  spoonDir = os.getenv("HOME") .. "/.local/share/hammerspoon/site/Spoons",
  git = {
    spoonRepo = "https://github.com/Hammerspoon/Spoons.git",
    timeout = 60,
  },
  autoInstall = true,
  autoCleanup = true,
  logLevel = "info",
}

-- ------------------------------------------------------------------
-- Types
-- ------------------------------------------------------------------

---@class Hs.Pack.Config
---@field dir? string The directory to scan for plugin files
---@field repoDir? string The directory to use for the Spoon repository
---@field spoonDir? string The directory to use for the Spoon files
---@field git? Hs.Pack.Config.Git The Git configuration
---@field autoInstall? boolean Whether to automatically install plugins
---@field autoCleanup? boolean Whether to automatically clean up unused plugins
---@field logLevel? string The log level to use
---@field plugins? Hs.Pack.PluginSpec[] The plugins to use

---@class Hs.Pack.Config.Git
---@field spoonRepo? string The Spoon repository URL to install official Spoons from
---@field timeout? number The timeout to use for Git operations

---@class Hs.Pack.Version
---@field major integer
---@field minor integer
---@field patch integer
---@field prerelease? string
---@field original? string

---@class Hs.Pack.PluginSpec
---@field name string The name of the plugin
---@field url? string The URL to use for the plugin
---@field branch? string The branch to use for the plugin
---@field tag? string The tag to use for the plugin
---@field commit? string The commit to use for the plugin
---@field version? string The version to use for the plugin
---@field dir? string The directory to use for the plugin
---@field spoon? boolean Whether it's a Spoon from official repo
---@field config? function The configuration function to use for the plugin
---@field dependencies? Hs.Pack.PluginSpec[] The dependencies to use for the plugin
---@field enabled? boolean Whether to enable the plugin
---@field resolvedCommit? string [Internal only] The resolved commit to use for the plugin

---@class Hs.Pack.PluginInfo
---@field name string The name of the plugin
---@field path string The path to the plugin
---@field isSymlink boolean Whether the plugin is a symlink

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

---imports from utils
---can be implemented in this file if publishing as a module
Utils.tblDeepExtend = _utils.tblDeepExtend

---Normalizes a path by expanding `~` and removing trailing slashes
---@param path string
---@return string
function Utils.normalizePath(path)
  path = path:gsub("^~", os.getenv("HOME") or "~")
  path = path:gsub("/+$", "")
  return path
end

---Checks if a path exists
---@param path string
---@return boolean
function Utils.pathExists(path)
  path = Utils.normalizePath(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

---Checks if a directory exists including symlinks directory
---@param path string
---@return boolean
function Utils.dirExists(path)
  path = Utils.normalizePath(path)
  local ok, _, code = os.execute(string.format('[ -d "%s" ]', path))
  return ok == true and code == 0
end

---Creates a directory recursively
---@param path string
---@return boolean|nil
function Utils.mkdirP(path)
  path = Utils.normalizePath(path)
  local success, err = os.execute(string.format("mkdir -p '%s'", path))
  if not success then
    log.ef("Failed to create directory %s: %s", path, err or "unknown error")
  end
  return success
end

---Executes a command and returns the result
---@param cmd string
---@param timeout? number
---@param cwd? string
---@return boolean? success
---@return string result
---@return integer? exitCode
function Utils.exec(cmd, timeout, cwd)
  timeout = timeout or 10

  local fullCmd = cmd
  if cwd then
    fullCmd = string.format("cd '%s' && %s", Utils.normalizePath(cwd), cmd)
  end

  log.df("Executing: %s", fullCmd)

  local handle = io.popen(fullCmd .. " 2>&1")
  if not handle then
    return false, "Failed to execute command", 1
  end

  local result = handle:read("*all") or ""
  local success, _, exitCode = handle:close()

  result = result:gsub("^%s*(.-)%s*$", "%1")

  if not success then
    log.df("Command failed with exit code %s: %s", exitCode or "unknown", result)
  else
    log.df("Command succeeded: %s", result:sub(1, 100) .. (result:len() > 100 and "..." or ""))
  end

  return success, result, exitCode
end

---Serializes a table to a string
---@param t table
---@param indent? string
---@param maxDepth? number
---@return string
function Utils.serializeTable(t, indent, maxDepth)
  indent = indent or ""
  maxDepth = maxDepth or 10

  if maxDepth <= 0 then
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
  local sortedKeys = {}

  for k in pairs(t) do
    table.insert(sortedKeys, k)
  end
  table.sort(sortedKeys, function(a, b)
    return tostring(a) < tostring(b)
  end)

  for _, k in ipairs(sortedKeys) do
    local v = t[k]
    local key = type(k) == "string" and string.match(k, "^[%a_][%w_]*$") and k
      or string.format("[%s]", Utils.serializeTable(k, "", 1))
    result = result .. indent .. "  " .. key .. " = " .. Utils.serializeTable(v, indent .. "  ", maxDepth - 1) .. ",\n"
  end
  result = result .. indent .. "}"
  return result
end

---Returns the number of elements in a table
---@param t table
---@return integer
function Utils.tableLength(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

---Safely removes a path, including symlinks
---@param path string
---@return boolean?
function Utils.safeRemove(path)
  path = Utils.normalizePath(path)

  if not Utils.pathExists(path) and not Utils.dirExists(path) then
    return false
  end

  local isLink = os.execute(string.format('[ -L "%s" ]', path)) == true
  local cmd = isLink and string.format('rm "%s"', path:gsub('"', '\\"'))
    or string.format('rm -rf "%s"', path:gsub('"', '\\"'))

  log.df("Removing %s (symlink: %s)", path, isLink)
  local ok, _, code = os.execute(cmd)

  if not ok then
    log.wf("Failed to remove %s: exit code %s", path, code or "unknown")
  end

  return ok
end

---Parses a semantic version string
---@param versionStr string
---@return Hs.Pack.Version?
function Utils.parseVersion(versionStr)
  if not versionStr then
    return nil
  end

  -- Remove 'v' prefix if present
  local cleanVersion = versionStr:gsub("^v", "")

  -- Parse major.minor.patch with optional pre-release and build metadata
  local major, minor, patch, prerelease = cleanVersion:match("^(%d+)%.?(%d*)%.?(%d*)%-?([^%+]*)")

  if not major then
    return nil
  end

  return {
    major = tonumber(major) or 0,
    minor = tonumber(minor) or 0,
    patch = tonumber(patch) or 0,
    prerelease = prerelease and prerelease ~= "" and prerelease or nil,
    original = versionStr,
  }
end

---Compares two semantic versions
---@param v1 Hs.Pack.Version
---@param v2 Hs.Pack.Version
---@return integer
function Utils.compareVersions(v1, v2)
  -- Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
  if v1.major ~= v2.major then
    return v1.major < v2.major and -1 or 1
  end

  if v1.minor ~= v2.minor then
    return v1.minor < v2.minor and -1 or 1
  end

  if v1.patch ~= v2.patch then
    return v1.patch < v2.patch and -1 or 1
  end

  -- Handle prerelease versions (1.0.0-alpha < 1.0.0)
  if v1.prerelease and not v2.prerelease then
    return -1
  elseif not v1.prerelease and v2.prerelease then
    return 1
  elseif v1.prerelease and v2.prerelease then
    return v1.prerelease < v2.prerelease and -1 or (v1.prerelease > v2.prerelease and 1 or 0)
  end

  return 0
end

---Checks if a version satisfies a constraint
---@param version string
---@param constraint string
---@return boolean
function Utils.versionSatisfies(version, constraint)
  local v = Utils.parseVersion(version)
  if not v then
    return false
  end

  -- Handle different constraint patterns
  if constraint == "*" then
    -- Latest stable (no prerelease)
    return not v.prerelease
  elseif constraint:match("^%d+%.%d+%.x$") then
    -- Pattern like "1.2.x"
    local major, minor = constraint:match("^(%d+)%.(%d+)%.x$")
    return v.major == tonumber(major) and v.minor == tonumber(minor)
  elseif constraint:match("^%d+%.x$") then
    -- Pattern like "1.x"
    local major = constraint:match("^(%d+)%.x$")
    return v.major == tonumber(major)
  elseif constraint:match("^%^") then
    -- Caret range: ^1.2.3 (compatible, same major)
    local constraintVersion = Utils.parseVersion(constraint:sub(2))
    if not constraintVersion then
      return false
    end
    return v.major == constraintVersion.major and Utils.compareVersions(v, constraintVersion) >= 0
  elseif constraint:match("^~") then
    -- Tilde range: ~1.2.3 (reasonably close, same major.minor)
    local constraintVersion = Utils.parseVersion(constraint:sub(2))
    if not constraintVersion then
      return false
    end
    return v.major == constraintVersion.major
      and v.minor == constraintVersion.minor
      and Utils.compareVersions(v, constraintVersion) >= 0
  elseif constraint:match("^>=") then
    -- Greater than or equal
    local constraintVersion = Utils.parseVersion(constraint:sub(3))
    if not constraintVersion then
      return false
    end
    return Utils.compareVersions(v, constraintVersion) >= 0
  elseif constraint:match("^>") then
    -- Greater than
    local constraintVersion = Utils.parseVersion(constraint:sub(2))
    if not constraintVersion then
      return false
    end
    return Utils.compareVersions(v, constraintVersion) > 0
  elseif constraint:match("^<=") then
    -- Less than or equal
    local constraintVersion = Utils.parseVersion(constraint:sub(3))
    if not constraintVersion then
      return false
    end
    return Utils.compareVersions(v, constraintVersion) <= 0
  elseif constraint:match("^<") then
    -- Less than
    local constraintVersion = Utils.parseVersion(constraint:sub(2))
    if not constraintVersion then
      return false
    end
    return Utils.compareVersions(v, constraintVersion) < 0
  else
    -- Exact match
    local constraintVersion = Utils.parseVersion(constraint)
    if not constraintVersion then
      return false
    end
    return Utils.compareVersions(v, constraintVersion) == 0
  end
end

---Resolves a version reference for a plugin
---@param plugin Hs.Pack.PluginSpec
---@param repoPath? string
---@return string?
function Utils.resolveVersionRef(plugin, repoPath)
  -- Priority: commit > resolved tag from version constraint > tag > version > branch
  if plugin.commit then
    return plugin.commit
  elseif plugin.version and plugin.version:match("[%*%^~<>=x]") then
    -- This is a version constraint, resolve it
    local resolvedTag

    if repoPath and Utils.dirExists(repoPath) then
      -- Repository exists locally, get tags from it
      resolvedTag = Git.getMatchingTag(repoPath, plugin.version)
    elseif plugin.url then
      -- No local repo, get tags remotely
      resolvedTag = Git.resolveRemoteTag(plugin.url, plugin.version)
    end

    if resolvedTag then
      return resolvedTag
    else
      log.wf("Could not resolve version constraint %s for %s", plugin.version, plugin.name)
      return nil
    end
  elseif plugin.tag then
    return plugin.tag
  elseif plugin.version then
    -- Simple version, convert to tag if it looks like a version
    if plugin.version:match("^v?%d+") then
      return plugin.version:match("^v") and plugin.version or ("v" .. plugin.version)
    end
    return plugin.version
  elseif plugin.branch then
    return plugin.branch
  end
  return nil
end

-- ------------------------------------------------------------------
-- Git
-- ------------------------------------------------------------------

---Gets the commit of a Git repository
---@param path string
---@return string?
function Git.getCommit(path)
  local success, result = Utils.exec("git rev-parse HEAD", 10, path)
  if success then
    return result
  end
  return nil
end

---Checks out a Git reference
---@param path string
---@param ref string
---@return boolean?
---@return string?
function Git.checkout(path, ref)
  if not ref then
    return true, "HEAD"
  end

  log.i(string.format("Checking out %s in %s", ref, path))
  local success, result = Utils.exec(string.format("git checkout '%s'", ref), M.config.git.timeout, path)
  if success then
    return true, Git.getCommit(path) or ref
  end
  return false, result
end

function Git.clone(url, path, ref)
  local parentDir = path:match("(.+)/[^/]+$")
  if parentDir and not Utils.dirExists(parentDir) then
    Utils.mkdirP(parentDir)
  end

  -- Clone with full history if we need to checkout a specific ref
  local depthFlag = ref and "" or "--depth 1"
  local cmd = string.format("git clone %s '%s' '%s'", depthFlag, url, path)

  log.i(string.format("Cloning %s to %s", url, path))
  local success, result = Utils.exec(cmd, M.config.git.timeout)

  if not success then
    return false, result, nil
  end

  if ref then
    local checkoutSuccess, commitOrError = Git.checkout(path, ref)
    if checkoutSuccess then
      return true, result, commitOrError
    else
      return false, commitOrError, nil
    end
  end

  return true, result, Git.getCommit(path)
end

---Pulls a Git repository
---@param path string
---@param ref? string
---@return boolean?
---@return string?
---@return string?
function Git.pull(path, ref)
  if not Utils.dirExists(path .. "/.git") then
    log.wf("Directory %s is not a git repository", path)
    return false, "Not a git repository", nil
  end

  log.i(string.format("Updating %s", path))

  -- Fetch all updates
  local success, result = Utils.exec("git fetch --all", M.config.git.timeout, path)
  if not success then
    return false, result, nil
  end

  if ref then
    local checkoutSuccess, commitOrError = Git.checkout(path, ref)
    if checkoutSuccess then
      return true, result, commitOrError
    else
      return false, commitOrError, nil
    end
  else
    local pullSuccess, pullResult = Utils.exec("git pull --ff-only", M.config.git.timeout, path)
    if pullSuccess then
      return true, pullResult, Git.getCommit(path)
    else
      return false, pullResult, nil
    end
  end
end

function Git.getMatchingTag(pluginPath, versionConstraint)
  -- Get all tags from the repository
  local success, result = Utils.exec("git tag --list --sort=-version:refname", 10, pluginPath)
  if not success then
    log.wf("Failed to get tags from %s", pluginPath)
    return nil
  end

  local tags = {}
  for tag in result:gmatch("[^\r\n]+") do
    if tag and tag ~= "" then
      table.insert(tags, tag)
    end
  end

  -- Find the best matching tag
  for _, tag in ipairs(tags) do
    if Utils.versionSatisfies(tag, versionConstraint) then
      log.df("Found matching tag %s for constraint %s", tag, versionConstraint)
      return tag
    end
  end

  log.wf("No tag found matching constraint %s", versionConstraint)
  return nil
end

---Resolves a remote tag for a Git repository
---@param url string
---@param versionConstraint string
---@return string?
function Git.resolveRemoteTag(url, versionConstraint)
  -- Get remote tags without cloning the entire repo
  local success, result = Utils.exec(string.format("git ls-remote --tags '%s'", url), M.config.git.timeout)
  if not success then
    log.wf("Failed to get remote tags from %s", url)
    return nil
  end

  local tags = {}
  for line in result:gmatch("[^\r\n]+") do
    local tag = line:match("refs/tags/([^%^]+)")
    if tag then
      table.insert(tags, tag)
    end
  end

  -- Sort tags by version (descending)
  table.sort(tags, function(a, b)
    local va, vb = Utils.parseVersion(a), Utils.parseVersion(b)
    if va and vb then
      return Utils.compareVersions(va, vb) > 0
    end
    return a > b
  end)

  -- Find the best matching tag
  for _, tag in ipairs(tags) do
    if Utils.versionSatisfies(tag, versionConstraint) then
      log.df("Found remote matching tag %s for constraint %s", tag, versionConstraint)
      return tag
    end
  end

  log.wf("No remote tag found matching constraint %s", versionConstraint)
  return nil
end

-- ------------------------------------------------------------------
-- Spoon
-- ------------------------------------------------------------------

---Gets the path to a Spoon
---@param spoonName string
---@return string
function Spoons.getSpoonPath(spoonName)
  return M.config.spoonDir .. "/" .. spoonName .. ".spoon"
end

---Copies a Spoon
---@param spoonName string
---@param sourcePath string
---@param destPath string
---@return boolean?
---@return string?
function Spoons.copy(spoonName, sourcePath, destPath)
  local parentDir = destPath:match("(.+)/[^/]+$")
  if parentDir then
    Utils.mkdirP(parentDir)
  end

  local sourceSpoon = sourcePath .. "/" .. spoonName .. ".spoon"
  if not Utils.dirExists(sourceSpoon) then
    return false, "Source spoon directory not found: " .. sourceSpoon
  end

  log.i(string.format("Copying %s.spoon to %s", spoonName, destPath))
  return Utils.exec(string.format("cp -r '%s' '%s'", sourceSpoon, destPath), 10)
end

---Creates a symlink to a Spoon
---@param spoonName string
---@param targetPath string
---@return boolean?
function Spoons.symlink(spoonName, targetPath)
  local symlinkPath = Spoons.getSpoonPath(spoonName)
  targetPath = Utils.normalizePath(targetPath)

  Utils.safeRemove(symlinkPath)
  Utils.mkdirP(symlinkPath:match("(.+)/[^/]+$"))

  log.i(string.format("Creating symlink: %s -> %s", symlinkPath, targetPath))
  return hs.fs.link(targetPath, symlinkPath, true)
end

---Ensures the Spoons repository is cloned
---@return boolean
function Spoons.ensureSpoonsRepo()
  if spoonsRepoCloned then
    return true
  end

  local spoonsTemp = M.config.repoDir .. "/spoons-repo"

  if not Utils.dirExists(spoonsTemp) then
    local success, err = Git.clone(M.config.git.spoonRepo, spoonsTemp)
    if not success then
      log.ef("Failed to clone Spoons repository: %s", err or "unknown error")
      return false
    end
  end

  spoonsRepoCloned = true
  return true
end

-- ------------------------------------------------------------------
-- Lockfile
-- ------------------------------------------------------------------

---Saves the current configuration to the lockfile
---@return boolean
function Lockfile.save()
  local lockfileData = {
    version = "1.0.0",
    plugins = {},
  }

  for name, plugin in pairs(configuredPlugins) do
    if plugin.enabled then
      local spoonPath = Spoons.getSpoonPath(plugin.name)
      local lockEntry = {
        name = plugin.name,
        url = plugin.url,
        branch = plugin.branch,
        tag = plugin.tag,
        commit = plugin.commit,
        version = plugin.version,
        spoon = plugin.spoon,
        dir = plugin.dir,
      }

      -- Get actual commit if it's a git repo
      if plugin.url and Utils.dirExists(spoonPath) then
        lockEntry.resolvedCommit = Git.getCommit(spoonPath)
      end

      lockfileData.plugins[name] = lockEntry
    end
  end

  local file, err = io.open(lockfilePath, "w")
  if file then
    file:write("-- Pack lockfile - tracks exact versions of installed plugins\n")
    file:write("-- This file should be committed to version control\n")
    file:write("return " .. Utils.serializeTable(lockfileData) .. "\n")
    file:close()
    log.i(string.format("Saved lockfile to %s (%d plugins)", lockfilePath, Utils.tableLength(lockfileData.plugins)))
    return true
  else
    log.ef("Failed to save lockfile to %s: %s", lockfilePath, err or "unknown error")
    return false
  end
end

---Loads the current configuration from the lockfile
---@return table<string, Hs.Pack.PluginSpec>
function Lockfile.load()
  if not lockfilePath or not Utils.pathExists(lockfilePath) then
    log.df("No lockfile found at %s", lockfilePath or "unset")
    return {}
  end

  local chunk, err = loadfile(lockfilePath)
  if chunk then
    local success, lockfileData = pcall(chunk)
    if success and type(lockfileData) == "table" and lockfileData.plugins then
      log.df("Loaded lockfile from %s (%d plugins)", lockfilePath, Utils.tableLength(lockfileData.plugins))
      return lockfileData.plugins
    else
      log.wf("Failed to load lockfile data: %s", tostring(lockfileData))
    end
  else
    log.wf("Failed to parse lockfile: %s", err or "unknown error")
  end

  return {}
end

-- ------------------------------------------------------------------
-- Plugins
-- ------------------------------------------------------------------

---Gets the installed plugins
---@return table<string, Hs.Pack.PluginInfo>
function Plugins.getInstalled()
  local installed = {}

  if not Utils.dirExists(M.config.spoonDir) then
    return installed
  end

  local handle = io.popen(string.format('find "%s" -maxdepth 1 -name "*.spoon" -type d', M.config.spoonDir))
  if handle then
    for path in handle:lines() do
      local pluginName = path:match("([^/]+)%.spoon$")
      if pluginName then
        installed[pluginName] = {
          name = pluginName,
          path = path,
          isSymlink = os.execute(string.format('[ -L "%s" ]', path)) == true,
        }
      end
    end
    handle:close()
  end

  return installed
end

---Scans a directory for plugin files
---@param dirPath string
---@return Hs.Pack.PluginSpec[]
function Plugins.scanDirectory(dirPath)
  dirPath = Utils.normalizePath(dirPath)

  if not Utils.dirExists(dirPath) then
    log.df("Plugin directory not found: %s", dirPath)
    return {}
  end

  log.i(string.format("Scanning for plugin configs in: %s", dirPath))

  local files = {}
  local handle = io.popen(string.format('find "%s" -name "*.lua" -type f', dirPath))

  if handle then
    for file in handle:lines() do
      table.insert(files, file)
    end
    handle:close()
  end

  ---@type Hs.Pack.PluginSpec[]
  local foundPlugins = {}
  local loadedCount = 0

  for _, filePath in ipairs(files) do
    local relativePath = filePath:match(".+/(.+)%.lua$") or filePath
    log.df("Loading plugin config from %s", relativePath)

    local chunk, err = loadfile(filePath)
    if chunk then
      local success, pluginSpec = pcall(chunk)
      if success then
        -- Handle function returns
        if type(pluginSpec) == "function" then
          success, pluginSpec = pcall(pluginSpec)
        end

        if success and type(pluginSpec) == "table" then
          -- if empty table, skip
          if next(pluginSpec) == nil then
            log.df("Skipping empty plugin spec")
            loadedCount = loadedCount + 1
            goto continue
          end
          -- Auto-detect plugin name from filename if not specified
          if not pluginSpec.name and not pluginSpec[1] then
            local filename = filePath:match(".+/(.+)%.lua$") or filePath:match("([^/]+)%.lua$")
            pluginSpec.name = filename
          end

          table.insert(foundPlugins, pluginSpec)
          loadedCount = loadedCount + 1
          log.df("Loaded plugin: %s", pluginSpec.name or pluginSpec[1] or "unnamed")
        else
          log.ef("Plugin file %s must return a table: %s", relativePath, tostring(pluginSpec))
        end
      else
        log.ef("Failed to execute plugin file %s: %s", relativePath, tostring(pluginSpec))
      end
      ::continue::
    else
      log.ef("Failed to parse plugin file %s: %s", relativePath, err or "unknown")
    end
  end

  log.i(string.format("Loaded %d plugin configurations from %d files", loadedCount, #files))
  return foundPlugins
end

---Normalizes a plugin spec
---@param spec Hs.Pack.PluginSpec|string
---@return Hs.Pack.PluginSpec
function Plugins.normalizeSpec(spec)
  if type(spec) == "string" then
    return { name = spec }
  end

  local plugin = {
    name = spec[1] or spec.name,
    url = spec.url,
    branch = spec.branch,
    tag = spec.tag,
    commit = spec.commit,
    version = spec.version,
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

---Installs a plugin
---@param plugin Hs.Pack.PluginSpec
---@return boolean
function Plugins.install(plugin)
  if not plugin.enabled then
    log.df("Skipping disabled plugin %s", plugin.name)
    return true
  end

  if plugin.spoon then
    if not Spoons.ensureSpoonsRepo() then
      return false
    end

    local spoonsTemp = M.config.repoDir .. "/spoons-repo"
    local spoonSource = spoonsTemp .. "/Source/" .. plugin.name
    local spoonPath = Spoons.getSpoonPath(plugin.name)

    if not Utils.dirExists(spoonSource .. ".spoon") then
      log.ef("Spoon %s not found in repository", plugin.name)
      return false
    end

    local success, err = Spoons.copy(plugin.name, spoonsTemp .. "/Source", spoonPath)
    if not success then
      log.ef("Failed to install spoon %s: %s", plugin.name, err or "unknown error")
      return false
    end
  else
    if plugin.dir then
      -- Local plugin - create symlink
      if not Utils.dirExists(plugin.dir) then
        log.ef("Local plugin directory not found: %s", plugin.dir)
        return false
      end

      local symlinkSuccess, symlinkErr = Spoons.symlink(plugin.name, plugin.dir)
      if not symlinkSuccess then
        log.ef("Failed to create symlink for plugin %s: %s", plugin.name, symlinkErr or "unknown error")
        return false
      end
    elseif plugin.url then
      -- Git plugin with version support
      local targetPath = Spoons.getSpoonPath(plugin.name)
      local versionRef = Utils.resolveVersionRef(plugin, nil) -- No repo path for initial install
      local success, err, commit = Git.clone(plugin.url, targetPath, versionRef)
      if not success then
        log.ef("Failed to install plugin %s: %s", plugin.name, err or "unknown error")
        return false
      end

      -- Update plugin with resolved commit
      if commit then
        plugin.resolvedCommit = commit
      end

      -- Log the resolved version
      if versionRef and versionRef ~= commit then
        log.i(
          string.format(
            "Installed %s at %s (commit: %s)",
            plugin.name,
            versionRef,
            commit and commit:sub(1, 7) or "unknown"
          )
        )
      end
    else
      log.ef("Plugin %s has no URL or directory specified", plugin.name)
      return false
    end
  end

  log.i(string.format("Successfully installed %s", plugin.name))
  return true
end

---Updates a plugin
---@param plugin Hs.Pack.PluginSpec
---@param useLockfile? boolean Whether to use the lockfile for version resolution
---@return boolean
function Plugins.update(plugin, useLockfile)
  local spoonPath = Spoons.getSpoonPath(plugin.name)

  if not Utils.dirExists(spoonPath) then
    log.wf("Plugin %s not installed, installing...", plugin.name)
    return Plugins.install(plugin)
  end

  if plugin.spoon then
    if not Spoons.ensureSpoonsRepo() then
      return false
    end

    local spoonsTemp = M.config.repoDir .. "/spoons-repo"
    local success, err = Git.pull(spoonsTemp)
    if not success then
      log.wf("Failed to update Spoons repository: %s", err or "unknown error")
    end

    Utils.safeRemove(spoonPath)
    return Plugins.install(plugin)
  elseif plugin.url then
    local versionRef
    if useLockfile then
      versionRef = plugin.resolvedCommit
    else
      versionRef = Utils.resolveVersionRef(plugin, spoonPath)
    end

    local success, err, commit = Git.pull(spoonPath, versionRef)
    if not success then
      log.ef("Failed to update plugin %s: %s", plugin.name, err or "unknown error")
      return false
    end

    -- Update plugin with resolved commit
    if commit then
      plugin.resolvedCommit = commit
    end

    -- Log the resolved version
    if versionRef and versionRef ~= commit then
      log.i(
        string.format(
          "Updated %s to %s (commit: %s)",
          plugin.name,
          versionRef,
          commit and commit:sub(1, 7) or "unknown"
        )
      )
    end
  elseif plugin.dir then
    local symlinkSuccess, symlinkErr = Spoons.symlink(plugin.name, plugin.dir)
    if not symlinkSuccess then
      log.wf("Failed to update symlink for plugin %s: %s", plugin.name, symlinkErr or "unknown error")
      return false
    end
  end

  log.i(string.format("Successfully updated %s", plugin.name))
  return true
end

---Loads a plugin with dependency resolution
---@param plugin Hs.Pack.PluginSpec
---@param loadingStack? table<string, boolean> The loading stack
---@return boolean
function Plugins.load(plugin, loadingStack)
  loadingStack = loadingStack or {}

  -- Detect circular dependencies
  if loadingStack[plugin.name] then
    local cycle = {}
    local found = false
    for name in pairs(loadingStack) do
      if found or name == plugin.name then
        found = true
        table.insert(cycle, name)
      end
    end
    table.insert(cycle, plugin.name)
    log.ef("Circular dependency detected: %s", table.concat(cycle, " -> "))
    return false
  end

  if not plugin.enabled then
    log.df("Skipping disabled plugin %s", plugin.name)
    return true
  end

  loadingStack[plugin.name] = true

  -- Load dependencies first
  for _, depSpec in ipairs(plugin.dependencies) do
    local dep = Plugins.normalizeSpec(depSpec)
    if not Plugins.load(dep, loadingStack) then
      log.ef("Failed to load dependency %s for %s", dep.name, plugin.name)
      loadingStack[plugin.name] = nil
      return false
    end
  end

  local spoonPath = Spoons.getSpoonPath(plugin.name)

  if not Utils.dirExists(spoonPath) then
    if M.config.autoInstall then
      log.i(string.format("Plugin %s not found, installing...", plugin.name))
      if not Plugins.install(plugin) then
        loadingStack[plugin.name] = nil
        return false
      end
    else
      log.ef("Plugin %s not installed and autoInstall is disabled", plugin.name)
      loadingStack[plugin.name] = nil
      return false
    end
  end

  -- Load the spoon
  local loadSuccess, loadError = pcall(hs.loadSpoon, plugin.name)
  if not loadSuccess then
    log.ef("Failed to load spoon %s: %s", plugin.name, loadError or "unknown error")
    loadingStack[plugin.name] = nil
    return false
  end

  -- Run configuration
  if type(plugin.config) == "function" then
    local configSuccess, configError = pcall(plugin.config)
    if not configSuccess then
      log.ef("Failed to configure plugin %s: %s", plugin.name, configError or "unknown error")
      loadingStack[plugin.name] = nil
      return false
    end
  end

  loadingStack[plugin.name] = nil
  log.i(string.format("Successfully loaded %s", plugin.name))
  return true
end

-- ------------------------------------------------------------------
-- API
-- ------------------------------------------------------------------

---@type Hs.Pack.Config
M.config = {}

---Initializes the Pack module
---@param userConfig? Hs.Pack.Config
---@return nil
function M:init(userConfig)
  print("-- Starting Pack...")
  M.config = Utils.tblDeepExtend("force", defaultConfig, userConfig or {})
  log = hs.logger.new(M.name, M.config.logLevel)

  -- Create directories
  Utils.mkdirP(M.config.repoDir)
  Utils.mkdirP(M.config.spoonDir)

  -- Setup Hammerspoon load path
  package.path = package.path .. ";" .. M.config.spoonDir .. "/?.spoon/init.lua"

  -- Handle plugin sources
  configuredPlugins = {}

  -- Load lockfile for version pinning
  local lockfileData = Lockfile.load()

  -- If directory is specified, scan it for plugin files
  if M.config.dir then
    local dirPlugins = Plugins.scanDirectory(M.config.dir)
    for _, pluginSpec in ipairs(dirPlugins) do
      local success, plugin = pcall(Plugins.normalizeSpec, pluginSpec)
      if success then
        -- Merge lockfile data if available
        if lockfileData[plugin.name] then
          plugin.resolvedCommit = lockfileData[plugin.name].resolvedCommit
        end
        configuredPlugins[plugin.name] = plugin
      else
        log.ef("Failed to normalize plugin spec: %s", plugin or "unknown error")
      end
    end
  end

  -- Add inline plugins
  if M.config.plugins then
    for _, pluginSpec in ipairs(M.config.plugins) do
      local success, plugin = pcall(Plugins.normalizeSpec, pluginSpec)
      if success then
        -- Merge lockfile data if available
        if lockfileData[plugin.name] then
          plugin.resolvedCommit = lockfileData[plugin.name].resolvedCommit
        end
        configuredPlugins[plugin.name] = plugin
      else
        log.ef("Failed to normalize plugin spec: %s", plugin or "unknown error")
      end
    end
  end

  log.i(string.format("Configured %d plugins", Utils.tableLength(configuredPlugins)))

  -- Cleanup if enabled
  if M.config.autoCleanup then
    M.clean()
  end

  -- Load all enabled plugins
  local loadedCount = 0
  local failedCount = 0
  local disabledCount = 0

  for _, plugin in pairs(configuredPlugins) do
    if not plugin.enabled then
      disabledCount = disabledCount + 1
    elseif Plugins.load(plugin) then
      loadedCount = loadedCount + 1
    else
      failedCount = failedCount + 1
    end
  end

  log.i(
    string.format("Plugin loading complete: %d loaded, %d failed, %d disabled", loadedCount, failedCount, disabledCount)
  )

  -- Save lockfile with current state
  if lockfilePath then
    Lockfile.save()
  end
end

---Updates a plugin
---@param name? string The name of the plugin to update
---@return boolean
function M.update(name)
  local lockfileData = Lockfile.load()

  if name then
    local plugin = configuredPlugins[name]
    if not plugin then
      log.ef("Plugin %s not found in current configuration", name)
      return false
    end

    -- Merge lockfile data
    if lockfileData[name] then
      plugin.resolvedCommit = lockfileData[name].resolvedCommit
    end

    return Plugins.update(plugin, false) -- Don't use lockfile for explicit updates
  else
    local success = true
    local updatedCount = 0

    for pluginName, plugin in pairs(configuredPlugins) do
      -- Merge lockfile data
      if lockfileData[pluginName] then
        plugin.resolvedCommit = lockfileData[pluginName].resolvedCommit
      end

      if Plugins.update(plugin, false) then
        updatedCount = updatedCount + 1
      else
        success = false
      end
    end

    log.i(string.format("Update complete: %d plugins updated", updatedCount))

    -- Update lockfile after successful updates
    if success and lockfilePath then
      Lockfile.save()
    end

    return success
  end
end

---Restores the plugins from the lockfile
---@return boolean
function M.restore()
  local lockfileData = Lockfile.load()

  if Utils.tableLength(lockfileData) == 0 then
    log.ef("No lockfile found, cannot restore")
    return false
  end

  log.i("Restoring plugins from lockfile...")

  local success = true
  local restoredCount = 0

  for _, lockEntry in pairs(lockfileData) do
    local plugin = Plugins.normalizeSpec(lockEntry)
    plugin.resolvedCommit = lockEntry.resolvedCommit

    if Plugins.update(plugin, true) then
      restoredCount = restoredCount + 1
    else
      success = false
    end
  end

  log.i(string.format("Restore complete: %d plugins restored", restoredCount))
  return success
end

---Enables a plugin
---@param name string The name of the plugin to enable
---@return boolean
function M.enable(name)
  if not configuredPlugins[name] then
    log.ef("Plugin %s not found", name)
    return false
  end

  if configuredPlugins[name].enabled then
    log.i(string.format("Plugin %s is already enabled", name))
    return true
  end

  configuredPlugins[name].enabled = true
  log.i(string.format("Enabled plugin %s", name))

  -- Install and load if needed
  if M.config.autoInstall then
    if Plugins.install(configuredPlugins[name]) then
      Plugins.load(configuredPlugins[name])
    end
  end

  if lockfilePath then
    Lockfile.save()
  end

  return true
end

---Disables a plugin
---@param name string The name of the plugin to disable
function M.disable(name)
  if not configuredPlugins[name] then
    log.ef("Plugin %s not found", name)
    return false
  end

  if not configuredPlugins[name].enabled then
    log.i(string.format("Plugin %s is already disabled", name))
    return true
  end

  configuredPlugins[name].enabled = false
  log.i(string.format("Disabled plugin %s", name))

  if lockfilePath then
    Lockfile.save()
  end

  return true
end

---Cleans up unused plugins
---@return integer The number of plugins cleaned up
function M.clean()
  log.i("Cleaning unused plugins...")

  local installedPlugins = Plugins.getInstalled()
  local currentPlugins = {}

  -- Build set of currently configured plugins
  for name, _ in pairs(configuredPlugins) do
    currentPlugins[name] = true
  end

  local cleanedCount = 0

  -- Remove any installed plugins that aren't in the current configuration
  for pluginName, pluginInfo in pairs(installedPlugins) do
    if not currentPlugins[pluginName] then
      log.i(string.format("Removing unused plugin %s", pluginName))

      local ok = Utils.safeRemove(pluginInfo.path)

      if ok then
        cleanedCount = cleanedCount + 1
        log.i(string.format("Removed plugin: %s", pluginInfo.path))
      else
        log.ef("Failed to remove %s", pluginInfo.path)
      end
    end
  end

  if cleanedCount > 0 then
    log.i(string.format("Cleanup complete: removed %d plugins", cleanedCount))
  else
    log.i("No unused plugins found")
  end

  return cleanedCount
end

return M
