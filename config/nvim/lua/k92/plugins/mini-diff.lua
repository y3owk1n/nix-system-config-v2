---@type LazySpec
return {
	{
		"echasnovski/mini.diff",
		version = false,
		event = "VeryLazy",
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
	},
	{
		"catppuccin/nvim",
		opts = {
			integrations = {
				mini = {
					enabled = true,
				},
			},
		},
	},
}
