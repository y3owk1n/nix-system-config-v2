---@type PluginModule
local M = {}

M.lazy = {
  keys = {
    { lhs = "<c-h>", rhs = "<cmd>NvimTmuxNavigateLeft<cr>", opts = { desc = "Navigate left" } },
    { lhs = "<c-j>", rhs = "<cmd>NvimTmuxNavigateDown<cr>", opts = { desc = "Navigate down" } },
    { lhs = "<c-k>", rhs = "<cmd>NvimTmuxNavigateUp<cr>", opts = { desc = "Navigate up" } },
    { lhs = "<c-l>", rhs = "<cmd>NvimTmuxNavigateRight<cr>", opts = { desc = "Navigate right" } },
  },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "nvim-tmux-navigation")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
