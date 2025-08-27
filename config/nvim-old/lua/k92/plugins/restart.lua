local custom_name = "restart"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  name = custom_name,
  lazy = false,
  ---@type Restart.Config
  opts = {},
  keys = {
    {
      "<leader>R",
      function()
        require(custom_name).save_restart()
      end,
      desc = "Save and restart",
    },
  },
}
