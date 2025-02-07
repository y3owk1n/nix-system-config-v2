---@type LazySpec
return {
	{
		"tzachar/highlight-undo.nvim",
		event = { "VeryLazy" },
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
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = function(_, opts)
			local colors = require("catppuccin.palettes").get_palette()

			local highlights = {
				HighlightUndo = { bg = colors.red, fg = colors.base },
				HighlightRedo = { bg = colors.flamingo, fg = colors.base },
			}

			opts.custom_highlights = opts.custom_highlights or {}

			for key, value in pairs(highlights) do
				opts.custom_highlights[key] = value
			end
		end,
	},
}
