---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "nix" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.servers.nil_ls = {}
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				nix = { "nixfmt" },
			},
		},
	},
}
