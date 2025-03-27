local _table = require("k92.utils.table")

vim.lsp.enable("tailwindcss_ls")

---@type LazySpec
return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "tailwindcss-language-server" })
		end,
	},
	{
		"y3owk1n/tailwind-autosort.nvim",
		-- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
		-- version = "*",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		---@module "tailwind-autosort"
		---@type TailwindAutoSort.Config
		opts = {},
	},
}
