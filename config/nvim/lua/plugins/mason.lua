return {
	"williamboman/mason.nvim",
	opts = function(_, opts)
		vim.list_extend(opts.ensure_installed, {
			"biome",
		})
		opts.ui = {
			border = "rounded",
		}
	end,
}
