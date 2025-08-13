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
    border = "rounded",
    padding = { left = 1, right = 1 },
    animation = {
      enabled = true,
    },
  }

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>N", function()
    plugin.show_history()
  end, { desc = "Show Notification History" })
  vim.keymap.set("n", "<leader>un", function()
    plugin.dismiss_all()
  end, { desc = "Dismiss All Notifications" })

  local old_laststatus = vim.o.laststatus
  local old_cmdheight = vim.o.cmdheight

  vim.api.nvim_create_autocmd("OptionSet", {
    callback = function()
      local new_laststatus = vim.o.laststatus
      local new_cmdheight = vim.o.cmdheight

      if new_laststatus ~= old_laststatus or new_cmdheight ~= old_cmdheight then
        old_laststatus = new_laststatus
        old_cmdheight = new_cmdheight

        -- let the plugin recalculate positions
        plugin._internal.utils.cache_config_group_row_col()
      end
    end,
  })
end

return M
