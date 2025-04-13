if vim.loader then
	vim.loader.enable()
end

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Disable snacks animation
vim.g.snacks_animate = false

-- Add a toggle for minimal config to be used elsewhere
-- This will disable the following plugins:
--   - dotmd
--   - undo-glow
--   - supermaven-nvim
--   - vim-tmux-navigator
vim.g.strip_personal_plugins = false

require("k92.health")
require("k92.lsp")
require("k92.lazy-bootstrap")
require("k92.lazy-plugins")
require("k92.options")
require("k92.keymaps")
require("k92.autocmds")
