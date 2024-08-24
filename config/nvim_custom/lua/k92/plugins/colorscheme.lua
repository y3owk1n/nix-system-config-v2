return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function(_, opts)
		require("catppuccin").setup(opts)
		-- load the colorscheme here
		vim.cmd([[colorscheme catppuccin]])
	end,
	opts = {
		flavour = "macchiato", -- latte, frappe, macchiato, mocha
		background = { -- :h background
			light = "latte",
			dark = "macchiato",
		},
		transparent_background = true, -- disables setting the background color.
		show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
		term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
		dim_inactive = {
			enabled = true, -- dims the background color of inactive window
			shade = "dark",
			percentage = 0.15, -- percentage of the shade to apply to the inactive window
		},
		no_italic = false, -- Force no italic
		no_bold = false, -- Force no bold
		no_underline = false, -- Force no underline
		styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
			comments = { "italic" }, -- Change the style of comments
			conditionals = { "italic" },
			loops = {},
			functions = {},
			keywords = {},
			strings = {},
			variables = {},
			numbers = {},
			booleans = {},
			properties = {},
			types = {},
			operators = {},
		},
		color_overrides = {},
		custom_highlights = function(colors)
			return {
				HighlightUndo = { bg = colors.red, fg = colors.base },
			}
		end,
		integrations = {
			fidget = true,
			flash = true,
			gitsigns = true,
			harpoon = true,
			markdown = true,
			mason = true,
			neotree = true,
			cmp = true,
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
			treesitter = true,
			treesitter_context = true,
			ufo = true,
			telescope = {
				enabled = true,
			},
			lsp_trouble = true,
			which_key = true,
			indent_blankline = {
				enabled = true,
				colored_indent_levels = false,
			},
		},
	},
}
