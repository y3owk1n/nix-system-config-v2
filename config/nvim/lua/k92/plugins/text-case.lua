return {
	{
		"johmsalas/text-case.nvim",
		event = "VeryLazy",
		opts = {
			prefix = "<leader>cc",
		},
	},
	{
		"folke/which-key.nvim",
		optional = true,
		opts = function(opts)
			table.insert(opts.opts.spec[1], {
				"<leader>cc",
				group = "Textcase",
			})
		end,
	},
}
