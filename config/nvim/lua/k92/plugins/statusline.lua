local custom_name = "statusline"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  lazy = false,
  name = custom_name,
  ---@type Statusline.Config
  opts = {},
}
