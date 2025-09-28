---@diagnostic disable: undefined-global

local M = {}

M.keys = {}

M.keys.hyper = { "cmd", "alt", "ctrl", "shift" }
M.keys.meh = { "alt", "ctrl", "shift" }

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
