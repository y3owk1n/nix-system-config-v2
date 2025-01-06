local _table = require("k92.utils.table")

return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "dockerfile" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.servers.dockerls = {}
			opts.servers.docker_compose_language_service = {}
		end,
	},
}
