---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.ai")

  if not plugin_ok then
    return
  end

  plugin.setup({
    n_lines = 500,
  })
end

return M
