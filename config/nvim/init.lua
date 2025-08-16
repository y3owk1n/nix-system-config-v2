if vim.loader then
  vim.loader.enable()
end

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("k92.health")
require("k92.lazy-bootstrap")
require("k92.lazy-plugins")
require("k92.options")
require("k92.keymaps")
require("k92.autocmds")
require("k92.restart")
require("k92.diagnostics")
