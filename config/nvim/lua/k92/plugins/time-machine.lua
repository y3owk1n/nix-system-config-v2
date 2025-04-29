---@type LazySpec
return {
	{
		"y3owk1n/time-machine.nvim",
		-- dir = "~/Dev/time-machine.nvim", -- Your path
		cmd = {
			"TimeMachineToggle",
			"TimeMachinePurgeBuffer",
			"TimeMachinePurgeAll",
			"TimeMachineLogShow",
			"TimeMachineLogClear",
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
			{
				"<leader>tl",
				"<cmd>TimeMachineLogShow<cr>",
				desc = "[Time Machine] Show log",
			},
		},
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = function(_, opts)
			local colors = require("catppuccin.palettes").get_palette()

			local c_utils = require("catppuccin.utils.colors")

			---@type {[string]: CtpHighlight}
			local highlights = {
				TimeMachineCurrent = {
					bg = c_utils.darken(colors.blue, 0.18, colors.base),
					fg = colors.blue,
					style = { "bold" },
				},
				TimeMachineTimeline = { fg = colors.blue, style = { "bold" } },
				TimeMachineTimelineAlt = { fg = colors.overlay2 },
				TimeMachineKeymap = { fg = colors.teal, style = { "italic" } },
				TimeMachineInfo = { fg = colors.subtext0, style = { "italic" } },
				TimeMachineSeq = { fg = colors.peach, style = { "bold" } },
				TimeMachineTag = { fg = colors.yellow, style = { "bold" } },
			}

			opts.custom_highlights = opts.custom_highlights or {}

			for key, value in pairs(highlights) do
				opts.custom_highlights[key] = value
			end
		end,
	},
}
