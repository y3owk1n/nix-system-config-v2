local function has_words_before()
	local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

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
				["<CR>"] = { "accept", "fallback" },
				["<Esc>"] = {
					function(cmp)
						if cmp.is_visible() then
							if cmp.snippet_active() then
								return cmp.hide()
							end
						end
					end,
					"fallback",
				},
				["<Tab>"] = {
					function(cmp)
						if cmp.is_visible() then
							return cmp.select_next()
						elseif cmp.snippet_active() then
							return cmp.snippet_forward()
						elseif has_words_before() then
							return cmp.show()
						end
					end,
					"fallback",
				},
				["<S-Tab>"] = {
					function(cmp)
						if cmp.is_visible() then
							return cmp.select_prev()
						elseif cmp.snippet_active() then
							return cmp.snippet_backward()
						end
					end,
					"fallback",
				},
			},

			appearance = {
				nerd_font_variant = "mono",
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer", "lazydev" },
				cmdline = {},
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						score_offset = 100, -- show at a higher priority than lsp
					},
				},
			},

			completion = {
				list = {
					selection = "auto_insert",
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

			signature = { enabled = true, window = {
				border = "rounded",
			} },
		},
		-- allows extending the providers array elsewhere in your config
		-- without having to redefine it
		opts_extend = { "sources.default" },
	},
	{
		"catppuccin/nvim",
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
