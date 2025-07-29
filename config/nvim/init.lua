local start_time = vim.uv.hrtime()

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local elapsed = (vim.loop.hrtime() - start_time) / 1e6
    local formatted = string.format("%.2f", elapsed) -- 2 decimals
    vim.g.startuptime = formatted
  end,
})

if vim.loader then
  vim.loader.enable()
end

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- First source packages
require("packages")

-- Load default configurations and plugins
for _, source in ipairs({
  "plugins",
  "options",
  "mappings",
  "autocmds",
  "lsp",
  "diagnostics",
}) do
  local ok, fault = pcall(require, source)
  if not ok then
    vim.notify("Failed to load " .. source .. "\n\n" .. fault)
  end
end
