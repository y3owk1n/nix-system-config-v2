local custom_name = "lazygit"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  name = custom_name,
  enabled = false,
  lazy = false,
  ---@type Lazygit.Config
  opts = {},
  keys = {
    {
      "<leader>gg",
      function()
        require(custom_name).open()
      end,
      desc = "Open lazygit",
    },
  },
}
