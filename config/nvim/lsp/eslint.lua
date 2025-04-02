local lsp_utils = require("k92.utils.lsp")

local function fix_all(opts)
	opts = opts or {}

	opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

	local clients = vim.lsp.get_clients({ bufnr = opts.bufnr, name = "eslint" })
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

		local git_root = lsp_utils.root_pattern(".git")(fname)

		local package_root = lsp_utils.root_pattern("package.json")(fname)

		if package_root and git_root then
			local package_data = lsp_utils.decode_json_file(package_root .. "/package.json")
			if
				package_data
				and (
					lsp_utils.has_nested_key(package_data, "dependencies", "eslint")
					or lsp_utils.has_nested_key(package_data, "devDependencies", "eslint")
				)
			then
				return cb(git_root)
			end
		end
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
	before_init = function(params, config)
		local new_root_dir = params.rootUri
		if not new_root_dir or new_root_dir == vim.NIL then
			return
		end
		-- The "workspaceFolder" is a VSCode concept. It limits how far the
		-- server will traverse the file system when locating the ESLint config
		-- file (e.g., .eslintrc).
		config.settings.workspaceFolder = {
			uri = new_root_dir,
			name = vim.fn.fnamemodify(new_root_dir, ":t"),
		}

		-- Support flat config
		if
			vim.fn.filereadable(new_root_dir .. "/eslint.config.js") == 1
			or vim.fn.filereadable(new_root_dir .. "/eslint.config.mjs") == 1
			or vim.fn.filereadable(new_root_dir .. "/eslint.config.cjs") == 1
			or vim.fn.filereadable(new_root_dir .. "/eslint.config.ts") == 1
			or vim.fn.filereadable(new_root_dir .. "/eslint.config.mts") == 1
			or vim.fn.filereadable(new_root_dir .. "/eslint.config.cts") == 1
		then
			config.settings.experimental.useFlatConfig = true
		end

		-- Support Yarn2 (PnP) projects
		local pnp_cjs = new_root_dir .. "/.pnp.cjs"
		local pnp_js = new_root_dir .. "/.pnp.js"
		if vim.loop.fs_stat(pnp_cjs) or vim.loop.fs_stat(pnp_js) then
			config.cmd = vim.list_extend({ "yarn", "exec" }, config.cmd)
		end
	end,
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
