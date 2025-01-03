---@type LazySpec
return {
	{
		"echasnovski/mini.comment",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
		opts = {
			custom_commentstring = function()
				return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
			end,
		},
	},
	{
		"catppuccin/nvim",
		opts = {
			integrations = {
				mini = {
					enabled = true,
				},
			},
		},
	},
}
