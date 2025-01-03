return {
	"folke/flash.nvim",
	specs = {
		{
			"catppuccin",
			optional = true,
			---@type CatppuccinOptions
			opts = { integrations = { flash = true } },
		},
	},
	event = { "BufReadPre", "BufNewFile" },
	---@type Flash.Config
	---@diagnostic disable-next-line: missing-fields
	opts = {},
	keys = {
		{
			"s",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump()
			end,
			desc = "Flash",
		},
	},
}
