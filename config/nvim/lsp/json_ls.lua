local schemastore_status_ok, schemastore = pcall(require, "schemastore")
if not schemastore_status_ok then
	return
end

---@type vim.lsp.Config
return {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
	init_options = {
		provideFormatter = true,
	},
	root_markers = {
		".git",
	},
	settings = {
		json = {
			schemas = schemastore.json.schemas(),
			format = {
				enable = true,
			},
			validate = { enable = true },
		},
	},
}
