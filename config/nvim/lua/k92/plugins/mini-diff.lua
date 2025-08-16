---@type LazySpec
return {
  "echasnovski/mini.diff",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    {
      "<leader>gd",
      function()
        require("mini.diff").toggle_overlay(0)
      end,
      mode = "n",
      desc = "Toggle diff overlay",
    },
  },
  opts = {
    view = {
      style = "sign",
      signs = {
        add = "▎",
        change = "▎",
        delete = "",
      },
    },
  },
}
