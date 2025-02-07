---@type LazySpec
return {
	{
		"folke/flash.nvim",
		event = { "VeryLazy" },
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
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				flash = true,
			},
		},
	},
}
