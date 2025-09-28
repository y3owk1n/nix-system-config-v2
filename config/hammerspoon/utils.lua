---@diagnostic disable: undefined-global

local M = {}

M.keys = {}

M.keys.hyper = { "cmd", "alt", "ctrl", "shift" }
M.keys.meh = { "alt", "ctrl", "shift" }

---Installs a spoon asynchronously
---@param name string -- Spoon name
---@param repo string -- Git repository URL
---@param force boolean -- Force install even if spoon is already installed
---@param callback function -- Callback function to be called after spoon is loaded
function M.installSpoon(name, repo, force, callback)
  local packRoot = _G.k92.packRoot
  local spoonPath = string.format("%s/%s.spoon", packRoot, name)
  local spoonStat = hs.fs.attributes(spoonPath)

  -- Helper function to run shell commands async
  local function runCommand(cmd, args, onComplete)
    local task = hs.task.new(cmd, function(exitCode, stdOut, stdErr)
      onComplete(exitCode == 0, exitCode, stdOut, stdErr)
    end, args)
    task:start()
    return task
  end

  local function loadAndCallback()
    hs.loadSpoon(name)
    print(string.format("Loaded %s", name))
    if callback then
      callback(spoon[name])
    end
  end

  local function cloneSpoon()
    print(string.format("Cloning %s...", name))
    runCommand("/usr/bin/git", { "clone", repo, spoonPath }, function(success, exitCode, stdOut, stdErr)
      if success then
        print(string.format("Cloned %s", name))
        loadAndCallback()
      else
        print(string.format("Failed to clone %s (exit %s): %s", repo, exitCode, stdErr))
      end
    end)
  end

  local function removeAndClone()
    print(string.format("Removing %s", name))
    runCommand("/bin/rm", { "-rf", spoonPath }, function(success, exitCode, stdOut, stdErr)
      if success then
        print(string.format("Removed %s", name))
        cloneSpoon()
      else
        print(string.format("Failed to remove %s (exit %s): %s", name, exitCode, stdErr))
      end
    end)
  end

  if not spoonStat or force then
    if not spoonStat then
      print(string.format("Not found: %s", name))
      cloneSpoon()
    elseif force then
      print(string.format("Force installing %s", name))
      if spoonStat then
        removeAndClone()
      else
        cloneSpoon()
      end
    end
  else
    print(string.format("Found: %s", name))
    loadAndCallback()
  end
end

---Helper function to check if something is a "list-like" table
---@param t table
---@return boolean
function M.isList(t)
  if type(t) ~= "table" then
    return false
  end
  local count = 0
  for k, _ in pairs(t) do
    count = count + 1
    if type(k) ~= "number" or k <= 0 or k > count then
      return false
    end
  end
  return true
end

---Helper function to deep copy a value
---@param obj table
---@return table
function M.deepCopy(obj)
  if type(obj) ~= "table" then
    return obj
  end

  local copy = {}
  for k, v in pairs(obj) do
    copy[k] = M.deepCopy(v)
  end
  return copy
end

---@param behavior "error"|"keep"|"force"
---@param ... table
---@return table
function M.tblDeepExtend(behavior, ...)
  if select("#", ...) < 2 then
    error("tblDeepExtend expects at least 2 tables")
  end

  local ret = {}

  -- Handle the behavior parameter
  local validBehaviors = {
    error = true,
    keep = true,
    force = true,
  }

  if not validBehaviors[behavior] then
    error("invalid behavior: " .. tostring(behavior))
  end

  -- Process each table argument
  for i = 1, select("#", ...) do
    local t = select(i, ...)

    if type(t) ~= "table" then
      error("expected table, got " .. type(t))
    end

    for k, v in pairs(t) do
      if ret[k] == nil then
        -- Key doesn't exist, just copy it
        ret[k] = M.deepCopy(v)
      elseif type(ret[k]) == "table" and type(v) == "table" and not M.isList(ret[k]) and not M.isList(v) then
        -- Both are non-list tables, merge recursively
        ret[k] = M.tblDeepExtend(behavior, ret[k], v)
      else
        -- Handle conflicts based on behavior
        if behavior == "error" then
          error("key '" .. tostring(k) .. "' is already present")
        elseif behavior == "keep" then
        -- Keep existing value, do nothing
        elseif behavior == "force" then
          -- Overwrite with new value
          ret[k] = M.deepCopy(v)
        end
      end
    end
  end

  return ret
end

---Checks if a table contains a value
---@param tbl table
---@param val any
---@return boolean
function M.tblContains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

---@param mods "cmd"|"ctrl"|"alt"|"shift"|"fn"|("cmd"|"ctrl"|"alt"|"shift"|"fn")[]
---@param key string
---@param delay? number
---@param application? table
---@return nil
function M.keyStroke(mods, key, delay, application)
  if type(mods) == "string" then
    mods = { mods }
  end
  hs.eventtap.keyStroke(mods, key, delay or 0, application)
end

return M
