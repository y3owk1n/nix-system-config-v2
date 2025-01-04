local _table = require("k92.utils.table")

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

return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "biome" })

			opts.servers = opts.servers or {}
			opts.servers.biome = {}
		end,
	},

	{
		"stevearc/conform.nvim",
		---@param opts ConformOpts
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
