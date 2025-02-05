---@type LazySpec
return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			local root_pattern = require("lspconfig.util").root_pattern
			opts.servers = opts.servers or {}
			opts.servers.tailwindcss = function() end
			opts.servers.tailwindcss = {
				--- NOTE: Override unique root pattern to just root .git
				--- If not, it wont work for monorepo
				--- Since v4 does not have any config file anymore, looking for the git root might be a better
				--- choice, thought no idea what are the consequences yet...
				root_dir = root_pattern(
					-- "tailwind.config.js",
					-- "tailwind.config.ts",
					-- "postcss.config.js",
					-- "package.json",
					-- "node_modules",
					".git"
				),
			}
		end,
	},
	{
		"y3owk1n/tailwind-autosort.nvim",
		-- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
		ft = {
			"css",
			"sass",
			"scss",
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
		},
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {},
	},
}
