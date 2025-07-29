---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, package = pcall(require, "cloak")

  if not plugin_ok then
    return
  end

  package.setup()
end

return M
