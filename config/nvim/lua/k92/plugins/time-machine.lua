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
				"<leader>t",
				"",
				desc = "Time Machine",
			},
			{
				"<leader>tt",
				function()
					require("time-machine").actions.toggle()
				end,
				mode = "n",
				desc = "[Time Machine] Toggle Tree",
			},
			{
				"<leader>tx",
				function()
					require("time-machine").actions.purge_current()
				end,
				mode = "n",
				desc = "[Time Machine] Purge current",
			},
			{
				"<leader>tX",
				function()
					require("time-machine").actions.purge_all()
				end,
				mode = "n",
				desc = "[Time Machine] Purge all",
			},
		},
	},
}
