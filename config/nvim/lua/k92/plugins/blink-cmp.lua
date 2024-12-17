local function has_words_before()
	local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
	return col ~= 0
		and vim.api
				.nvim_buf_get_lines(0, line - 1, line, true)[1]
				:sub(col, col)
				:match '%s'
			== nil
end

return {
	'saghen/blink.cmp',
	lazy = false, -- lazy loading handled internally
	-- optional: provides snippets for the snippet source
	dependencies = 'rafamadriz/friendly-snippets',

	-- use a release tag to download pre-built binaries
	version = 'v0.*',
	-- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
	-- build = 'cargo build --release',
	-- If you use nix, you can build from source using latest nightly rust with:
	-- build = 'nix run .#build-plugin',

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		-- 'default' for mappings similar to built-in completion
		-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
		-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
		-- see the "default configuration" section below for full documentation on how to define
		-- your own keymap.
		keymap = {
			preset = 'default',
			['<CR>'] = { 'accept', 'fallback' },
			['<Esc>'] = {
				function(cmp)
					if
						require('blink.cmp.completion.windows.menu').win:is_open()
					then
						if cmp.snippet_active() then
							return cmp.hide()
						end
					end
				end,
				'fallback',
			},
			['<Tab>'] = {
				function(cmp)
					if
						require('blink.cmp.completion.windows.menu').win:is_open()
					then
						return cmp.select_next()
					elseif cmp.snippet_active() then
						return cmp.snippet_forward()
					elseif has_words_before() then
						return cmp.show()
					end
				end,
				'fallback',
			},
			['<S-Tab>'] = {
				function(cmp)
					if
						require('blink.cmp.completion.windows.menu').win:is_open()
					then
						return cmp.select_prev()
					elseif cmp.snippet_active() then
						return cmp.snippet_backward()
					end
				end,
				'fallback',
			},
		},

		appearance = {
			-- Sets the fallback highlight groups to nvim-cmp's highlight groups
			-- Useful for when your theme doesn't support blink.cmp
			-- will be removed in a future release
			use_nvim_cmp_as_default = true,
			-- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
			-- Adjusts spacing to ensure icons are aligned
			nerd_font_variant = 'mono',
		},

		-- default list of enabled providers defined so that you can extend it
		-- elsewhere in your config, without redefining it, via `opts_extend`
		sources = {
			default = { 'lsp', 'path', 'snippets', 'buffer' },
			-- optionally disable cmdline completions
			-- cmdline = {},
		},

		-- experimental signature help support
		-- signature = { enabled = true }

		completion = {
			list = {
				selection = 'auto_insert',
			},
			menu = {
				border = 'rounded',
				winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None',
			},
			documentation = {
				window = {
					border = 'rounded',
					winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None',
				},
			},
			signature = {
				window = {
					border = 'rounded',
					winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None',
				},
			},
		},
	},
	-- allows extending the providers array elsewhere in your config
	-- without having to redefine it
	opts_extend = { 'sources.default' },
}
