---@type PluginModule
local M = {}

M.name = "custom.gh"

M.lazy = {
  cmd = {
    "Gh",
  },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.gh")

  if not plugin_ok then
    return
  end

  plugin.setup()
end

return M
