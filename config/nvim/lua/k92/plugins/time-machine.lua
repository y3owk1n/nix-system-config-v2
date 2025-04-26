---@type LazySpec
return {
	{
		"y3owk1n/time-machine.nvim",
		-- dir = "~/Dev/time-machine.nvim", -- Your path
		cmd = {
			"TimeMachineToggle",
			"TimeMachinePurgeBuffer",
			"TimeMachinePurgeAll",
		},
		---@module "time-machine"
		---@type TimeMachine.Config
		opts = {
			diff_tool = "difft",
			keymaps = {
				redo = "U",
			},
		},
		keys = {
			{
				"<leader>t",
				"",
				desc = "Time Machine",
			},
			{
				"<leader>tt",
				"<cmd>TimeMachineToggle<cr>",
				desc = "[Time Machine] Toggle Tree",
			},
			{
				"<leader>tx",
				"<cmd>TimeMachinePurgeBuffer<cr>",
				desc = "[Time Machine] Purge current",
			},
			{
				"<leader>tX",
				"<cmd>TimeMachinePurgeAll<cr>",
				desc = "[Time Machine] Purge all",
			},
		},
	},
}
