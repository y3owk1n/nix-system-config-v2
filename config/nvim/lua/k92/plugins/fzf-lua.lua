return {
	'ibhagwan/fzf-lua',
	lazy = true,
	event = 'VimEnter',
	cmd = 'FzfLua',
	dependencies = {
		{ 'echasnovski/mini.icons', enabled = vim.g.have_nerd_font },
	},
	opts = function(_, opts)
		local config = require 'fzf-lua.config'
		local actions = require 'fzf-lua.actions'

		-- Quickfix
		config.defaults.keymap.fzf['ctrl-q'] = 'select-all+accept'
		config.defaults.keymap.fzf['ctrl-u'] = 'half-page-up'
		config.defaults.keymap.fzf['ctrl-d'] = 'half-page-down'
		config.defaults.keymap.fzf['ctrl-x'] = 'jump'
		config.defaults.keymap.fzf['ctrl-f'] = 'preview-page-down'
		config.defaults.keymap.fzf['ctrl-b'] = 'preview-page-up'
		config.defaults.keymap.builtin['<c-f>'] = 'preview-page-down'
		config.defaults.keymap.builtin['<c-b>'] = 'preview-page-up'

		-- Trouble
		config.defaults.actions.files['ctrl-t'] =
			require('trouble.sources.fzf').actions.open

		local img_previewer ---@type string[]?
		for _, v in ipairs {
			{ cmd = 'ueberzug', args = {} },
			{ cmd = 'chafa', args = { '{file}', '--format=symbols' } },
			{ cmd = 'viu', args = { '-b' } },
		} do
			if vim.fn.executable(v.cmd) == 1 then
				img_previewer = vim.list_extend({ v.cmd }, v.args)
				break
			end
		end

		return {
			'default-title',
			fzf_colors = true,
			fzf_opts = {
				['--no-scrollbar'] = true,
			},
			defaults = {
				-- formatter = "path.filename_first",
				formatter = 'path.dirname_first',
			},
			previewers = {
				builtin = {
					extensions = {
						['png'] = img_previewer,
						['jpg'] = img_previewer,
						['jpeg'] = img_previewer,
						['gif'] = img_previewer,
						['webp'] = img_previewer,
					},
					ueberzug_scaler = 'fit_contain',
				},
			},
			winopts = {
				width = 0.8,
				height = 0.8,
				row = 0.5,
				col = 0.5,
				preview = {
					scrollchars = { '┃', '' },
				},
			},
			files = {
				cwd_prompt = false,
				actions = {
					['alt-i'] = { actions.toggle_ignore },
					['alt-h'] = { actions.toggle_hidden },
				},
			},
			grep = {
				actions = {
					['alt-i'] = { actions.toggle_ignore },
					['alt-h'] = { actions.toggle_hidden },
				},
			},
			lsp = {
				symbols = {
					symbol_hl = function(s)
						return 'TroubleIcon' .. s
					end,
					symbol_fmt = function(s)
						return s:lower() .. '\t'
					end,
					child_prefix = false,
				},
				code_actions = {
					previewer = vim.fn.executable 'delta' == 1
							and 'codeaction_native'
						or nil,
				},
			},
		}
	end,
	config = function(_, opts)
		require('fzf-lua').setup(opts)

		local fzf = require 'fzf-lua'
		vim.keymap.set(
			'n',
			'<leader>sh',
			fzf.helptags,
			{ desc = '[S]earch [H]elp' }
		)
		vim.keymap.set(
			'n',
			'<leader>sk',
			fzf.keymaps,
			{ desc = '[S]earch [K]eymaps' }
		)
		vim.keymap.set(
			'n',
			'<leader>sf',
			fzf.files,
			{ desc = '[S]earch [F]iles' }
		)
		vim.keymap.set(
			'n',
			'<leader>ss',
			fzf.builtin,
			{ desc = '[S]earch [S]elect Fzf' }
		)
		vim.keymap.set(
			'n',
			'<leader>sw',
			fzf.grep_cword,
			{ desc = '[S]earch current [W]ord' }
		)
		vim.keymap.set(
			'n',
			'<leader>sg',
			fzf.live_grep,
			{ desc = '[S]earch by [G]rep' }
		)
		vim.keymap.set(
			'n',
			'<leader>sd',
			fzf.diagnostics_document,
			{ desc = '[S]earch [D]iagnostics Document' }
		)
		vim.keymap.set(
			'n',
			'<leader>sr',
			fzf.resume,
			{ desc = '[S]earch [R]esume' }
		)
		vim.keymap.set(
			'n',
			'<leader>s.',
			fzf.oldfiles,
			{ desc = '[S]earch Recent Files ("." for repeat)' }
		)
		vim.keymap.set(
			'n',
			'<leader>sb',
			fzf.buffers,
			{ desc = '[S]earch existing [B]uffers' }
		)

		-- It's also possible to pass additional configuration options.
		--  See `:help telescope.builtin.live_grep()` for information about particular keys
		vim.keymap.set(
			'n',
			'<leader><leader>',
			fzf.files,
			{ desc = '[S]earch [/] in Open Files' }
		)

		-- Shortcut for searching your Neovim configuration files
		vim.keymap.set('n', '<leader>sn', function()
			fzf.find_files { cwd = vim.fn.stdpath 'config' }
		end, { desc = '[S]earch [N]eovim files' })
	end,
}
