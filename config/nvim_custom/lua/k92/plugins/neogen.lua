return {
	"danymat/neogen",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"<leader>cc",
			function()
				require("neogen").generate({})
			end,
			desc = "Neogen Comment",
		},
	},
	opts = { snippet_engine = "luasnip" },
}
