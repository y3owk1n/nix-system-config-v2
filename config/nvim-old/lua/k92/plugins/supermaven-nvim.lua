return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = "<C-y>",
      },
      ignore_filetypes = { "bigfile", "float_info", "minifiles", "minipick" },
    },
  },
}
