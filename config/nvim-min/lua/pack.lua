-- =========================================================
--  External plugins to install
-- =========================================================
vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/y3owk1n/base16-pro-max.nvim",
  "https://github.com/alexghergh/nvim-tmux-navigation",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/laytan/cloak.nvim",
  "https://github.com/mfussenegger/nvim-lint",
  "https://github.com/supermaven-inc/supermaven-nvim",
  "https://github.com/nvim-mini/mini.files",
  "https://github.com/nvim-mini/mini.diff",
  "https://github.com/nvim-mini/mini.icons",
})

-- =========================================================
--  Builtin plugins to enable
-- =========================================================
vim.cmd.packadd("cfilter")
vim.cmd.packadd("nvim.undotree")
