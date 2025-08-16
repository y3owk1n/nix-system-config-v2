local M = {}

function M.decode_json_file(filename)
  local file = io.open(filename, "r")
  if file then
    local content = file:read("*all")
    file:close()

    local ok, data = pcall(vim.fn.json_decode, content)
    if ok and type(data) == "table" then
      return data
    end
  end
end

function M.has_nested_key(json, ...)
  return vim.tbl_get(json, ...) ~= nil
end

return M
