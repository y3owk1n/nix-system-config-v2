---@type LazySpec
return {
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		cmd = "FzfLua",
		dependencies = {
			{ "echasnovski/mini.icons", enabled = vim.g.have_nerd_font },
		},
		opts = function()
			local config = require("fzf-lua.config")

			config.defaults.keymap.fzf["ctrl-d"] = "preview-page-down"
			config.defaults.keymap.fzf["ctrl-u"] = "preview-page-up"
			config.defaults.keymap.builtin["<c-d>"] = "preview-page-down"
			config.defaults.keymap.builtin["<c-u>"] = "preview-page-up"

			-- Trouble
			config.defaults.actions.files["ctrl-t"] = require("trouble.sources.fzf").actions.open

			---@type fzf.Opts
			return {
				fzf_colors = true,
				fzf_opts = {
					["--no-scrollbar"] = true,
				},
				defaults = {
					formatter = "path.filename_first",
				},
				files = {
					cwd_prompt = false,
				},
				winopts = {
					preview = {
						default = "bat_native",
					},
				},
			}
		end,
		---@param opts fzf.Opts
		config = function(_, opts)
			require("fzf-lua").setup(opts)

			local fzf = require("fzf-lua")
			vim.keymap.set("n", "<leader>sh", fzf.helptags, { desc = "Search help" })
			vim.keymap.set("n", "<leader>sk", fzf.keymaps, { desc = "Search keymaps" })
			vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "Search files" })
			vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "Search current word" })
			vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Search by grep" })
			vim.keymap.set("n", "<leader>sd", fzf.diagnostics_document, { desc = "Search diagnostics document" })
			vim.keymap.set("n", "<leader>sD", fzf.diagnostics_workspace, { desc = "Search diagnostics workspace" })
			vim.keymap.set("n", "<leader>sR", fzf.resume, { desc = "Resume search" })
			vim.keymap.set("n", "<leader>sb", fzf.buffers, { desc = "Search buffers" })
			vim.keymap.set("n", "<leader><leader>", fzf.files, { desc = "Search files" })
		end,
	},
	{
		"catppuccin/nvim",
		opts = {
			integrations = {
				fzf = true,
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			additional_keymaps = {
				["lsp_definitions"] = function(map)
					map("gd", function()
						require("fzf-lua").lsp_definitions({
							jump_to_single_result = true,
							ignore_current_line = true,
						})
					end, "Goto definition")
				end,
				["lsp_references"] = function(map)
					map("gr", function()
						require("fzf-lua").lsp_references({
							jump_to_single_result = true,
							ignore_current_line = true,
						})
					end, "Goto references")
				end,
				["lsp_implementations"] = function(map)
					map("gi", function()
						require("fzf-lua").lsp_implementations({
							jump_to_single_result = true,
							ignore_current_line = true,
						})
					end, "Goto implementation")
				end,
				["lsp_typedefs"] = function(map)
					map("gt", function()
						require("fzf-lua").lsp_typedefs({
							jump_to_single_result = true,
							ignore_current_line = true,
						})
					end, "Goto Type Definition")
				end,
				["lsp_document_symbols"] = function(map)
					map("<leader>ss", require("fzf-lua").lsp_document_symbols, "Search for document symbols")
				end,
				["lsp_workspace_symbols"] = function(map)
					map("<leader>sS", require("fzf-lua").lsp_workspace_symbols, "Search for workspace symbols")
				end,
				["lsp_code_actions"] = function(map)
					map("<leader>ca", require("fzf-lua").lsp_code_actions, "Code actions", { "n", "x" })
				end,
			},
		},
	},
}
