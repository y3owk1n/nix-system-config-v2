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
  vim.keymap.set("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", { desc = "lsp info" })
  vim.keymap.set("n", "<leader>lr", "<cmd>lsp restart<cr>", { desc = "lsp restart" })
  vim.keymap.set("n", "<leader>ls", "<cmd>lsp enable<cr>", { desc = "lsp start" })
  vim.keymap.set("n", "<leader>ld", "<cmd>lsp disable<cr>", { desc = "lsp stop" })
  vim.keymap.set(
    "n",
    "<leader>ll",
    "<cmd>lua vim.cmd('tabnew ' .. vim.lsp.log.get_filename())<cr>",
    { desc = "lsp log" }
  )

  vim.schedule(function()
    require("lsp.init").setup({
      log_level = "INFO",
    })
  end)
end

return M
