---@type LazySpec
return {
	{
		"y3owk1n/undo-glow.nvim",
		-- dir = "~/Dev/undo-glow.nvim", -- Your path
		event = { "VeryLazy" },
		opts = {},
		config = function(_, opts)
			local undo_glow = require("undo-glow")
			undo_glow.setup(opts)

			vim.keymap.set("n", "u", undo_glow.undo, { noremap = true, silent = true })
			vim.keymap.set("n", "U", undo_glow.redo, { noremap = true, silent = true })
		end,
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = function(_, opts)
			local colors = require("catppuccin.palettes").get_palette()
			local highlights = {
				UgUndo = { bg = colors.red, fg = colors.base },
				UgRedo = { bg = colors.flamingo, fg = colors.base },
			}
			opts.custom_highlights = opts.custom_highlights or {}
			for key, value in pairs(highlights) do
				opts.custom_highlights[key] = value
			end
		end,
	},
}
