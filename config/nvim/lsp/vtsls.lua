---@type vim.lsp.Config
return {
	cmd = { "vtsls", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
	},
	root_markers = {
		"tsconfig.json",
		"package.json",
		"jsconfig.json",
		".git",
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
	on_attach = function(client, bufnr)
		local lsp = {}
		lsp.map = require("k92.utils.lsp").map
		lsp.execute = require("k92.utils.lsp").execute
		lsp.action = require("k92.utils.lsp").action

		lsp.map(bufnr, "gD", function()
			local params = vim.lsp.util.make_position_params(0, "utf-8")
			lsp.execute({
				command = "typescript.goToSourceDefinition",
				arguments = { params.textDocument.uri, params.position },
				open = true,
			})
		end, "Goto Source Definition")

		lsp.map(bufnr, "gR", function()
			lsp.execute({
				command = "typescript.findAllFileReferences",
				arguments = { vim.uri_from_bufnr(0) },
				open = true,
			})
		end, "File References")

		lsp.map(bufnr, "<leader>co", function()
			local fname = vim.api.nvim_buf_get_name(bufnr)
			lsp.execute({ command = "typescript.organizeImports", arguments = { fname } })
		end, "Organize Imports")

		lsp.map(bufnr, "<leader>cM", lsp.action["source.addMissingImports.ts"], "Add Missing Imports")
		lsp.map(bufnr, "<leader>cu", lsp.action["source.removeUnused.ts"], "Remove Unused Imports")
		lsp.map(bufnr, "<leader>cD", lsp.action["source.fixAll.ts"], "Fix All Diagnostics")

		lsp.map(bufnr, "cV", function()
			lsp.execute({ command = "typescript.selectTypeScriptVersion" })
		end, "Select TS workspace version")

		client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
			---@type string, string, lsp.Range
			local action, uri, range = unpack(command.arguments)

			local function move(newf)
				client:request("workspace/executeCommand", {
					command = command.command,
					arguments = { action, uri, range, newf },
				})
			end

			local fname = vim.uri_to_fname(uri)
			client:request("workspace/executeCommand", {
				command = "typescript.tsserverRequest",
				arguments = {
					"getMoveToRefactoringFileSuggestions",
					{
						file = fname,
						startLine = range.start.line + 1,
						startOffset = range.start.character + 1,
						endLine = range["end"].line + 1,
						endOffset = range["end"].character + 1,
					},
				},
			}, function(_, result)
				---@type string[]
				local files = result.body.files
				table.insert(files, 1, "Enter new path...")
				vim.ui.select(files, {
					prompt = "Select move destination:",
					format_item = function(f)
						return vim.fn.fnamemodify(f, ":~:.")
					end,
				}, function(f)
					if f and f:find("^Enter new path") then
						vim.ui.input({
							prompt = "Enter move destination:",
							default = vim.fn.fnamemodify(fname, ":h") .. "/",
							completion = "file",
						}, function(newf)
							return newf and move(newf)
						end)
					elseif f then
						move(f)
					end
				end)
			end)
		end
	end,
}
