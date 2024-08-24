return {
	"echasnovski/mini.files",
	opts = {
		-- Module mappings created only inside explorer.
		-- Use `''` (empty string) to not create one.
		mappings = {
			close = "<esc>",
			go_in = "",
			go_in_plus = "<CR>",
			go_out = "",
			go_out_plus = "<BS>",
			reset = "",
			reveal_cwd = "@",
			show_help = "g?",
			synchronize = "=",
			trim_left = "<",
			trim_right = ">",
			-- go_in_horizontal = "",
			-- go_in_vertical = "",
			go_in_horizontal_plus = "-",
			go_in_vertical_plus = "\\",
		},
		options = {
			-- Whether to use for editing directories
			-- Disabled by default in LazyVim because neo-tree is used for that
			use_as_default_explorer = true,
		},
	},
	keys = {
		{
			"<leader>e",
			function()
				require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
			end,
			desc = "Open mini.files (Directory of Current File)",
		},
		{
			"<leader>E",
			function()
				require("mini.files").open(vim.uv.cwd(), true)
			end,
			desc = "Open mini.files (cwd)",
		},
		{
			"<leader>fe",
			function()
				require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
			end,
			desc = "Open mini.files (Directory of Current File)",
		},
		{
			"<leader>fE",
			function()
				require("mini.files").open(vim.uv.cwd(), true)
			end,
			desc = "Open mini.files (cwd)",
		},
	},
}
