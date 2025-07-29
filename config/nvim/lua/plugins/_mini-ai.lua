---@type PluginModule
local M = {}

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.ai")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    n_lines = 500,
  }

  plugin.setup(plugin_opts)
end

return M
