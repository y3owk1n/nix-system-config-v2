---@type LazySpec
return {
	{
		"echasnovski/mini-git",
		event = "VeryLazy",
		version = false,
		main = "mini.git",
		opts = {},
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
