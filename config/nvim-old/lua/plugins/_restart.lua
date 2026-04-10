---@type PluginModule
local M = {}

M.name = "restart"

M.registry = {
  { src = vim.fn.stdpath("config") .. "/lua/custom-plugins/restart", name = "restart" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "restart")

  if not plugin_ok then
    return
  end

  ---@type Restart.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>R", function()
    plugin.save_restart()
  end, { desc = "Save and restart" })
end

return M
