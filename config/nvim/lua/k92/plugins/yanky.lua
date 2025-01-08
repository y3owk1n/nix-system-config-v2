---@type LazySpec
return {
	"gbprod/yanky.nvim",
	event = { "VeryLazy" },
	opts = {
		highlight = { timer = 150 },
	},
	keys = {
		{ "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
		{
			"p",
			"<Plug>(YankyPutAfter)",
			mode = { "n", "x" },
			desc = "Put Text After Cursor",
		},
		{
			"P",
			"<Plug>(YankyPutBefore)",
			mode = { "n", "x" },
			desc = "Put Text Before Cursor",
		},
	},
}
