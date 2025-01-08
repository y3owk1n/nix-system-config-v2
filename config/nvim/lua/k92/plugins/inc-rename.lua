---@type LazySpec
return {
	{
		"smjonas/inc-rename.nvim",
		event = { "VeryLazy" },
		cmd = "IncRename",
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			additional_keymaps = {
				["inc-rename"] = function()
					vim.keymap.set("n", "<leader>cr", function()
						return ":IncRename " .. vim.fn.expand("<cword>")
					end, { expr = true, desc = "Rename word" })
				end,
			},
		},
	},
}
