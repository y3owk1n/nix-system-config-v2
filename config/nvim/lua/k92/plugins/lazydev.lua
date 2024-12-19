return {
	"folke/lazydev.nvim",
	ft = "lua",
	cmd = "LazyDev",
	opts = {
		library = {
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			{ path = "snacks.nvim", words = { "Snacks" } },
			{ path = "lazy.nvim", words = { "Lazy" } },
		},
	},
	specs = {
		{ "Bilal2453/luvit-meta", lazy = true },
	},
}

-- vim: ts=2 sts=2 sw=2 et
