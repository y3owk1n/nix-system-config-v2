local _table = require("k92.utils.table")

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "bash" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "shellcheck", "shfmt" })

			opts.servers = opts.servers or {}
			opts.servers.bashls = {}
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				sh = { "shfmt" },
			},
		},
	},
}
