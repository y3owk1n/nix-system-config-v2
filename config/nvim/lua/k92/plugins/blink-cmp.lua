local function has_words_before()
	local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

return {
	"saghen/blink.cmp",
	event = "InsertEnter",
	dependencies = "rafamadriz/friendly-snippets",
	version = "v0.*",
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
}
