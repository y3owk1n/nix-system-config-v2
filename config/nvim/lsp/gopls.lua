local lsp_utils = require("k92.utils.lsp")

local mod_cache = nil

---@type vim.lsp.Config
return {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	---@param bufnr integer
	---@param cb fun(root_dir?:string)
	root_dir = function(bufnr, cb)
		local fname = vim.api.nvim_buf_get_name(bufnr)

		if not mod_cache then
			lsp_utils.run_async_job({ "go", "env", "GOMODCACHE" }, function(result)
				if result and result[1] then
					mod_cache = vim.trim(result[1])
				else
					mod_cache = vim.fn.system("go env GOMODCACHE")
				end
			end)
		end
		if mod_cache and fname:sub(1, #mod_cache) == mod_cache then
			local clients = vim.lsp.get_clients({ name = "gopls" })

			if #clients > 0 then
				return cb(clients[#clients].config.root_dir)
			end
		end
		return cb(lsp_utils.root_pattern("go.work", "go.mod", ".git")(fname))
	end,
	settings = {
		gopls = {
			gofumpt = true,
			codelenses = {
				gc_details = false,
				generate = true,
				regenerate_cgo = true,
				run_govulncheck = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
				vendor = true,
			},
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
			analyses = {
				nilness = true,
				unusedparams = true,
				unusedwrite = true,
				useany = true,
			},
			usePlaceholders = true,
			completeUnimported = true,
			staticcheck = true,
			directoryFilters = {
				"-.git",
				"-.vscode",
				"-.idea",
				"-.vscode-test",
				"-node_modules",
			},
			semanticTokens = true,
		},
	},
}
