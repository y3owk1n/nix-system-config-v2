---@type LazySpec
return {
	{
		"MagicDuck/grug-far.nvim",
		---@module "grug-far"
		---@type grug.far.Options
		---@diagnostic disable-next-line: missing-fields
		opts = {},
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
