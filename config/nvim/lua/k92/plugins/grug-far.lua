---@type LazySpec
return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    {
      "<leader>sr",
      function()
        local plugin = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        plugin.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n" },
      desc = "Search and Replace",
    },
    {
      "<leader>sr",
      function()
        local plugin = require("grug-far")
        plugin.open({
          visualSelectionUsage = "operate-within-range",
        })
      end,
      mode = { "x" },
      desc = "Search and Replace Within",
    },
  },
  ---@module "grug-far"
  ---@type grug.far.Options
  ---@diagnostic disable-next-line: missing-fields
  opts = {},
}
