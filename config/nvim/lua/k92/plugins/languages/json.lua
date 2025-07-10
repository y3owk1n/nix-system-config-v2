local _table = require("k92.utils.table")

if vim.g.has_node then
	vim.lsp.enable("jsonls")
end

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"json",
				"jsonc",
				"json5",
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}

			if vim.g.has_node and vim.fn.executable("vscode-json-language-server") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "json-lsp" })
			end
		end,
	},
}
