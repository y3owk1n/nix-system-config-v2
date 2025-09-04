---@type PluginModule
local M = {}

M.name = "nvim-lspconfig"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

M.registry = {
  { src = "https://github.com/neovim/nvim-lspconfig", name = "lspconfig" },
}

function M.setup()
  local plugin_ok, _ = pcall(require, "lspconfig")

  if not plugin_ok then
    return
  end

  vim.keymap.set("n", "<leader>l", "", { desc = "lsp" })
  vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", { desc = "lsp info" })
  vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "lsp restart" })
  vim.keymap.set("n", "<leader>ls", "<cmd>LspStart<cr>", { desc = "lsp start" })
  vim.keymap.set("n", "<leader>ld", "<cmd>LspStop<cr>", { desc = "lsp stop" })
  vim.keymap.set("n", "<leader>ll", "<cmd>LspLog<cr>", { desc = "lsp log" })

  vim.schedule(function()
    require("lsp.init").setup({
      log_level = "INFO",
    })
  end)
end

return M
