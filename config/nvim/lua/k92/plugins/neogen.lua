return {
	"danymat/neogen",
	event = { "BufReadPre", "BufNewFile" },
	cmd = "Neogen",
	keys = {
		{
			"<leader>cn",
			function()
				require("neogen").generate()
			end,
			desc = "Generate Annotations (Neogen)",
		},
	},
	---@type neogen.Configuration
	---@diagnostic disable-next-line: missing-fields
	opts = {
		snippet_engine = "nvim",
	},
}
