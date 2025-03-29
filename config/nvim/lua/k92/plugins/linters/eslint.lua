local _table = require("k92.utils.table")

vim.lsp.enable("eslint")

---@type LazySpec
return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "eslint-lsp" })
		end,
	},
}
