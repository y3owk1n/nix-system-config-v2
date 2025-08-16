---@type LazySpec
return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/git-head",
    name = "git-head",
    event = "VeryLazy",
    ---@type GitHead.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {},
    config = function(_, opts)
      require("git-head").setup(opts)
    end,
  },
}
