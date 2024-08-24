return {
	"lukas-reineke/indent-blankline.nvim",
	lazy = true,
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	main = "ibl",
	opts = {
		indent = {
			char = "│",
			tab_char = "│",
		},
		scope = { show_start = false, show_end = false },
		exclude = {
			filetypes = {
				"help",
				"neo-tree",
				"Trouble",
				"trouble",
				"lazy",
				"mason",
				"notify",
			},
		},
	},
}
