---@type PluginModule
local M = {}

M.name = "custom.notifier"

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.notifier")

  if not plugin_ok then
    return
  end

  ---@type Notifier.Config
  local plugin_opts = {
    padding = { top = 1, right = 1, bottom = 1, left = 1 },
    group_configs = {
      important = {
        anchor = "SW", -- South-West
        row = vim.o.lines - 2,
        col = 0,
      },
    },
  }

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>N", function()
    plugin.show_history()
  end, { desc = "Show Notification History" })
  vim.keymap.set("n", "<leader>un", function()
    plugin.dismiss_all()
  end, { desc = "Dismiss All Notifications" })
end

return M
