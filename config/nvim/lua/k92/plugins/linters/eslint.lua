return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			---@type lspconfig.options
			servers = {
				eslint = {
					settings = {
						-- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
						workingDirectories = { mode = "auto" },
						format = false,
					},
				},
			},
		},
	},
}
