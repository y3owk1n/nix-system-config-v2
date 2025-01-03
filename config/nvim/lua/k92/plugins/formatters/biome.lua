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
		opts = {
			ensure_installed = { "biome" },
			servers = {
				biome = {},
			},
		},
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
