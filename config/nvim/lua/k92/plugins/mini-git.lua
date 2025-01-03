return {
	"echasnovski/mini-git",
	event = "VeryLazy",
	version = false,
	specs = {
		{
			"catppuccin",
			optional = true,
			---@type CatppuccinOptions
			opts = { integrations = {
				mini = {
					enabled = true,
				},
			} },
		},
	},
	main = "mini.git",
	opts = {},
}
