local custom_name = "bigfile"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  name = custom_name,
  event = { "BufReadPre", "BufNewFile" },
  ---@type BigFile.Config
  opts = {},
}
