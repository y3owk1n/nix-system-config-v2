return {
	"tzachar/highlight-undo.nvim",
	lazy = true,
	event = { "BufReadPre" },
	opts = {
		keymaps = {
			undo = {
				hlgroup = "HighlightUndo",
				mode = "n",
				lhs = "u",
				map = "undo",
				opts = {},
			},
			redo = {
				hlgroup = "HighlightUndo",
				mode = "n",
				lhs = "U",
				map = "redo",
				opts = {},
			},
		},
	},
}
