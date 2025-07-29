---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "nvim-tmux-navigation")

  if not plugin_ok then
    return
  end

  plugin.setup({})

  vim.keymap.set("n", "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>", { desc = "Navigate left" })
  vim.keymap.set("n", "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>", { desc = "Navigate down" })
  vim.keymap.set("n", "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>", { desc = "Navigate up" })
  vim.keymap.set("n", "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>", { desc = "Navigate right" })
end

return M
