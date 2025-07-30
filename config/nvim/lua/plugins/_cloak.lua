---@type PluginModule
local M = {}

M.name = "cloak"

M.lazy = { event = { "BufReadPre", "BufNewFile" } }

function M.setup()
  vim.pack.add({ "https://github.com/laytan/cloak.nvim" })

  local plugin_ok, plugin = pcall(require, "cloak")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
