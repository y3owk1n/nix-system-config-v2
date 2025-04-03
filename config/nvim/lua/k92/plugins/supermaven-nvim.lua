return {
	{
		"supermaven-inc/supermaven-nvim",
		event = "VeryLazy",
		opts = {
			keymaps = {
				accept_suggestion = "<C-y>",
			},
			ignore_filetypes = { "bigfile", "snacks_input", "snacks_notif" },
		},
	},
}
