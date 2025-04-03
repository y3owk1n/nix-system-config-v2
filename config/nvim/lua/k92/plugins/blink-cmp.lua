---@type LazySpec
return {
	{
		"saghen/blink.cmp",
		event = { "VeryLazy" },
		dependencies = "rafamadriz/friendly-snippets",
		version = "*",
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				preset = "default",
				["<CR>"] = { "select_and_accept", "fallback" },
				["<C-n>"] = { "show", "select_next", "fallback" },
				["<C-p>"] = { "show", "select_prev", "fallback" },
			},

			appearance = {
				nerd_font_variant = "mono",
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			cmdline = {
				enabled = false,
				sources = {},
			},
			completion = {
				list = {
					selection = {
						preselect = false,
					},
				},
				menu = {
					draw = {
						treesitter = { "lsp" },
					},
					border = "rounded",
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = {
						border = "rounded",
					},
				},
			},

			signature = {
				enabled = true,
				window = {
					border = "rounded",
				},
			},
		},
		-- allows extending the providers array elsewhere in your config
		-- without having to redefine it
		opts_extend = { "sources.default" },
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = function(_, opts)
			local colors = require("catppuccin.palettes").get_palette()

			local highlights = {
				-- TODO: Remove this when merged -> https://github.com/catppuccin/nvim/pull/809/files
				BlinkCmpLabel = { fg = colors.overlay2 },
				BlinkCmpLabelDeprecated = { fg = colors.overlay0, style = { "strikethrough" } },
				BlinkCmpKind = { fg = colors.blue },
				BlinkCmpMenu = { fg = colors.text },
				BlinkCmpMenuBorder = { fg = colors.blue },
				BlinkCmpDocBorder = { fg = colors.blue },
				BlinkCmpSignatureHelpActiveParameter = { fg = colors.mauve },
				BlinkCmpSignatureHelpBorder = { fg = colors.blue },
				BlinkCmpLabelMatch = { fg = colors.text, style = { "bold" } },
				BlinkCmpKindText = { fg = colors.green },
				BlinkCmpKindMethod = { fg = colors.blue },
				BlinkCmpKindFunction = { fg = colors.blue },
				BlinkCmpKindConstructor = { fg = colors.blue },
				BlinkCmpKindField = { fg = colors.green },
				BlinkCmpKindVariable = { fg = colors.flamingo },
				BlinkCmpKindClass = { fg = colors.yellow },
				BlinkCmpKindInterface = { fg = colors.yellow },
				BlinkCmpKindModule = { fg = colors.blue },
				BlinkCmpKindProperty = { fg = colors.blue },
				BlinkCmpKindUnit = { fg = colors.green },
				BlinkCmpKindValue = { fg = colors.peach },
				BlinkCmpKindEnum = { fg = colors.yellow },
				BlinkCmpKindKeyword = { fg = colors.mauve },
				BlinkCmpKindSnippet = { fg = colors.flamingo },
				BlinkCmpKindColor = { fg = colors.red },
				BlinkCmpKindFile = { fg = colors.blue },
				BlinkCmpKindReference = { fg = colors.red },
				BlinkCmpKindFolder = { fg = colors.blue },
				BlinkCmpKindEnumMember = { fg = colors.teal },
				BlinkCmpKindConstant = { fg = colors.peach },
				BlinkCmpKindStruct = { fg = colors.blue },
				BlinkCmpKindEvent = { fg = colors.blue },
				BlinkCmpKindOperator = { fg = colors.sky },
				BlinkCmpKindTypeParameter = { fg = colors.maroon },
				BlinkCmpKindCopilot = { fg = colors.teal },
			}

			opts.custom_highlights = opts.custom_highlights or {}

			for key, value in pairs(highlights) do
				opts.custom_highlights[key] = value
			end

			opts.integrations = {
				blink_cmp = true,
			}
		end,
	},
}
