local _table = require("k92.utils.table")

return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "fish" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "shellcheck", "shfmt" })
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = function(_, opts)
			if vim.fn.executable("fish_indent") == 1 then
				opts.formatters_by_ft.fish = opts.formatters_by_ft.fish or {}
				opts.formatters_by_ft.fish = { "fish_indent" }
			end
		end,
	},
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters_by_ft = {
				fish = { "fish" },
			},
		},
	},
}
