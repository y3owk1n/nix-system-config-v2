local _table = require("k92.utils.table")

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"go",
				"gomod",
				"gowork",
				"gosum",
			},
		},
	},

	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "goimports", "gofumpt" })

			opts.servers = opts.servers or {}
			opts.servers.gopls = {
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

			opts.additional_setup = opts.additional_setup or {}
			opts.additional_setup = {
				go = function(client)
					if client and client.name == "gopls" and not client.server_capabilities.semanticTokensProvider then
						local semantic = client.config.capabilities.textDocument.semanticTokens
						if semantic then
							client.server_capabilities.semanticTokensProvider = {
								full = true,
								legend = {
									tokenModifiers = semantic.tokenModifiers,
									tokenTypes = semantic.tokenTypes,
								},
								range = true,
							}
						end
					end
				end,
			}
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				go = { "goimports", "gofumpt" },
			},
		},
	},
	{
		"echasnovski/mini.icons",
		opts = {
			file = {
				[".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
			},
			filetype = {
				gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
			},
		},
	},
}
