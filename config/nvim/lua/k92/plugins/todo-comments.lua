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
		"folke/snacks.nvim",
		optional = true,
		keys = {
			{
				"<leader>st",
				function()
					require("k92.utils.lazy").plugin_load("todo-comments.nvim")

					Snacks.picker.todo_comments()
				end,
				desc = "Todo",
			},
			{
				"<leader>sT",
				function()
					require("k92.utils.lazy").plugin_load("todo-comments.nvim")

					Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
				end,
				desc = "Todo/Fix/Fixme",
			},
		},
	},
}
