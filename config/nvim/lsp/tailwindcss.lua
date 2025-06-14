local lsp_utils = require("k92.utils.lsp")

---@type vim.lsp.Config
return {
	cmd = { "tailwindcss-language-server", "--stdio" },
	-- filetypes copied and adjusted from tailwindcss-intellisense
	filetypes = {
		-- html
		"aspnetcorerazor",
		"astro",
		"astro-markdown",
		"blade",
		"clojure",
		"django-html",
		"htmldjango",
		"edge",
		"eelixir", -- vim ft
		"elixir",
		"ejs",
		"erb",
		"eruby", -- vim ft
		"gohtml",
		"gohtmltmpl",
		"haml",
		"handlebars",
		"hbs",
		"html",
		"htmlangular",
		"html-eex",
		"heex",
		"jade",
		"leaf",
		"liquid",
		"markdown",
		"mdx",
		"mustache",
		"njk",
		"nunjucks",
		"php",
		"razor",
		"slim",
		"twig",
		-- css
		"css",
		"less",
		"postcss",
		"sass",
		"scss",
		"stylus",
		"sugarss",
		-- js
		"javascript",
		"javascriptreact",
		"reason",
		"rescript",
		"typescript",
		"typescriptreact",
		-- mixed
		"vue",
		"svelte",
		"templ",
	},
	settings = {
		tailwindCSS = {
			validate = true,
			lint = {
				cssConflict = "warning",
				invalidApply = "error",
				invalidScreen = "error",
				invalidVariant = "error",
				invalidConfigPath = "error",
				invalidTailwindDirective = "error",
				recommendedVariantOrder = "warning",
			},
			classAttributes = {
				"class",
				"className",
				"class:list",
				"classList",
				"ngClass",
			},
			includeLanguages = {
				eelixir = "html-eex",
				elixir = "phoenix-heex",
				eruby = "erb",
				heex = "phoenix-heex",
				htmlangular = "html",
				templ = "html",
			},
			files = {
				exclude = {
					"**/.git/**",
					"**/node_modules/**",
					"**/.hg/**",
					"**/.svn/**",
					"**/build/**",
					"**/.medusa/**",
				},
			},
			-- NOTE: can temporarily use this for monorepo detection
			-- https://github.com/tailwindlabs/tailwindcss-intellisense/issues/1323#issuecomment-2873168306
			-- experimental = {
			-- 	configFile = "packages/ui/src/globals.css",
			-- },
		},
	},
	before_init = function(_, config)
		if not config.settings then
			config.settings = {}
		end
		if not config.settings.editor then
			config.settings.editor = {}
		end
		if not config.settings.editor.tabSize then
			-- set tab size for hover
			config.settings.editor.tabSize = vim.lsp.util.get_effective_tabstop()
		end
	end,
	workspace_required = true,
	---@param bufnr integer
	---@param cb fun(root_dir?:string)
	root_dir = function(bufnr, cb)
		local fname = vim.api.nvim_buf_get_name(bufnr)

		local workspace_root = lsp_utils.root_pattern("pnpm-workspace.yaml")(fname)

		local package_root = lsp_utils.root_pattern("package.json")(fname)

		if package_root then
			local package_data = lsp_utils.decode_json_file(package_root .. "/package.json")
			if
				package_data
				and (
					lsp_utils.has_nested_key(package_data, "dependencies", "tailwindcss")
					or lsp_utils.has_nested_key(package_data, "devDependencies", "tailwindcss")
				)
			then
				if workspace_root then
					cb(workspace_root)
				else
					cb(package_root)
				end
			end
		end
	end,
}
