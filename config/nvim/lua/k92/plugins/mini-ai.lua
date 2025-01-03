return {
	"echasnovski/mini.ai",
	event = { "BufReadPre", "BufNewFile" },
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
		n_lines = 500,
	},
}
