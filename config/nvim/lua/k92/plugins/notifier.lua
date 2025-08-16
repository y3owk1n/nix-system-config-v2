---@type LazySpec
return {
  "y3owk1n/notifier.nvim",
  lazy = false,
  priority = 1000,
  keys = {
    {
      "<leader>N",
      function()
        require("notifier").show_history()
      end,
      desc = "Notification History",
    },
    {
      "<leader>un",
      function()
        require("notifier").dismiss_all()
      end,
      desc = "Dismiss All Notifications",
    },
  },
  ---@type Notifier.Config
  opts = {
    border = "rounded",
    padding = { left = 1, right = 1 },
    animation = {
      enabled = true,
    },
  },
  config = function(_, opts)
    local plugin = require("notifier")

    plugin.setup(opts)

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
  end,
}
