local lsp_utils = require("k92.utils.lsp")

local root_files = { "biome.json", "biome.jsonc" }

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

		local root_string = lsp_utils.root_pattern(unpack(root_files))(fname)

		if root_string then
			return cb(root_string)
		end
	end,
}
