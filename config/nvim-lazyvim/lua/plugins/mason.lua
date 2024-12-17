return {
	"williamboman/mason.nvim",
	---@module 'mason'
	---@type function|MasonSettings
	opts = function(_, opts)
		opts.ui = {
			border = "rounded",
		}
	end,
}
