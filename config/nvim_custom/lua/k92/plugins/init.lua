return {
	{ "christoomey/vim-tmux-navigator" },
	{
		"b0o/SchemaStore.nvim",
		lazy = true,
		version = false, -- last release is way too old
	},
	-- {
	-- 	"windwp/nvim-ts-autotag",
	-- 	lazy = true,
	-- 	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	-- 	opts = {},
	-- 	config = true,
	-- },
	{
		"kylechui/nvim-surround",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		config = true,
	},
	{
		"NvChad/nvim-colorizer.lua",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		config = true,
	},
	{
		"dmmulroy/ts-error-translator.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
	},
	{
		"folke/todo-comments.nvim",
		lazy = true,
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{
		"y3owk1n/tailwind-autosort.nvim",
		-- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
		lazy = true,
		event = { "LspAttach" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {},
	},
}
