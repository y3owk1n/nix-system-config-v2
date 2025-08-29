if vim.loader then
  vim.loader.enable()
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable default plugins and providers
require("disables").init()

-- Set options
require("options").init()

-- Set autocmds
require("autocmds").init()

-- Set mappings
require("mappings").init()

-- Set diagnostics
require("diagnostics").init()

-- Load plugins & lsp settings
-- NOTE: lsp configurations will be loaded after `lspconfig` is ensured
require("plugins").init()
