return {
	"nvim-pack/nvim-spectre",
	lazy = true,
	build = false,
	cmd = "Spectre",
	opts = { open_cmd = "noswapfile vnew" },
	keys = {
		{
			"<leader>sr",
			function()
				require("spectre").open()
			end,
			desc = "Replace in Files (Spectre)",
		},
	},
}
