---@type LazySpec
return {
	{
		"folke/trouble.nvim",
		event = { "BufReadPre", "BufNewFile" },
		---@type trouble.Config
		---@diagnostic disable-next-line: missing-fields
		opts = {
			focus = true,
		},
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				lsp_trouble = true,
			},
		},
	},
}
