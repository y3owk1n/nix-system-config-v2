---@type PluginModule
local M = {}

M.name = "git-head"

M.lazy = {
  event = {
    "VeryLazy",
  },
}

M.registry = {
  { src = vim.fn.stdpath("config") .. "/lua/custom-plugins/git-head", name = "git-head" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "git-head")

  if not plugin_ok then
    return
  end

  ---@type GitHead.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
