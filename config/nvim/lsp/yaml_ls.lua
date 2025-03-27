local schemastore_status_ok, schemastore = pcall(require, "schemastore")
if not schemastore_status_ok then
	return
end

---@type vim.lsp.Config
return {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
	root_markers = {
		".git",
	},
	capabilities = {
		textDocument = {
			foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			},
		},
	},
	settings = {
		schemas = schemastore.yaml.schemas(),
		-- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
		redhat = { telemetry = { enabled = false } },
		yaml = {
			keyOrdering = false,
			format = {
				enable = true,
			},
			validate = true,
			schemaStore = {
				-- Must disable built-in schemaStore support to use
				-- schemas from SchemaStore.nvim plugin
				enable = false,
				-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
				url = "",
			},
		},
	},
}
