---@type LazySpec
return {
	"folke/lazydev.nvim",
	ft = "lua",
	cmd = "LazyDev",
	opts = {
		library = {
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			{ path = "snacks.nvim", words = { "Snacks" } },
			{ path = "lazy.nvim", words = { "Lazy" } },
			-- { path = "~/.hammerspoon/Spoons/EmmyLua.spoon/annotations", words = { "hs%." } },
			{ path = "~/.hammerspoon/Spoons/EmmyLua.spoon/annotations", mods = { "hs" } },
		},
	},
	specs = {
		{ "Bilal2453/luvit-meta", lazy = true },
	},
}
