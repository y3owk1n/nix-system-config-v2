local _table = require("k92.utils.table")

vim.lsp.enable("bashls")

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "bash" } },
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "shellcheck", "shfmt", "bash-language-server" })
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
