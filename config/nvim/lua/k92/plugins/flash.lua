return {
	"folke/flash.nvim",
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
