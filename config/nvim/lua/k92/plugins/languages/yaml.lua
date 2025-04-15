local _table = require("k92.utils.table")

if vim.g.has_node then
	vim.lsp.enable("yamlls")
end

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"yaml",
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			if vim.g.has_node then
				_table.add_unique_items(opts.ensure_installed, { "yaml-language-server" })
			end
		end,
	},
}
