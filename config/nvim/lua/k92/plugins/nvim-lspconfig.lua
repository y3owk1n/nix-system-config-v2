---@type LazySpec
return {
  "neovim/nvim-lspconfig",
  event = { "VeryLazy" },
  keys = {
    {
      "<leader>l",
      "",
      desc = "lsp",
    },
    {
      "<leader>li",
      "<cmd>LspInfo<cr>",
      desc = "lsp info",
    },
    {
      "<leader>lr",
      "<cmd>LspRestart<cr>",
      desc = "lsp restart",
    },
    {
      "<leader>ls",
      "<cmd>LspStart<cr>",
      desc = "lsp start",
    },
    {
      "<leader>ld",
      "<cmd>LspStop<cr>",
      desc = "lsp stop",
    },
    {
      "<leader>ll",
      "<cmd>LspLog<cr>",
      desc = "lsp log",
    },
  },
  config = function()
    -- setup lsp after this
    require("k92.lsp").setup()
  end,
}
