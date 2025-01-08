---@type LazySpec
return {
	"laytan/cloak.nvim",
	event = { "VeryLazy" },
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
