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
			preset = "default",
			["<CR>"] = { "accept", "fallback" },
			["<Esc>"] = {
				function(cmp)
					if cmp.windows.autocomplete.win:is_open() then
						return cmp.hide()
					else
						return cmp.cancel()
					end
				end,
				"fallback",
			},
			["<Tab>"] = {
				function(cmp)
					if cmp.windows.autocomplete.win:is_open() then
						return cmp.select_next()
					elseif cmp.is_in_snippet() then
						return cmp.snippet_forward()
					elseif has_words_before() then
						return cmp.show()
					end
				end,
				"fallback",
			},
			["<S-Tab>"] = {
				function(cmp)
					if cmp.windows.autocomplete.win:is_open() then
						return cmp.select_prev()
					elseif cmp.is_in_snippet() then
						return cmp.snippet_backward()
					end
				end,
				"fallback",
			},
		},
		windows = {
			autocomplete = {
				border = "rounded",
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
				selection = "auto_insert",
			},
			documentation = {
				auto_show = true,
				border = "rounded",
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
			},
			signature_help = {
				border = "rounded",
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
			},
		},
	},
}
