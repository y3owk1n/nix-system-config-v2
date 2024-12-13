return {
	{
		"catppuccin/nvim",
		---@module 'catppuccin'
		---@type CatppuccinOptions
		opts = {
			flavour = "macchiato", -- latte, frappe, macchiato, mocha
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
		config = function(_, opts)
			require("catppuccin").setup(opts)
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
}
