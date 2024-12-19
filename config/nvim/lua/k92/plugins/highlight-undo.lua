return {
	"tzachar/highlight-undo.nvim",
	event = { "BufReadPre" },
	opts = {
		keymaps = {
			undo = {
				desc = "undo",
				hlgroup = "HighlightUndo",
				mode = "n",
				lhs = "u",
				rhs = nil,
				opts = {},
			},
			redo = {
				desc = "redo",
				hlgroup = "HighlightRedo",
				mode = "n",
				lhs = "U",
				rhs = nil,
				opts = {},
			},
		},
	},
}
