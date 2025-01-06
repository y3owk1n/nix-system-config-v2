local _table = require("k92.utils.table")

return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "just" })
			vim.filetype.add({
				extension = { just = "just" },
				filename = {
					justfile = "just",
					Justfile = "just",
					[".Justfile"] = "just",
					[".justfile"] = "just",
				},
			})
		end,
	},
}
