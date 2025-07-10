local _table = require("k92.utils.table")

if not vim.g.has_go then
	return {}
end

vim.lsp.enable("gopls")

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"go",
				"gomod",
				"gowork",
				"gosum",
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}

			if vim.fn.executable("gopls") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "gopls" })
			end

			if vim.fn.executable("goimports") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "goimports" })
			end

			if vim.fn.executable("gofumpt") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "gofumpt" })
			end

			if vim.fn.executable("golangci-lint") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "golangci-lint" })
			end
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				go = { "goimports", "gofumpt" },
			},
		},
	},

	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = {
			linters_by_ft = {
				go = { "golangcilint" },
			},
		},
	},
	{
		"echasnovski/mini.icons",
		opts = {
			file = {
				[".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
			},
			filetype = {
				gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
			},
		},
	},
}
