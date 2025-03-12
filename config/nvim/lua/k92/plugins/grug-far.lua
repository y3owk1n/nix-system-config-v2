---@type LazySpec
return {
	{
		"MagicDuck/grug-far.nvim",
		event = "VeryLazy",
		---@type GrugFarOptions
		---@diagnostic disable-next-line: missing-fields
		opts = { headerMaxWidth = 80 },
		cmd = { "GrugFar", "GrugFarWithin" },
		keys = {
			{
				"<leader>sr",
				function()
					local grug = require("grug-far")
					local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
					grug.open({
						transient = true,
						prefills = {
							filesFilter = ext and ext ~= "" and "*." .. ext or nil,
						},
					})
				end,
				mode = { "n" },
				desc = "Search and Replace",
			},
			{
				"<leader>sr",
				function()
					local grug = require("grug-far")
					grug.open({
						visualSelectionUsage = "operate-within-range",
					})
				end,
				mode = { "x" },
				desc = "Search and Replace Within",
			},
		},
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				grug_far = true,
			},
		},
	},
}
