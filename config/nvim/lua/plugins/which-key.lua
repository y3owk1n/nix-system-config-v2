return {
	"folke/which-key.nvim",
	keys = {
		{ "<c-w><space>", false },
	},
	opts = {
		defaults = {},
		spec = {
			{
				mode = { "n", "v" },
				{ "<leader><tab>", hidden = true },
				{
					"<leader>b",
					hidden = true,
				},
				{ "<leader>t", group = "terminal" },
				-- { "<leader>tz", group = "zellij" },
			},
		},
	},
}
