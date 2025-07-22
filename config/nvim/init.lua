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

-- Add a toggle for minimal config to be used elsewhere
-- This will disable the following plugins:
--   - dotmd
--   - undo-glow
--   - supermaven-nvim
vim.g.strip_personal_plugins = false

-- Check if the executables are available
-- This is used to enable/disable certain plugins / features
vim.g.has_node = vim.fn.executable("node") == 1
vim.g.has_go = vim.fn.executable("go") == 1
vim.g.has_bash = vim.fn.executable("bash") == 1
vim.g.has_docker = vim.fn.executable("docker") == 1
vim.g.has_fish = vim.fn.executable("fish") == 1
vim.g.has_git = vim.fn.executable("git") == 1
vim.g.has_just = vim.fn.executable("just") == 1
vim.g.has_nix = vim.fn.executable("nix") == 1
vim.g.has_tmux = vim.fn.executable("tmux") == 1

local function is_nixos()
	local os_release, err = pcall(vim.fn.readfile, "/etc/os-release")
	if err then
		return false
	end
	for _, line in ipairs(os_release) do
		if line:match("^ID=nixos") then
			return true
		end
	end

	return false
end

local function is_nixdarwin()
	return vim.fn.executable("darwin-rebuild") == 1
end

vim.g.disable_mason = is_nixos() or is_nixdarwin()

require("k92.health")
require("k92.lsp")
require("k92.lazy-bootstrap")
require("k92.lazy-plugins")
require("k92.options")
require("k92.keymaps")
require("k92.autocmds")
