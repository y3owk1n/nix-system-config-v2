---@diagnostic disable: undefined-global

local M = {}

-- Helper function to run shell commands async
local function runCommand(cmd, args, onComplete)
  local task = hs.task.new(cmd, function(exitCode, stdOut, stdErr)
    onComplete(exitCode == 0, exitCode, stdOut, stdErr)
  end, args)
  task:start()
  return task
end

local function isSymlink(path)
  local pathStat = hs.fs.symlinkAttributes(path)
  return pathStat and pathStat.mode == "link"
end

-- Safe removal that handles symlinks vs directories
local function safeRemove(path, onComplete)
  local pathStat = hs.fs.symlinkAttributes(path)
  if not pathStat then
    onComplete(true) -- Nothing to remove
    return
  end

  if pathStat.mode == "link" then
    -- It's a symlink, safe to remove just the link
    print(string.format("Removing symlink: %s", path))
    local success = os.remove(path)
    if success then
      print(string.format("Removed symlink"))
      onComplete(true)
    else
      print(string.format("Failed to remove symlink"))
      onComplete(false)
    end
  else
    -- It's a regular directory, use rm -rf
    print(string.format("Removing directory: %s", path))
    runCommand("/bin/rm", { "-rf", path }, function(success, exitCode, stdOut, stdErr)
      if success then
        print(string.format("Removed directory"))
        onComplete(true)
      else
        print(string.format("Failed to remove directory (exit %s): %s", exitCode, stdErr))
        onComplete(false)
      end
    end)
  end
end

---@class InstallFromGithubOpts
---@field name string -- Spoon name
---@field repo string -- Git repository URL
---@field force boolean? -- Force install even if spoon exists
---@field branch string? -- Git branch to checkout
---@field tag string? -- Git tag to checkout

---Installs a spoon from GitHub repository
---@param opts InstallFromGithubOpts
---@param callback function? -- Callback function after spoon is loaded
function M.installFromGithub(opts, callback)
  local name = opts.name
  local repo = opts.repo
  local force = opts.force or false
  local branch = opts.branch
  local tag = opts.tag

  local packRoot = hs.configdir .. "/Spoons"
  local spoonPath = string.format("%s/%s.spoon", packRoot, name)
  local spoonExists = hs.fs.attributes(spoonPath) ~= nil

  local function loadSpoon()
    hs.loadSpoon(name)
    print(string.format("Loaded %s", name))
    if callback then
      callback(spoon[name])
    end
  end

  local function cloneSpoon()
    local cloneArgs = { "clone" }

    -- Add branch/tag to clone command
    if branch then
      table.insert(cloneArgs, "--branch")
      table.insert(cloneArgs, branch)
    elseif tag then
      table.insert(cloneArgs, "--branch")
      table.insert(cloneArgs, tag)
    end

    table.insert(cloneArgs, repo)
    table.insert(cloneArgs, spoonPath)

    local refInfo = branch and (" (branch: " .. branch .. ")") or tag and (" (tag: " .. tag .. ")") or ""
    print(string.format("Cloning %s%s...", name, refInfo))

    runCommand("/usr/bin/git", cloneArgs, function(success, exitCode, stdOut, stdErr)
      if success then
        print(string.format("Cloned %s", name))
        loadSpoon()
      else
        print(string.format("Failed to clone %s (exit %s): %s", repo, exitCode, stdErr))
      end
    end)
  end

  local function removeAndClone()
    safeRemove(spoonPath, function(success)
      if success then
        cloneSpoon()
      end
    end)
  end

  if not spoonExists then
    print(string.format("Not found: %s", name))
    cloneSpoon()
  elseif force then
    print(string.format("Force installing %s", name))
    removeAndClone()
  else
    print(string.format("Found: %s", name))
    loadSpoon()
  end
end

---@class InstallFromZipOpts
---@field name string -- Spoon name
---@field url string -- Zip URL
---@field force boolean? -- Force install even if spoon exists

---Installs a spoon from zip URL
---@param opts InstallFromZipOpts
---@param callback function? -- Callback function after spoon is loaded
function M.installFromZip(opts, callback)
  local name = opts.name
  local zipUrl = opts.url
  local force = opts.force or false

  local packRoot = hs.configdir .. "/Spoons"
  local spoonPath = string.format("%s/%s.spoon", packRoot, name)
  local zipPath = string.format("%s/%s.spoon.zip", packRoot, name)
  local spoonExists = hs.fs.attributes(spoonPath) ~= nil

  local function loadSpoon()
    hs.loadSpoon(name)
    print(string.format("Loaded %s", name))
    if callback then
      callback(spoon[name])
    end
  end

  local function cleanupZip()
    if hs.fs.attributes(zipPath) then
      os.remove(zipPath)
    end
  end

  local function extractSpoon()
    print(string.format("Extracting %s...", name))
    runCommand("/usr/bin/unzip", { "-q", "-o", zipPath, "-d", packRoot }, function(success, exitCode, stdOut, stdErr)
      cleanupZip()
      if success then
        print(string.format("Extracted %s", name))
        loadSpoon()
      else
        print(string.format("Failed to extract %s (exit %s): %s", name, exitCode, stdErr))
      end
    end)
  end

  local function downloadSpoon()
    print(string.format("Downloading %s...", name))
    runCommand("/usr/bin/curl", { "-L", "-o", zipPath, zipUrl }, function(success, exitCode, stdOut, stdErr)
      if success then
        print(string.format("Downloaded %s", name))
        extractSpoon()
      else
        cleanupZip()
        print(string.format("Failed to download %s (exit %s): %s", zipUrl, exitCode, stdErr))
      end
    end)
  end

  local function removeAndDownload()
    safeRemove(spoonPath, function(success)
      if success then
        downloadSpoon()
      end
    end)
  end

  if not spoonExists then
    print(string.format("Not found: %s", name))
    downloadSpoon()
  elseif force then
    print(string.format("Force installing %s", name))
    removeAndDownload()
  else
    print(string.format("Found: %s", name))
    loadSpoon()
  end
end

---@class InstallFromLocalOpts
---@field name string -- Spoon name
---@field path string -- Local path to spoon directory
---@field symlink boolean? -- Create symlink (true) or copy (false), default: true
---@field force boolean? -- Force install even if spoon exists

---Links or copies a local spoon for development
---@param opts InstallFromLocalOpts
---@param callback function? -- Callback function after spoon is loaded
function M.installFromLocal(opts, callback)
  local name = opts.name
  local localPath = opts.path
  local useSymlink = opts.symlink ~= false -- default true
  local force = opts.force or false

  local packRoot = hs.configdir .. "/Spoons"
  local spoonPath = string.format("%s/%s.spoon", packRoot, name)
  local spoonExists = hs.fs.attributes(spoonPath) ~= nil
  local localExists = hs.fs.attributes(localPath) ~= nil

  if not localExists then
    print(string.format("Local path does not exist: %s", localPath))
    return
  end

  local function loadSpoon()
    hs.loadSpoon(name)
    print(string.format("Loaded %s (local)", name))
    if callback then
      callback(spoon[name])
    end
  end

  local function createLink()
    if useSymlink then
      print(string.format("Creating symlink for %s", name))
      local cmd = string.format("ln -sf '%s' '%s'", localPath, spoonPath)
      local output, status = hs.execute(cmd)
      if status then
        print(string.format("Symlinked %s", name))
        loadSpoon()
      else
        print(string.format("Failed to create symlink for %s", name))
      end
    else
      print(string.format("Copying %s...", name))
      local cmd = string.format("cp -r '%s' '%s'", localPath, spoonPath)
      local output, status = hs.execute(cmd)
      if status then
        print(string.format("Copied %s", name))
        loadSpoon()
      else
        print(string.format("Failed to copy %s", name))
      end
    end
  end

  local function removeAndLink()
    safeRemove(spoonPath, function(success)
      if success then
        createLink()
      end
    end)
  end

  if not spoonExists then
    print(string.format("Not found: %s", name))
    createLink()
  elseif force then
    print(string.format("Force installing %s", name))
    removeAndLink()
  else
    print(string.format("Found: %s", name))
    loadSpoon()
  end
end

---@class InstallFromOfficialOpts
---@field name string -- Spoon name
---@field force boolean? -- Force install even if spoon exists

---Installs a spoon from official Hammerspoon repository
---@param opts InstallFromOfficialOpts
---@param callback function? -- Callback function after spoon is loaded
function M.installFromOfficial(opts, callback)
  local name = opts.name
  local force = opts.force or false
  local officialUrl = string.format("https://github.com/Hammerspoon/Spoons/raw/master/Spoons/%s.spoon.zip", name)

  M.installFromZip({
    name = name,
    url = officialUrl,
    force = force,
  }, callback)
end

---@class InstallSpoonOpts
---@field name string -- Spoon name
---@field github string? -- GitHub repository URL
---@field branch string? -- Git branch (only for GitHub)
---@field tag string? -- Git tag (only for GitHub)
---@field local_path string? -- Local development path
---@field official boolean? -- Install from official Hammerspoon repo
---@field zip_url string? -- Direct zip URL
---@field dev boolean? -- Use development mode (local_path), default: false
---@field force boolean? -- Force install even if spoon exists
---@field symlink boolean? -- Use symlink for local (default: true)

---Universal spoon installer that handles local/GitHub switching
---@param opts InstallSpoonOpts
---@param callback function? -- Callback function after spoon is loaded
function M.install(opts, callback)
  local name = opts.name
  local dev = opts.dev or false
  local force = opts.force or false

  -- Validations
  if dev and not opts.local_path then
    print(string.format("Error: Local path not specified for %s", name))
    print("Please specify local_path in development mode")
    return
  end

  if not dev and (not opts.github and not opts.official and not opts.zip_url) then
    print(string.format("Error: No installation source specified for %s", name))
    print("Please specify one of: github, official, or zip_url")
  end

  -- Installations
  local packRoot = hs.configdir .. "/Spoons"
  local spoonPath = string.format("%s/%s.spoon", packRoot, name)

  local function installDevelopment()
    print(string.format("Installing %s in development mode", name))
    M.installFromLocal({
      name = name,
      path = opts.local_path,
      symlink = opts.symlink,
      force = force,
    }, callback)
  end

  -- Development mode
  if dev and opts.local_path then
    -- Switches to development mode
    if not isSymlink(spoonPath) then
      print(string.format("%s is not symlink but dev mode is on, maybe switching from production to dev...", name))
      print(string.format("Removing %s", name))
      safeRemove(spoonPath, function(success)
        if success then
          print(string.format("Removed %s", name))
          installDevelopment()
        else
          print(string.format("Failed to remove %s", name))
        end
      end)
    else
      installDevelopment()
    end
  end

  local function installProduction()
    print(string.format("Installing %s in production mode", name))
    if opts.github then
      -- Production mode: use GitHub
      print(string.format("Installing %s from GitHub", name))
      M.installFromGithub({
        name = name,
        repo = opts.github,
        branch = opts.branch,
        tag = opts.tag,
        force = force,
      }, callback)
    elseif opts.official then
      -- Official Hammerspoon repository
      print(string.format("Installing %s from official repository", name))
      M.installFromOfficial({
        name = name,
        force = force,
      }, callback)
    elseif opts.zip_url then
      -- Direct zip URL
      print(string.format("Installing %s from zip URL", name))
      M.installFromZip({
        name = name,
        url = opts.zip_url,
        force = force,
      }, callback)
    end
  end

  -- Production mode
  if not dev then
    -- Switches to production mode
    if isSymlink(spoonPath) then
      print(string.format("%s is symlink but dev mode is off, maybe switching from dev to production...", name))
      safeRemove(spoonPath, function(success)
        if success then
          print(string.format("Removed %s", name))
          installProduction()
        else
          print(string.format("Failed to remove %s", name))
        end
      end)
    else
      installProduction()
    end
  end
end

return M
