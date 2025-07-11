local _table = require("k92.utils.table")
local tr = require("tool-resolver.tools")

if not vim.g.has_node then
	return {}
end

vim.lsp.enable("biome")
tr.add("biome")

-- https://biomejs.dev/internals/language-support/
local supported = {
	"astro",
	"css",
	"graphql",
	-- "html",
	"javascript",
	"javascriptreact",
	"json",
	"jsonc",
	-- "markdown",
	"svelte",
	"typescript",
	"typescriptreact",
	"vue",
	-- "yaml",
}

---@type LazySpec
return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}

			if vim.fn.executable("biome") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "biome" })
			end
		end,
	},
	{
		"stevearc/conform.nvim",
		---@param opts conform.setupOpts
		opts = function(_, opts)
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			for _, ft in ipairs(supported) do
				opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
				table.insert(opts.formatters_by_ft[ft], "biome")
			end

			opts.formatters = opts.formatters or {}
			opts.formatters.biome = {
				require_cwd = true,
			}
		end,
	},
}
