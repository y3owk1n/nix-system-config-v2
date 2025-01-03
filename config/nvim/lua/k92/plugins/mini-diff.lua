---@type LazySpec
return {
	"echasnovski/mini.diff",
	version = false,
	event = "VeryLazy",
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
	opts = {
		view = {
			style = "sign",
			signs = {
				add = "▎",
				change = "▎",
				delete = "",
			},
		},
	},
}
