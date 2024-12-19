return {
	"ibhagwan/fzf-lua",
	event = "VeryLazy",
	cmd = "FzfLua",
	dependencies = {
		{ "echasnovski/mini.icons", enabled = vim.g.have_nerd_font },
	},
	opts = function()
		local config = require("fzf-lua.config")
		local actions = require("fzf-lua.actions")

		-- Quickfix
		config.defaults.keymap.fzf["ctrl-q"] = "select-all+accept"
		config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
		config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
		config.defaults.keymap.fzf["ctrl-x"] = "jump"
		config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
		config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
		config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
		config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"

		-- Trouble
		config.defaults.actions.files["ctrl-t"] =
			require("trouble.sources.fzf").actions.open

		---@type fzf.Opts
		return {
			"default-title",
			fzf_colors = true,
			fzf_opts = {
				["--no-scrollbar"] = true,
			},
			defaults = {
				formatter = "path.filename_first",
				-- formatter = 'path.dirname_first',
			},
			winopts = {
				width = 0.8,
				height = 0.8,
				row = 0.5,
				col = 0.5,
				preview = {
					scrollchars = { "┃", "" },
				},
			},
			files = {
				cwd_prompt = false,
				actions = {
					["alt-i"] = { actions.toggle_ignore },
					["alt-h"] = { actions.toggle_hidden },
				},
			},
			grep = {
				actions = {
					["alt-i"] = { actions.toggle_ignore },
					["alt-h"] = { actions.toggle_hidden },
				},
			},
			lsp = {
				symbols = {
					symbol_hl = function(s)
						return "TroubleIcon" .. s
					end,
					symbol_fmt = function(s)
						return s:lower() .. "\t"
					end,
					child_prefix = false,
				},
				code_actions = {
					previewer = vim.fn.executable("delta") == 1
							and "codeaction_native"
						or nil,
				},
			},
		}
	end,
	---@param opts fzf.Opts
	config = function(_, opts)
		require("fzf-lua").setup(opts)

		local fzf = require("fzf-lua")
		vim.keymap.set(
			"n",
			"<leader>sh",
			fzf.helptags,
			{ desc = "Search help" }
		)
		vim.keymap.set(
			"n",
			"<leader>sk",
			fzf.keymaps,
			{ desc = "Search keymaps" }
		)
		vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "Search files" })
		vim.keymap.set(
			"n",
			"<leader>sw",
			fzf.grep_cword,
			{ desc = "Search current word" }
		)
		vim.keymap.set(
			"n",
			"<leader>sg",
			fzf.live_grep,
			{ desc = "Search by grep" }
		)
		vim.keymap.set(
			"n",
			"<leader>sd",
			fzf.diagnostics_document,
			{ desc = "Search diagnostics document" }
		)
		vim.keymap.set(
			"n",
			"<leader>sR",
			fzf.resume,
			{ desc = "Resume search" }
		)
		vim.keymap.set(
			"n",
			"<leader>sb",
			fzf.buffers,
			{ desc = "Search buffers" }
		)
		vim.keymap.set(
			"n",
			"<leader><leader>",
			fzf.files,
			{ desc = "Search files" }
		)
	end,
}
