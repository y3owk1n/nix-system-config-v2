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

-- vim: ts=2 sts=2 sw=2 et
