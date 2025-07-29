---@type LazySpec
return {
  "alexghergh/nvim-tmux-navigation",
  enabled = vim.g.has_tmux,
  cmd = {
    "NvimTmuxNavigateLeft",
    "NvimTmuxNavigateDown",
    "NvimTmuxNavigateUp",
    "NvimTmuxNavigateRight",
    "NvimTmuxNavigatePrevious",
  },
  opts = {},
  keys = {
    { "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>" },
    { "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>" },
    { "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>" },
    { "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>" },
  },
}
