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
				default = { "lsp", "path", "snippets", "buffer", "lazydev" },
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						score_offset = 100, -- show at a higher priority than lsp
					},
				},
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
				BlinkCmpKind = { fg = colors.blue },
				BlinkCmpMenu = { fg = colors.text },
				BlinkCmpMenuBorder = { fg = colors.blue },
				BlinkCmpDocBorder = { fg = colors.blue },
				BlinkCmpSignatureHelpBorder = { fg = colors.blue },
				BlinkCmpSignatureHelpActiveParameter = { bg = colors.mauve, fg = colors.crust },
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
