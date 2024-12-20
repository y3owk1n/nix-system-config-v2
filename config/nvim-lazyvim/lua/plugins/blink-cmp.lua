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
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = {
			preset = "super-tab",
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
				LazyVim.cmp.map({ "snippet_forward", "ai_accept" }),
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
		completion = {
			list = {
				selection = "auto_insert",
			},
			menu = {
				border = "rounded",
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
			},
			documentation = {
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
}
