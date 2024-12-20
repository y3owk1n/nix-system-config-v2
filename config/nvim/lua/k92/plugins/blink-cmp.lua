---@diagnostic disable: missing-fields

local function has_words_before()
	local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
	return col ~= 0
		and vim.api
				.nvim_buf_get_lines(0, line - 1, line, true)[1]
				:sub(col, col)
				:match("%s")
			== nil
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
					if
						require("blink.cmp.completion.windows.menu").win:is_open()
					then
						if cmp.snippet_active() then
							return cmp.hide()
						end
					end
				end,
				"fallback",
			},
			["<Tab>"] = {
				function(cmp)
					if
						require("blink.cmp.completion.windows.menu").win:is_open()
					then
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
					if
						require("blink.cmp.completion.windows.menu").win:is_open()
					then
						return cmp.select_prev()
					elseif cmp.snippet_active() then
						return cmp.snippet_backward()
					end
				end,
				"fallback",
			},
		},

		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
			kind_icons = {
				Color = "██", -- Use block instead of icon for color items to make swatches more usable
			},
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

		-- experimental signature help support
		-- signature = { enabled = true },

		completion = {
			accept = {
				-- experimental auto-brackets support
				auto_brackets = {
					enabled = true,
				},
			},
			list = {
				selection = "auto_insert",
			},
			menu = {
				draw = {
					treesitter = true,
				},
				border = "rounded",
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = {
					border = "rounded",
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
				},
			},
			signature = {
				window = {
					border = "rounded",
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
				},
			},
		},
	},
	-- allows extending the providers array elsewhere in your config
	-- without having to redefine it
	opts_extend = { "sources.default" },
}

-- vim: ts=2 sts=2 sw=2 et
