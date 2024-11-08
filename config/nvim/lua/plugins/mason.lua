return {
	"williamboman/mason.nvim",
	---@module 'mason'
	---@type function|MasonSettings
	opts = function(_, opts)
		vim.list_extend(opts.ensure_installed, {
			"biome",
		})
		opts.ui = {
			border = "rounded",
		}
	end,
}
