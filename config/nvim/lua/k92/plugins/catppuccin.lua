return {
	"catppuccin/nvim",
	lazy = false,
	name = "catppuccin",
	priority = 1000,
	---@type CatppuccinOptions
	opts = {},
	config = function(_, opts)
		require("catppuccin").setup(opts)

		vim.cmd("colorscheme catppuccin-macchiato")
	end,
}
