---@type LazySpec
return {
	{
		"echasnovski/mini.ai",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			n_lines = 500,
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
