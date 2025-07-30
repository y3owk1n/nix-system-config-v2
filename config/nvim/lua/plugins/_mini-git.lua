---@type PluginModule
local M = {}

M.name = "mini.git"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

function M.setup()
  vim.pack.add({ "https://github.com/echasnovski/mini-git" })

  local plugin_ok, plugin = pcall(require, "mini.git")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
