return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = { "prisma" },
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.servers.prismals = {}
		end,
	},
}
