---@type PluginModule
local M = {}

M.name = "nvim-tmux-navigation"

M.lazy = {
  cmd = { "NvimTmuxNavigateLeft", "NvimTmuxNavigateDown", "NvimTmuxNavigateUp", "NvimTmuxNavigateRight" },
  keys = {
    "<c-h>",
    "<c-j>",
    "<c-k>",
    "<c-l>",
  },
}

function M.setup()
  vim.pack.add({ "https://github.com/alexghergh/nvim-tmux-navigation" })

  local plugin_ok, plugin = pcall(require, "nvim-tmux-navigation")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>", { desc = "Navigate left" })
  vim.keymap.set("n", "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>", { desc = "Navigate down" })
  vim.keymap.set("n", "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>", { desc = "Navigate up" })
  vim.keymap.set("n", "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>", { desc = "Navigate right" })
end

return M
