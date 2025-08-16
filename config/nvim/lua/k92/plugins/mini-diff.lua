---@type LazySpec
return {
  {
    "echasnovski/mini.diff",
    event = { "BufReadPre", "BufNewFile" },
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
  },
}
