local M = {}

local _scheme_cache = {}

--- Normalize a color string into "#rrggbb" form
---@param val string
---@return string
local function normalize_hex(val)
  -- strip leading "#" if present
  val = val:gsub("^#", "")
  -- only accept full 6-digit hex
  if val:match("^[0-9a-fA-F]+$") and #val == 6 then
    return "#" .. val:lower()
  end
  return val
end

--- Parse Base16 YAML (simple key: value + palette)
---@param path string
---@return table
function M.parse_base16_yaml(path)
  if _scheme_cache[path] then
    return _scheme_cache[path]
  end

  if vim.fn.filereadable(path) == 0 then
    _scheme_cache[path] = {}
    return {}
  end

  local lines = vim.fn.readfile(path)
  local result = {}

  for _, line in ipairs(lines) do
    if not line:match("^%s*#") and line:match("%S") then
      local _, key, val = line:match([[^(%s*)([%w_]+):%s*"?([^"]+)"?]])
      if key and val then
        result[key] = normalize_hex(vim.trim(val):gsub("%s+#.*$", ""))
      end
    end
  end

  _scheme_cache[path] = result
  return result
end

--- Get Base16 colors (cached)
---@param path string
function M.get_base16_colors(path)
  local yml_path = vim.fn.expand(path)
  local scheme = M.parse_base16_yaml(yml_path)

  local palette = {}
  for k, v in pairs(scheme) do
    if k:match("^base%w%w$") then
      palette[k] = v
    end
  end

  return palette
end

return M
