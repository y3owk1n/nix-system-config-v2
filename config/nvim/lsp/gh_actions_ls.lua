---@type vim.lsp.Config
return {
	cmd = { "gh-actions-language-server", "--stdio" },
	filetypes = { "yaml" }, -- the `root_markers` prevent attaching to every yaml file
	root_markers = {
		".github/workflows",
		".forgejo/workflows",
		".gitea/workflows",
	},
	init_options = {
		sessionToken = "",
	},
	workspace_required = true,
	capabilities = {
		workspace = {
			didChangeWorkspaceFolders = {
				dynamicRegistration = true,
			},
		},
	},
}
