---@type PluginModule
local M = {}

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "Git" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.git")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
