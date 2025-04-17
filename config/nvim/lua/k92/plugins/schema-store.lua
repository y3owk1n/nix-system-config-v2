---@type LazySpec
return {
	"b0o/SchemaStore.nvim",
	version = false, -- last release is way too old
	init = function()
		local allowed_clients = { "jsonls", "yamlls" }

		require("k92.utils.lazy").lazy_load_lsp_attach(allowed_clients, "SchemaStore.nvim")
	end,
}
