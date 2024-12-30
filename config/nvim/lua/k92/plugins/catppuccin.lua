return {
	"catppuccin/nvim",
	lazy = false,
	name = "catppuccin",
	priority = 1000,
	---@type CatppuccinOptions
	opts = {
		custom_highlights = function(colors)
			return {
				-- highlight undo
				HighlightUndo = { bg = colors.red, fg = colors.base },
				HighlightRedo = { bg = colors.flamingo, fg = colors.base },
				-- blink extended
				-- TODO: Remove this when merged -> https://github.com/catppuccin/nvim/pull/809/files
				BlinkCmpKind = { fg = colors.blue },
				BlinkCmpMenu = { fg = colors.text },
				BlinkCmpMenuBorder = { fg = colors.blue },
				BlinkCmpDocBorder = { fg = colors.blue },
				BlinkCmpSignatureHelpBorder = { fg = colors.blue },
				BlinkCmpSignatureHelpActiveParameter = { bg = colors.mauve, fg = colors.crust },
			}
		end,
		integrations = {
			blink_cmp = true,
			flash = true,
			fzf = true,
			fidget = true,
			grug_far = true,
			headlines = true,
			lsp_trouble = true,
			mason = true,
			markdown = true,
			mini = {
				enabled = true,
			},
			native_lsp = {
				enabled = true,
			},
			semantic_tokens = true,
			snacks = true,
			treesitter = true,
			render_markdown = true,
			which_key = true,
		},
	},
	config = function(_, opts)
		require("catppuccin").setup(opts)

		vim.cmd("colorscheme catppuccin-macchiato")
	end,
}
