return {
	{
		"supermaven-inc/supermaven-nvim",
		enabled = not vim.g.strip_personal_plugins,
		event = "VeryLazy",
		opts = {
			keymaps = {
				accept_suggestion = "<C-y>",
			},
			ignore_filetypes = { "bigfile", "snacks_input", "snacks_notif" },
		},
	},
}
