local _table = require("k92.utils.table")

vim.lsp.enable({
	"dockerls",
	"docker_compose_language_service",
})

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "dockerfile" })

			vim.filetype.add({
				pattern = {
					["docker?-compose?.ya?ml"] = "yaml.docker-compose",
				},
			})
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(
				opts.ensure_installed,
				{ "dockerfile-language-server", "docker-compose-language-service", "hadolint" }
			)
		end,
	},
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters_by_ft = {
				dockerfile = { "hadolint" },
			},
		},
	},
}
