---@type PluginModule
local M = {}

M.name = "mini.ai"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

M.registry = {
  { src = "https://github.com/nvim-mini/mini.ai", name = "mini.ai" },
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
