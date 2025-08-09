---@type PluginModule
local M = {}

M.name = "notifier"

M.registry = {
  "https://github.com/y3owk1n/notifier.nvim",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "notifier")

  if not plugin_ok then
    return
  end

  ---@type Notifier.Config
  local plugin_opts = {
    padding = { top = 1, right = 1, bottom = 1, left = 1 },
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
