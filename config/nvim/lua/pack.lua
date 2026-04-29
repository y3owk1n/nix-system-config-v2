-- =========================================================
--  External plugins to install
-- =========================================================

vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/y3owk1n/base16-pro-max.nvim",
  "https://github.com/alexghergh/nvim-tmux-navigation",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/supermaven-inc/supermaven-nvim",
  "https://github.com/nvim-mini/mini.files",
  "https://github.com/nvim-mini/mini.diff",
  "https://github.com/nvim-mini/mini.icons",
  "https://github.com/y3owk1n/undo-glow.nvim",
  "https://github.com/y3owk1n/notifier.nvim",
})

-- =========================================================
--  Builtin plugins to enable
-- =========================================================

vim.cmd.packadd("cfilter")
vim.cmd.packadd("nvim.undotree")
