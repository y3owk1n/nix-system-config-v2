local M = {}

M.hyper = { "cmd", "alt", "ctrl", "shift" }

---@param behavior "error"|"keep"|"force"
---@param ... table
---@return table
function M.tbl_deep_extend(behavior, ...)
  if select("#", ...) < 2 then
    error("tbl_deep_extend expects at least 2 tables")
  end

  local ret = {}

  -- Handle the behavior parameter
  local valid_behaviors = {
    error = true,
    keep = true,
    force = true,
  }

  if not valid_behaviors[behavior] then
    error("invalid behavior: " .. tostring(behavior))
  end

  -- Helper function to check if something is a "list-like" table
  local function is_list(t)
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

  -- Helper function to deep copy a value
  local function deep_copy(obj)
    if type(obj) ~= "table" then
      return obj
    end

    local copy = {}
    for k, v in pairs(obj) do
      copy[k] = deep_copy(v)
    end
    return copy
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
        ret[k] = deep_copy(v)
      elseif type(ret[k]) == "table" and type(v) == "table" and not is_list(ret[k]) and not is_list(v) then
        -- Both are non-list tables, merge recursively
        ret[k] = M.tbl_deep_extend(behavior, ret[k], v)
      else
        -- Handle conflicts based on behavior
        if behavior == "error" then
          error("key '" .. tostring(k) .. "' is already present")
        elseif behavior == "keep" then
          -- Keep existing value, do nothing
        elseif behavior == "force" then
          -- Overwrite with new value
          ret[k] = deep_copy(v)
        end
      end
    end
  end

  return ret
end

return M
