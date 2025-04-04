---@type LazySpec
return {
	"danymat/neogen",
	event = { "VeryLazy" },
	cmd = "Neogen",
	keys = {
		{
			"<leader>cga",
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
