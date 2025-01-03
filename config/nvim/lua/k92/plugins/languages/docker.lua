return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "dockerfile" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			ensure_installed = { "hadolint" },
			servers = {
				dockerls = {},
				docker_compose_language_service = {},
			},
		},
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
