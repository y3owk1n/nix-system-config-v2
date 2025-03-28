local lsp_utils = require("k92.utils.lsp")

local function fix_all(opts)
	opts = opts or {}

	opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

	local clients = vim.lsp.get_clients({ bufnr = opts.bufnr, name = "eslint_ls" })
	local eslint_lsp_client = clients[1]

	if eslint_lsp_client == nil then
		return
	end

	local request
	if opts.sync then
		request = function(bufnr, method, params)
			eslint_lsp_client:request_sync(method, params, nil, bufnr)
		end
	else
		request = function(bufnr, method, params)
			eslint_lsp_client:request(method, params, nil, bufnr)
		end
	end

	request(0, "workspace/executeCommand", {
		command = "eslint.applyAllFixes",
		arguments = {
			{
				uri = vim.uri_from_bufnr(opts.bufnr),
				version = vim.lsp.util.buf_versions[opts.bufnr],
			},
		},
	})
end

local root_file = {
	".eslintrc",
	".eslintrc.js",
	".eslintrc.cjs",
	".eslintrc.yaml",
	".eslintrc.yml",
	".eslintrc.json",
	"eslint.config.js",
	"eslint.config.mjs",
	"eslint.config.cjs",
	"eslint.config.ts",
	"eslint.config.mts",
	"eslint.config.cts",
}

---@type vim.lsp.Config
return {
	cmd = { "vscode-eslint-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"vue",
		"svelte",
		"astro",
	},
	---@param bufnr integer
	---@param cb fun(root_dir?:string)
	root_dir = function(bufnr, cb)
		local fname = vim.api.nvim_buf_get_name(bufnr)

		root_file = lsp_utils.insert_package_json(root_file, "eslintConfig", fname)

		return cb(lsp_utils.root_pattern(unpack(root_file))(fname))
	end,
	-- Refer to https://github.com/Microsoft/vscode-eslint#settings-options for documentation.
	settings = {
		validate = "on",
		packageManager = nil,
		useESLintClass = false,
		experimental = {
			useFlatConfig = false,
		},
		codeActionOnSave = {
			enable = false,
			mode = "all",
		},
		format = false,
		quiet = false,
		onIgnoredFiles = "off",
		rulesCustomizations = {},
		run = "onType",
		problems = {
			shortenToSingleLine = false,
		},
		-- nodePath configures the directory in which the eslint server should start its node_modules resolution.
		-- This path is relative to the workspace folder (root dir) of the server instance.
		nodePath = "",
		-- use the workspace folder location or the file location (if no workspace folder is open) as the working directory
		workingDirectory = { mode = "auto" },
		codeAction = {
			disableRuleComment = {
				enable = true,
				location = "separateLine",
			},
			showDocumentation = {
				enable = true,
			},
		},
	},
	handlers = {
		["eslint/openDoc"] = function(_, result)
			if result then
				vim.ui.open(result.url)
			end
			return {}
		end,
		["eslint/confirmESLintExecution"] = function(_, result)
			if not result then
				return
			end
			return 4 -- approved
		end,
		["eslint/probeFailed"] = function()
			vim.notify("[lspconfig] ESLint probe failed.", vim.log.levels.WARN)
			return {}
		end,
		["eslint/noLibrary"] = function()
			vim.notify("[lspconfig] Unable to find ESLint library.", vim.log.levels.WARN)
			return {}
		end,
	},
	commands = {
		["EslintFixAll"] = function()
			fix_all({ sync = true, bufnr = 0 })
		end,
	},
}
