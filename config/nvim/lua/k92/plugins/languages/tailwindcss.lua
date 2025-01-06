return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.servers.tailwindcss = {}
		end,
	},
	{
		"y3owk1n/tailwind-autosort.nvim",
		-- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
		event = { "LspAttach" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {},
	},
}
