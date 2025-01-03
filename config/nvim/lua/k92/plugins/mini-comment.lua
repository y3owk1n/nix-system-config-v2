return {
	"echasnovski/mini.comment",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
	specs = {
		{
			"catppuccin",
			optional = true,
			---@type CatppuccinOptions
			opts = { integrations = {
				mini = {
					enabled = true,
				},
			} },
		},
	},
	opts = {
		custom_commentstring = function()
			return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
		end,
	},
}
