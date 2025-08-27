local function disable_builtin_plugins()
  local plugins = {
    "2html_plugin",
    "getscript",
    "getscriptPlugin",
    "gzip",
    "logipat",
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers",
    "matchit",
    "tar",
    "tarPlugin",
    "rrhelper",
    "spellfile_plugin",
    "vimball",
    "vimballPlugin",
    "zip",
    "zipPlugin",
    "tutor",
    "rplugin",
    "synmenu",
    "optwin",
    "compiler",
    "bugreport",
    "ftplugin",
  }
  for _, name in ipairs(plugins) do
    vim.g["loaded_" .. name] = 1
  end
end

disable_builtin_plugins()

if vim.loader then
  vim.loader.enable()
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set options
require("options")

-- Set autocmds
require("autocmds")

-- Set mappings
require("mappings")

-- Set diagnostics
require("diagnostics")

-- Load plugins & lsp settings
-- NOTE: lsp configurations will be loaded after `lspconfig` is ensured
require("plugins").init()
