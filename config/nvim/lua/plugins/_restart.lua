---@type PluginModule
local M = {}

M.name = "custom.restart"

M.priority = 1

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.restart")

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
