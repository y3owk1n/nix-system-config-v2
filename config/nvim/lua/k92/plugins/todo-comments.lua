---@type LazySpec
return {
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPre", "BufNewFile" },
		---@type TodoOptions
		---@diagnostic disable-next-line: missing-fields
		opts = { signs = false },
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next Todo Comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous Todo Comment",
			},
		},
	},
	{
		"echasnovski/mini.pick",
		optional = true,
		keys = {
			{
				"<leader>st",
				function()
					require("k92.utils.lazy").plugin_load("todo-comments.nvim")

					-- List of keywords we want to find
					local keywords = { "TODO", "FIXME", "HACK", "WARN", "PERF", "NOTE", "TEST", "BUG", "ISSUE" }

					-- Build a single ripgrep pattern:  \b(TODO|FIXME|...)\b
					local rg_pattern = [[\b(]] .. table.concat(keywords, "|") .. [[)\b:]]

					require("mini.pick").builtin.grep({
						pattern = rg_pattern, -- ripgrep regex
					})
				end,
				desc = "Todo",
			},
		},
	},
}
