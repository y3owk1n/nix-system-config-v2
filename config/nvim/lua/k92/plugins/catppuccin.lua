return {
	"catppuccin/nvim",
	lazy = false,
	name = "catppuccin",
	priority = 1000,
	---@type CatppuccinOptions
	opts = {
		custom_highlights = function(colors)
			return {
				HighlightUndo = { bg = colors.red, fg = colors.base },
				HighlightRedo = { bg = colors.flamingo, fg = colors.base },
			}
		end,
		integrations = {
			blink_cmp = true,
			flash = true,
			fzf = true,
			fidget = true,
			grug_far = true,
			gitsigns = true,
			headlines = true,
			lsp_trouble = true,
			mason = true,
			markdown = true,
			mini = true,
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
			semantic_tokens = true,
			snacks = true,
			treesitter = true,
			treesitter_context = true,
			render_markdown = true,
			which_key = true,
		},
	},
	config = function(_, opts)
		require("catppuccin").setup(opts)

		vim.cmd("colorscheme catppuccin-macchiato")
	end,
}

-- vim: ts=2 sts=2 sw=2 et
