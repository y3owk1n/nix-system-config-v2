return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	event = "VeryLazy",
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for Neovim
		{
			"williamboman/mason.nvim",
			cmd = "Mason",
			keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
			build = ":MasonUpdate",
			config = true,
			opts = { ui = { border = "rounded" } },
		}, -- NOTE: Must be loaded before dependants
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",

		"saghen/blink.cmp",

		-- Useful status updates for LSP.
		-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
		{
			"j-hui/fidget.nvim",
			opts = {
				notification = {
					window = {
						winblend = 0,
					},
				},
			},
		},
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup(
				"k92-lsp-attach",
				{ clear = true }
			),
			callback = function(event)
				-- NOTE: Remember that Lua is a real programming language, and as such it is possible
				-- to define small helper and utility functions so you don't have to repeat yourself.
				--
				-- In this case, we create a function that lets us more easily define mappings specific
				-- for LSP related items. It sets the mode, buffer and description for us each time.
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, {
						buffer = event.buf,
						silent = true,
						desc = "LSP: " .. desc,
					})
				end

				local fzf = require("fzf-lua")

				map("<leader>cl", "<cmd>LspInfo<cr>", "Lsp Info")

				-- Jump to the definition of the word under your cursor.
				--  This is where a variable was first declared, or where a function is defined, etc.
				--  To jump back, press <C-t>.
				map("gd", vim.lsp.buf.definition, "Goto definition")
				-- map('gd', fzf.lsp_definitions, 'Goto definition')

				-- Find references for the word under your cursor.
				map("gr", fzf.lsp_references, "Goto references")

				-- Jump to the implementation of the word under your cursor.
				--  Useful when your language has ways of declaring types without an actual implementation.
				map("gi", fzf.lsp_implementations, "Goto implementation")

				map("gt", fzf.lsp_typedefs, "Goto Type Definition")
				-- map('gt', vim.lsp.buf.type_definition, 'Goto Type Definition')

				-- Fuzzy find all the symbols in your current document.
				--  Symbols are things like variables, functions, types, etc.
				map(
					"<leader>ss",
					fzf.lsp_document_symbols,
					"Search for document symbols"
				)

				-- Fuzzy find all the symbols in your current workspace.
				--  Similar to document symbols, except searches over your entire project.
				map(
					"<leader>sS",
					fzf.lsp_workspace_symbols,
					"Search for workspace symbols"
				)

				-- Rename the variable under your cursor.
				--  Most Language Servers support renaming across files, etc.
				vim.keymap.set("n", "<leader>cr", function()
					return ":IncRename " .. vim.fn.expand("<cword>")
				end, { expr = true, desc = "Rename word" })

				-- Execute a code action, usually your cursor needs to be on top of an error
				-- or a suggestion from your LSP for this to activate.
				map(
					"<leader>ca",
					vim.lsp.buf.code_action,
					"Code actions",
					{ "n", "x" }
				)

				-- WARN: This is not Goto Definition, this is Goto Declaration.
				--  For example, in C this would take you to the header.
				map("gD", vim.lsp.buf.declaration, "Goto declaration")

				map("K", vim.lsp.buf.hover, "Hover")
				map("gK", vim.lsp.buf.signature_help, "Signature help")

				-- The following two autocommands are used to highlight references of the
				-- word under your cursor when your cursor rests there for a little while.
				--    See `:help CursorHold` for information about when this is executed
				--
				-- When you move your cursor, the highlights will be cleared (the second autocommand).
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if
					client
					and client.supports_method(
						vim.lsp.protocol.Methods.textDocument_documentHighlight
					)
				then
					local highlight_augroup = vim.api.nvim_create_augroup(
						"k92-lsp-highlight",
						{ clear = false }
					)
					vim.api.nvim_create_autocmd(
						{ "CursorHold", "CursorHoldI" },
						{
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						}
					)

					vim.api.nvim_create_autocmd(
						{ "CursorMoved", "CursorMovedI" },
						{
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						}
					)

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup(
							"k92-lsp-detach",
							{ clear = true }
						),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({
								group = "k92-lsp-highlight",
								buffer = event2.buf,
							})
						end,
					})
				end

				if
					client
					and client.name == "gopls"
					and not client.server_capabilities.semanticTokensProvider
				then
					local semantic =
						client.config.capabilities.textDocument.semanticTokens
					client.server_capabilities.semanticTokensProvider = {
						full = true,
						legend = {
							tokenModifiers = semantic.tokenModifiers,
							tokenTypes = semantic.tokenTypes,
						},
						range = true,
					}
				end
			end,
		})

		-- Change diagnostic symbols in the sign column (gutter)
		if vim.g.have_nerd_font then
			local signs =
				{ ERROR = " ", WARN = " ", INFO = " ", HINT = " " }
			local diagnostic_signs = {}
			for type, icon in pairs(signs) do
				diagnostic_signs[vim.diagnostic.severity[type]] = icon
			end
			vim.diagnostic.config({ signs = { text = diagnostic_signs } })
		end

		vim.diagnostic.config({
			virtual_text = false,
			float = {
				border = "rounded",
			},
		})

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend(
			"force",
			capabilities,
			require("blink.cmp").get_lsp_capabilities()
		)

		local servers = {
			dockerls = {},
			docker_compose_language_service = {},

			marksman = {},

			nil_ls = {},

			prismals = {},

			tailwindcss = {
				-- exclude a filetype from the default_config
				filetypes_exclude = { "markdown" },
				-- add additional filetypes to the default_config
				filetypes_include = {},
			},

			gopls = {
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
							fieldalignment = true,
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
			},

			jsonls = {
				-- lazy-load schemastore when needed
				on_new_config = function(new_config)
					new_config.settings.json.schemas = new_config.settings.json.schemas
						or {}
					vim.list_extend(
						new_config.settings.json.schemas,
						require("schemastore").json.schemas()
					)
				end,
				settings = {
					json = {
						format = {
							enable = true,
						},
						validate = { enable = true },
					},
				},
			},

			eslint = {
				settings = {
					-- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
					workingDirectories = { mode = "auto" },
					format = false,
				},
			},

			-- ts_ls = {
			-- 	enabled = false,
			-- },

			biome = {},

			vtsls = {
				filetypes = {
					"javascript",
					"javascriptreact",
					"javascript.jsx",
					"typescript",
					"typescriptreact",
					"typescript.tsx",
				},
				settings = {
					complete_function_calls = true,
					vtsls = {
						enableMoveToFileCodeAction = true,
						autoUseWorkspaceTsdk = true,
						experimental = {
							maxInlayHintLength = 30,
							completion = {
								enableServerSideFuzzyMatch = true,
							},
						},
					},
					typescript = {
						updateImportsOnFileMove = { enabled = "always" },
						suggest = {
							completeFunctionCalls = true,
						},
						inlayHints = {
							enumMemberValues = { enabled = true },
							functionLikeReturnTypes = { enabled = true },
							parameterNames = { enabled = "literals" },
							parameterTypes = { enabled = true },
							propertyDeclarationTypes = { enabled = true },
							variableTypes = { enabled = false },
						},
					},
				},
			},

			yamlls = {
				-- Have to add this for yamlls to understand that we support line folding
				capabilities = {
					textDocument = {
						foldingRange = {
							dynamicRegistration = false,
							lineFoldingOnly = true,
						},
					},
				},
				-- lazy-load schemastore when needed
				on_new_config = function(new_config)
					new_config.settings.yaml.schemas = vim.tbl_deep_extend(
						"force",
						new_config.settings.yaml.schemas or {},
						require("schemastore").yaml.schemas()
					)
				end,
				settings = {
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
			},

			lua_ls = {
				-- cmd = { ... },
				-- filetypes = { ... },
				-- capabilities = {},
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
						-- diagnostics = { disable = { 'missing-fields' } },
					},
				},
			},
		}

		require("mason").setup()

		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"stylua", -- Used to format Lua code
			"hadolint",
			"goimports",
			"gofumpt",
			"gomodifytags",
			"impl",
			"delve",
			"markdownlint-cli2",
			"markdown-toc",
			"biome",
			"prettier",
		})
		require("mason-tool-installer").setup({
			ensure_installed = ensure_installed,
		})

		require("mason-lspconfig").setup({
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					-- This handles overriding only values explicitly passed
					-- by the server configuration above. Useful when disabling
					-- certain features of an LSP (for example, turning off formatting for ts_ls)
					server.capabilities = vim.tbl_deep_extend(
						"force",
						{},
						capabilities,
						server.capabilities or {}
					)
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})
	end,
}
