---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.git")

  if not plugin_ok then
    return
  end

  plugin.setup()
end

return M
