---@type PluginModule
local M = {}

M.name = "custom.git-head"

M.lazy = {
  event = {
    "VeryLazy",
  },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.git-head")

  if not plugin_ok then
    return
  end

  ---@type GitHead.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
