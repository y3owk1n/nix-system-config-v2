local _table = require("k92.utils.table")

if not vim.g.has_docker then
	return {}
end

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

			if vim.fn.executable("docker-compose-langserver") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "docker-compose-language-service" })
			end

			if vim.fn.executable("hadolint") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "hadolint" })
			end

			if vim.fn.executable("docker-langserver") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "dockerfile-language-server" })
			end
		end,
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = {
			linters_by_ft = {
				dockerfile = { "hadolint" },
			},
		},
	},
}
