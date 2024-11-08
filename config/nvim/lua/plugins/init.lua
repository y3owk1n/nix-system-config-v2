return {
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
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
	-- {
	-- 	"prochri/telescope-all-recent.nvim",
	-- 	dependencies = {
	-- 		"nvim-telescope/telescope.nvim",
	-- 		"kkharji/sqlite.lua",
	-- 		-- optional, if using telescope for vim.ui.select
	-- 		"stevearc/dressing.nvim",
	-- 	},
	-- 	-- can reset the database by deleting ~/.local/share/nvim/telescope-all-recent.sqlite3
	-- 	opts = {
	-- 		-- your config goes here
	-- 		default = {
	-- 			sorting = "frecency", -- sorting: options: 'recent' and 'frecency'
	-- 		},
	-- 	},
	-- },
}
