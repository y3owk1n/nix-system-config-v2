local custom_name = "git-head"

---@type LazySpec
return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
    name = custom_name,
    event = "VeryLazy",
    ---@type GitHead.Config
    opts = {},
  },
}
