return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"lua",
				"luadoc",
				"luap",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			ensure_installed = { "stylua" },
			servers = {
				lua_ls = {
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false,
							},
							completion = {
								callSnippet = "Replace",
							},
							doc = {
								privateName = { "^_" },
							},
							hint = {
								enable = true,
								setType = false,
								paramType = true,
								paramName = "Disable",
								semicolon = "Disable",
								arrayIndex = "Disable",
							},
						},
					},
				},
			},
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
			},
		},
	},
	{
		"folke/lazydev.nvim",
		ft = "lua",
		cmd = "LazyDev",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				{ path = "snacks.nvim", words = { "Snacks" } },
				{ path = "lazy.nvim", words = { "Lazy" } },
				-- { path = "~/.hammerspoon/Spoons/EmmyLua.spoon/annotations", words = { "hs%." } },
				{ path = "~/.hammerspoon/Spoons/EmmyLua.spoon/annotations", mods = { "hs" } },
			},
		},
		specs = {
			{ "Bilal2453/luvit-meta", lazy = true },
		},
	},
}
