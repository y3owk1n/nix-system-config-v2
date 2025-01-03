return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				tailwindcss = {
					-- exclude a filetype from the default_config
					filetypes_exclude = { "markdown" },
					-- add additional filetypes to the default_config
					filetypes_include = {},
					-- to fully override the default_config, change the below
					-- filetypes = {}
				},
			},
		},
	},
	{
		"y3owk1n/tailwind-autosort.nvim",
		-- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
		event = { "LspAttach" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {},
	},
}
