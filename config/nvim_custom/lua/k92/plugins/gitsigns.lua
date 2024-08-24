return {
	"lewis6991/gitsigns.nvim",
	lazy = true,
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	opts = {},
	keys = {
		{
			"<leader>gp",
			mode = { "n" },
			":Gitsigns preview_hunk<cr>",
			desc = "Preview hunk",
		},
	},
}
