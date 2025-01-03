---@type LazySpec
return {
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"saghen/blink.cmp",
			"j-hui/fidget.nvim",
		},
		---@class PluginLspOpts
		opts = {
			-- specify the border for ui
			border = "rounded",
			-- add any global capabilities here
			capabilities = {
				workspace = {
					fileOperations = {
						didRename = true,
						willRename = true,
					},
				},
			},
			-- add any other sources that needed to be installed by mason tools
			ensure_installed = {},
			-- LSP Server Settings
			servers = {},
			-- table of functions that receive a client callback
			additional_setup = {},
		},
		---@param opts PluginLspOpts
		config = function(_, opts)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("k92-lsp-attach", { clear = true }),
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
					-- map("gd", vim.lsp.buf.definition, "Goto definition")
					map("gd", function()
						fzf.lsp_definitions({
							jump_to_single_result = true,
							ignore_current_line = true,
						})
					end, "Goto definition")

					-- Find references for the word under your cursor.
					map("gr", function()
						fzf.lsp_references({
							jump_to_single_result = true,
							ignore_current_line = true,
						})
					end, "Goto references")

					-- Jump to the implementation of the word under your cursor.
					--  Useful when your language has ways of declaring types without an actual implementation.
					map("gi", function()
						fzf.lsp_implementations({
							jump_to_single_result = true,
							ignore_current_line = true,
						})
					end, "Goto implementation")

					map("gt", function()
						fzf.lsp_typedefs({
							jump_to_single_result = true,
							ignore_current_line = true,
						})
					end, "Goto Type Definition")
					-- map('gt', vim.lsp.buf.type_definition, 'Goto Type Definition')

					-- Fuzzy find all the symbols in your current document.
					--  Symbols are things like variables, functions, types, etc.
					map("<leader>ss", fzf.lsp_document_symbols, "Search for document symbols")

					-- Fuzzy find all the symbols in your current workspace.
					--  Similar to document symbols, except searches over your entire project.
					map("<leader>sS", fzf.lsp_workspace_symbols, "Search for workspace symbols")

					-- Rename the variable under your cursor.
					--  Most Language Servers support renaming across files, etc.
					vim.keymap.set("n", "<leader>cr", function()
						return ":IncRename " .. vim.fn.expand("<cword>")
					end, { expr = true, desc = "Rename word" })

					-- Execute a code action, usually your cursor needs to be on top of an error
					-- or a suggestion from your LSP for this to activate.
					map("<leader>ca", fzf.lsp_code_actions, "Code actions", { "n", "x" })
					-- map("<leader>ca", vim.lsp.buf.code_action, "Code actions", { "n", "x" })

					-- WARN: This is not Goto Definition, this is Goto Declaration.
					--  For example, in C this would take you to the header.
					map("gD", vim.lsp.buf.declaration, "Goto declaration")

					map("K", function()
						vim.lsp.buf.hover({ border = opts.border or "rounded" })
					end, "Hover")
					map("gK", function()
						vim.lsp.buf.signature_help({ border = opts.border or "rounded" })
					end, "Signature help")

					-- The following two autocommands are used to highlight references of the
					-- word under your cursor when your cursor rests there for a little while.
					--    See `:help CursorHold` for information about when this is executed
					--
					-- When you move your cursor, the highlights will be cleared (the second autocommand).
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					local has_support_document_highlight

					-- TODO: Can remove this on 0.11
					-- 0.11 -> client:supports_method
					-- 0.10 -> client.supports_method
					if vim.fn.has("nvim-0.11") == 1 then
						has_support_document_highlight = client
							and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight)
					else
						has_support_document_highlight = client
							and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight)
					end

					if has_support_document_highlight then
						local highlight_augroup = vim.api.nvim_create_augroup("k92-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("k92-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({
									group = "k92-lsp-highlight",
									buffer = event2.buf,
								})
							end,
						})
					end

					for _, func in pairs(opts.additional_setup) do
						func(client)
					end
				end,
			})

			-- Update diagnostics
			vim.diagnostic.config({
				underline = true,
				update_in_insert = false,
				virtual_text = {
					severity = { min = vim.diagnostic.severity.W },
					spacing = 4,
					source = "if_many",
					prefix = "●",
					-- this will set set the prefix to a function that returns the diagnostics icon based on the severity
					-- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
					-- prefix = "icons",
				},
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.INFO] = " ",
						[vim.diagnostic.severity.HINT] = " ",
					},
					numhl = {
						[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
						[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
					},
				},
				float = {
					source = true,
					border = opts.border or "rounded",
					severity_sort = true,
				},
			})

			-- TODO: Can remove this on 0.11
			-- Make border rounded for hover & signatureHelp
			if vim.fn.has("nvim-0.10") == 1 then
				vim.lsp.handlers["textDocument/hover"] =
					vim.lsp.with(vim.lsp.handlers.hover, { border = opts.border or "rounded" })
				vim.lsp.handlers["textDocument/signatureHelp"] =
					vim.lsp.with(vim.lsp.handlers.signature_help, { border = opts.border or "rounded" })
			end

			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				require("blink.cmp").get_lsp_capabilities(),
				opts.capabilities or {}
			)

			local servers = opts.servers or {}

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, opts.ensure_installed or {})

			local _, mason_tool_installer = pcall(require, "mason-tool-installer")

			mason_tool_installer.setup({
				ensure_installed = ensure_installed,
			})

			local _, mason_lspconfig = pcall(require, "mason-lspconfig")

			---@diagnostic disable-next-line: missing-fields
			mason_lspconfig.setup({
				handlers = {
					function(server)
						local server_opts = vim.tbl_deep_extend("force", {
							capabilities = vim.deepcopy(capabilities),
						}, servers[server] or {})

						require("lspconfig")[server].setup(server_opts)
					end,
				},
			})
		end,
	},
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts_extend = { "ensure_installed" },
		config = true,
		opts = { ui = { border = "rounded" } },
	},
	{

		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = {},
		config = true,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = {},
		config = true,
	},
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
}
