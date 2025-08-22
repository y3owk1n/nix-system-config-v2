local custom_name = "statusline"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  event = "VeryLazy",
  name = custom_name,
  init = function()
    vim.opt.laststatus = 0 -- disable the statusline and let the plugin to handle it
  end,
  ---@type Statusline.Config
  opts = {},
}
