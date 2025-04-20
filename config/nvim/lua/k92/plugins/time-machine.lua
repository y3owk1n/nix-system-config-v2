---@type LazySpec
return {
	{
		"y3owk1n/time-machine.nvim",
		-- dir = "~/Dev/time-machine.nvim", -- Your path
		event = { "VeryLazy" },
		enabled = not vim.g.strip_personal_plugins,
		opts = {
			retention_days = 14,
			debounce_ms = 1000,
			auto_save = false,
		},
		keys = {
			{
				"<leader>tc",
				function()
					require("time-machine").create_snapshot(0)
				end,
				mode = "n",
				desc = "Create snapshot",
			},
			{
				"<leader>th",
				function()
					require("time-machine").show_history()
				end,
				mode = "n",
				desc = "Show history",
			},
			{
				"<leader>tt",
				function()
					require("time-machine").tag_snapshot()
				end,
				mode = "n",
				desc = "Tag snapshot",
			},
			{
				"<leader>tx",
				function()
					require("time-machine").purge_current()
				end,
				mode = "n",
				desc = "Purge current",
			},
		},
	},
}
