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
					require("time-machine").actions.create_snapshot(0)
				end,
				mode = "n",
				desc = "Create snapshot",
			},
			{
				"<leader>th",
				function()
					require("time-machine").actions.show_snapshots()
				end,
				mode = "n",
				desc = "Show history",
			},
			{
				"<leader>tx",
				function()
					require("time-machine").actions.purge_current()
				end,
				mode = "n",
				desc = "Purge current",
			},
			{
				"<leader>tX",
				function()
					require("time-machine").actions.reset_database()
				end,
				mode = "n",
				desc = "Reset database",
			},
		},
	},
}
