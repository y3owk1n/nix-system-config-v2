---@type LazySpec
return {
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		priority = 1000,
		---@type CatppuccinOptions
		opts = {
			default_integrations = false,
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)

			vim.cmd("colorscheme catppuccin-macchiato")
		end,
	},
	--- Custom highlight color for undo and redo
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
