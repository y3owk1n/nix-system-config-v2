return {
	{
		"catppuccin/nvim",
		---@module 'catppuccin'
		---@type CatppuccinOptions
		opts = {
			flavour = "macchiato", -- latte, frappe, macchiato, mocha
			background = { -- :h background
				light = "latte",
				dark = "macchiato",
			},
			custom_highlights = function(colors)
				return {
					HighlightUndo = { bg = colors.red, fg = colors.base },
					HighlightRedo = { bg = colors.flamingo, fg = colors.base },
				}
			end,
			integrations = {
				fzf = true,
			},
		},
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
}
