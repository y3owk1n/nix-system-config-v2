return {
	"laytan/cloak.nvim",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	opts = {
		enabled = true,
		cloak_character = "*",
		highlight_group = "Comment",
		cloak_telescope = true,
		patterns = {
			{
				file_pattern = {
					".env*",
					"wrangler.toml",
					".dev.vars",
				},
				cloak_pattern = "=.+",
			},
		},
	},
}

-- vim: ts=2 sts=2 sw=2 et
