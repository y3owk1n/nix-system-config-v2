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

		local git_root = lsp_utils.root_pattern(".git")(fname)

		if git_root then
			local package_data = lsp_utils.decode_json_file(git_root .. "/package.json")
			if
				package_data
				and (
					lsp_utils.has_nested_key(package_data, "dependencies", "@biomejs/biome")
					or lsp_utils.has_nested_key(package_data, "devDependencies", "@biomejs/biome")
				)
			then
				return cb(git_root)
			end
		end
	end,
}
