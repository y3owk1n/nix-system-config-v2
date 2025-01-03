return {
	"tzachar/highlight-undo.nvim",
	event = { "BufReadPre" },
	specs = {
		{
			"catppuccin",
			optional = true,
			---@type CatppuccinOptions
			opts = {
				custom_highlights = function(colors)
					return {
						HighlightUndo = { bg = colors.red, fg = colors.base },
						HighlightRedo = { bg = colors.flamingo, fg = colors.base },
					}
				end,
			},
		},
	},
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
