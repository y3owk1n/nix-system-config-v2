---@type PluginModule
local M = {}

M.requires = { "_nvim-treesitter" }

function M.setup()
  local plugin_ok, plugin = pcall(require, "tailwind-autosort")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
