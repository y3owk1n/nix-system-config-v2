---@type LazySpec
return {
	{
		"y3owk1n/time-machine.nvim",
		-- dir = "~/Dev/time-machine.nvim", -- Your path
		event = { "VeryLazy" },
		enabled = not vim.g.strip_personal_plugins,
		---@type TimeMachine.Config
		opts = {
			diff_tool = "difft",
		},
		keys = {
			{
				"<leader>th",
				function()
					require("time-machine").actions.toggle_tree()
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
					require("time-machine").actions.purge_all()
				end,
				mode = "n",
				desc = "Purge all",
			},
		},
	},
}
