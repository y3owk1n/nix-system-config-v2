return {
  {
    "supermaven-inc/supermaven-nvim",
    enabled = not vim.g.strip_personal_plugins,
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = "<C-y>",
      },
      ignore_filetypes = { "bigfile", "float_info", "minifiles", "minipick" },
    },
  },
}
