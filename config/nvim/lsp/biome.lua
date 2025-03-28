local lsp_utils = require("k92.utils.lsp")

---@type vim.lsp.Config
return {
	cmd = { "biome", "lsp-proxy" },
	filetypes = {
		"astro",
		"css",
		"graphql",
		"javascript",
		"javascriptreact",
		"json",
		"jsonc",
		"svelte",
		"typescript",
		"typescript.tsx",
		"typescriptreact",
		"vue",
	},
	---@param bufnr integer
	---@param cb fun(root_dir?:string)
	root_dir = function(bufnr, cb)
		local fname = vim.api.nvim_buf_get_name(bufnr)

		local root_files = { "biome.json", "biome.jsonc" }
		root_files = lsp_utils.insert_package_json(root_files, "biome", fname)
		return cb(vim.fs.dirname(vim.fs.find(root_files, { path = fname, upward = true })[1]))
	end,
}
