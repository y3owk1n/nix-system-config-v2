if vim.loader then
  vim.loader.enable()
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable default plugins and providers
require("disables").setup()

-- Set options
require("options").setup()

-- Set autocmds
require("autocmds").setup()

-- Set mappings
require("mappings").setup()

-- Set diagnostics
require("diagnostics").setup()

-- Load plugins & lsp settings
-- NOTE: lsp configurations will be loaded after `lspconfig` is ensured
require("plugins").setup()
