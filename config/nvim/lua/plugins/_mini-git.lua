---@type PluginModule
local M = {}

M.name = "mini.git"

M.lazy = {
  cmd = {
    "Git",
  },
}

M.registry = {
  "https://github.com/echasnovski/mini-git",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.git")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    command = {
      split = "vertical",
    },
  }

  plugin.setup(plugin_opts)
end

return M
