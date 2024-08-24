local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		lazyrepo,
		lazypath,
	})
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "."

require("lazy").setup({
	spec = {
		{ import = "k92.plugins" },
	},
	defaults = {
		-- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
		-- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
		lazy = false,
		-- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
		-- have outdated releases, which may break your Neovim install.
		version = false, -- always use the latest git commit
		-- version = "*", -- try installing the latest stable version for plugins that support semver
	},
	checker = { enabled = true, notify = true }, -- automatically check for plugin updates
	change_detection = { enabled = false },
	performance = {
		rtp = {
			-- disable some rtp plugins
			disabled_plugins = {
				-- "2html_plugin",
				-- "bugreport",
				-- "compiler",
				-- "ftplugin",
				-- "getscript",
				-- "getscriptPlugin",
				-- "gzip",
				-- "logipat",
				-- "matchit",
				-- "netrw",
				-- "netrwFileHandlers",
				-- "netrwPlugin",
				-- "netrwSettings",
				-- "optwin",
				-- "rplugin",
				-- "rrhelper",
				-- "spellfile_plugin",
				-- "synmenu",
				-- "syntax",
				-- "tar",
				-- "tarPlugin",
				-- "tohtml",
				-- "tutor",
				-- "vimball",
				-- "vimballPlugin",
				-- "zip",
				-- "zipPlugin",
			},
		},
	},
})
