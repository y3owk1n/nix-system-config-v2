return {
	{
		"catppuccin/nvim",
		lazy = true,
		name = "catppuccin",
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
				}
			end,
			integrations = {
				blink_cmp = true,
				cmp = true,
				dashboard = true,
				flash = true,
				fzf = true,
				gitsigns = true,
				grug_far = true,
				harpoon = true,
				headlines = true,
				indent_blankline = { enabled = true },
				lsp_trouble = true,
				markdown = true,
				mason = true,
				mini = {
					enabled = true,
				},
				native_lsp = {
					enabled = true,
					underlines = {
						errors = { "undercurl" },
						hints = { "undercurl" },
						warnings = { "undercurl" },
						information = { "undercurl" },
					},
				},
				noice = true,
				notify = true,
				render_markdown = true,
				treesitter = true,
				treesitter_context = true,
				which_key = true,
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
