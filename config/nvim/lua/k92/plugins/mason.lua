---@type LazySpec
return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		enabled = not vim.g.disable_mason,
		event = "VeryLazy",
		keys = { { "<leader>im", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts_extend = { "ensure_installed" },
		config = true,
		opts = { ui = { border = "rounded", backdrop = 100 } },
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		enabled = not vim.g.disable_mason,
		cmd = {
			"MasonToolsInstall",
			"MasonToolsInstallSync",
			"MasonToolsUpdate",
			"MasonToolsUpdateSync",
			"MasonToolsClean",
		},
		opts = {},
		config = true,
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				mason = true,
				native_lsp = {
					enabled = true,
					virtual_text = {
						errors = { "italic" },
						hints = { "italic" },
						warnings = { "italic" },
						information = { "italic" },
						ok = { "italic" },
					},
					underlines = {
						errors = { "underline" },
						hints = { "underline" },
						warnings = { "underline" },
						information = { "underline" },
						ok = { "underline" },
					},
					inlay_hints = {
						background = true,
					},
				},
			},
		},
	},
}
