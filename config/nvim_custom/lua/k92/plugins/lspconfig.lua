return {
	"neovim/nvim-lspconfig",
	lazy = true,
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	dependencies = {
		{
			"williamboman/mason.nvim",
			keys = { { "<leader>lm", "<cmd>Mason<cr>", desc = "Mason" } },
			opts = {
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			},
		},
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		-- {
		-- 	"j-hui/fidget.nvim",
		-- 	opts = {
		-- 		notification = {
		-- 			window = {
		-- 				winblend = 0,
		-- 			},
		-- 		},
		-- 	},
		-- },

		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup(
				"k92-lsp-attach",
				{ clear = true }
			),
			callback = function(event)
				local map = function(keys, func, desc)
					vim.keymap.set(
						"n",
						keys,
						func,
						{ buffer = event.buf, desc = "LSP: " .. desc }
					)
				end

				-- Jump to the definition of the word under your cursor.
				map(
					"gd",
					require("telescope.builtin").lsp_definitions,
					"[G]oto [D]efinition" -- codespell:ignore
				)

				-- Find references for the word under your cursor.
				map(
					"gr",
					require("telescope.builtin").lsp_references,
					"[G]oto [R]eferences"
				)

				-- Jump to the implementation of the word under your cursor.
				--  Useful when your language has ways of declaring types without an actual implementation.
				map(
					"gI",
					require("telescope.builtin").lsp_implementations,
					"[G]oto [I]mplementation"
				)

				-- Jump to the type of the word under your cursor.
				--  Useful when you're not sure what type a variable is and you want to see
				--  the definition of its *type*, not where it was *defined*.
				map(
					"<leader>lbt",
					require("telescope.builtin").lsp_type_definitions,
					"[T]ype [D]efinition" -- codespell:ignore
				)

				-- Fuzzy find all the symbols in your current document.
				--  Symbols are things like variables, functions, types, etc.
				map(
					"<leader>lbd",
					require("telescope.builtin").lsp_document_symbols,
					"[D]ocument [S]symbols" -- codespell:ignore
				)

				-- Fuzzy find all the symbols in your current workspace
				--  Similar to document symbols, except searches over your whole project.
				map(
					"<leader>lbs",
					require("telescope.builtin").lsp_dynamic_workspace_symbols,
					"[W]orkspace [S]symbols" --codespell:ignore
				)

				-- Rename the variable under your cursor
				--  Most Language Servers support renaming across files, etc.
				map("<leader>cr", vim.lsp.buf.rename, "[R]ename")

				-- Execute a code action, usually your cursor needs to be on top of an error
				-- or a suggestion from your LSP for this to activate.
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

				-- Opens a popup that displays documentation about the word under your cursor
				--  See `:help K` for why this keymap
				map("K", vim.lsp.buf.hover, "[H]over Documentation")

				-- WARN: This is not Goto Definition, this is Goto Declaration.
				--  For example, in C this would take you to the header
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

				map(
					"[d",
					vim.diagnostic.goto_prev,
					"Go to previous Diagnostic message"
				)
				map(
					"]d",
					vim.diagnostic.goto_next,
					"Go to next Diagnostic message"
				)

				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if
					client
					and client.server_capabilities.documentHighlightProvider
				then
					vim.api.nvim_create_autocmd(
						{ "CursorHold", "CursorHoldI" },
						{
							buffer = event.buf,
							callback = vim.lsp.buf.document_highlight,
						}
					)

					vim.api.nvim_create_autocmd(
						{ "CursorMoved", "CursorMovedI" },
						{
							buffer = event.buf,
							callback = vim.lsp.buf.clear_references,
						}
					)
				end
			end,
		})

		local signs =
			{ Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend(
			"force",
			capabilities,
			require("cmp_nvim_lsp").default_capabilities()
		)

		local servers = {
			rust_analyzer = {},
			biome = {},
			tailwindcss = {},
			prismals = {},
			marksman = {},
			jsonls = {},
			nil_ls = {},
			yamlls = {
				settings = {
					redhat = { telemetry = { enabled = false } },
					yaml = {
						keyOrdering = false,
						format = {
							enable = true,
						},
						validate = true,
						schemaStore = {
							enable = false,
							url = "",
						},
					},
				},
			},
			tsserver = {
				keys = {
					"<leader>co",
					function()
						vim.lsp.buf.code_action({
							apply = true,
							context = {
								only = { "source.organizeImports.ts" },
								diagnostics = {},
							},
						})
					end,
					desc = "Organize Imports",
				},
				{
					"<leader>cR",
					function()
						vim.lsp.buf.code_action({
							apply = true,
							context = {
								only = { "source.removeUnused.ts" },
								diagnostics = {},
							},
						})
					end,
					desc = "Remove Unused Imports",
				},
				settings = {
					typescript = {
						format = {
							indentSize = vim.o.shiftwidth,
							convertTabsToSpaces = vim.o.expandtab,
							tabSize = vim.o.tabstop,
						},
					},
					javascript = {
						format = {
							indentSize = vim.o.shiftwidth,
							convertTabsToSpaces = vim.o.expandtab,
							tabSize = vim.o.tabstop,
						},
					},
					completions = {
						completeFunctionCalls = true,
					},
				},
			},

			lua_ls = {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							library = {
								vim.env.VIMRUNTIME,
							},
						},
						completion = {
							callSnippet = "Replace",
						},
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			},
		}

		require("mason").setup()

		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"biome",
			"jsonls",
			-- "eslint_d", -- install it on os level to enable restart
			"actionlint",
			"lua_ls",
			"marksman",
			"prismals",
			"nil_ls",
			"tailwindcss",
			"tsserver",
			"yamlls",
			"luacheck",
			"codespell",
			"stylua",
			"prettierd",
			"markdownlint",
			"yamllint",
			"rust_analyzer",
		})
		require("mason-tool-installer").setup({
			ensure_installed = ensure_installed,
		})

		require("mason-lspconfig").setup({
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
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
