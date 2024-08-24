return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local open_with_trouble = require("trouble.sources.telescope").open

		-- Use this to add more results without clearing the trouble list
		local add_to_trouble = require("trouble.sources.telescope").add

		telescope.setup({
			defaults = {
				path_display = { "truncate " },
				wrap_results = true,
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
				winblend = 0,
				mappings = {
					i = {
						-- do not allow any actions during insert mode
						-- mappings from https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/mappings.lua
						["<LeftMouse>"] = actions.nop,
						["<2-LeftMouse>"] = actions.nop,

						["<C-n>"] = actions.nop,
						["<C-p>"] = actions.nop,

						["<C-c>"] = actions.nop,

						["<Down>"] = actions.nop,
						["<Up>"] = actions.nop,

						-- ["<CR>"] = actions.nop,
						["<C-x>"] = actions.nop,
						["<C-v>"] = actions.nop,
						["<C-t>"] = actions.nop,

						["<C-u>"] = actions.nop,
						["<C-d>"] = actions.nop,
						["<C-f>"] = actions.nop,
						["<C-k>"] = actions.nop,

						["<PageUp>"] = actions.nop,
						["<PageDown>"] = actions.nop,
						["<M-f>"] = actions.nop,
						["<M-k>"] = actions.nop,

						["<Tab>"] = actions.nop,
						["<S-Tab>"] = actions.nop,
						["<C-q>"] = actions.nop,
						["<M-q>"] = actions.nop,
						["<C-l>"] = actions.nop,
						["<C-/>"] = actions.nop,
						["<C-_>"] = actions.nop,
						["<C-w>"] = actions.nop,
						["<C-r><C-w>"] = actions.nop,
						["<C-j>"] = actions.nop,
					},
					n = {
						["<c-a>"] = open_with_trouble,
						["<c-A>"] = add_to_trouble,
						["q"] = actions.close,
						["-"] = actions.select_horizontal,
						["\\"] = actions.select_vertical,
					},
				},
			},
			pickers = {
				diagnostics = {
					theme = "dropdown",
					initial_mode = "normal",
					layout_config = {
						preview_cutoff = 9999,
					},
				},
			},
		})

		telescope.load_extension("fzf")
		telescope.load_extension("notify")
		-- telescope.load_extension("file_browser")
		-- set keymaps
		local builtin = require("telescope.builtin")
		local extensions = require("telescope").extensions
		local keymap = vim.keymap -- for conciseness

		keymap.set(
			"n",
			"<leader><space>",
			builtin.find_files,
			{ desc = "[S]earch [F]iles" }
		)
		keymap.set(
			"n",
			"<leader>sd",
			builtin.diagnostics,
			{ desc = "[S]earch [D]iagnostics" }
		)
		keymap.set(
			"n",
			"<leader>sg",
			builtin.live_grep,
			{ desc = "[S]earch by [G]rep" }
		)
		keymap.set(
			"n",
			"<leader>sw",
			builtin.grep_string,
			{ desc = "[S]earch current [W]ord" }
		)
		keymap.set(
			"n",
			"<leader>sh",
			builtin.help_tags,
			{ desc = "[S]earch [H]elp" }
		)
		keymap.set(
			"n",
			"<leader>sk",
			builtin.keymaps,
			{ desc = "[S]earch [K]eymaps" }
		)
		keymap.set(
			"n",
			"<leader>ss",
			builtin.builtin,
			{ desc = "[S]earch [S]elect Telescope" }
		)
		keymap.set(
			"n",
			"<leader>sx",
			builtin.resume,
			{ desc = "[S]earch Resume" }
		)
		keymap.set("n", "<leader>sc", function()
			builtin.find_files({ cwd = vim.fn.stdpath("config") })
		end, { desc = "[S]earch Neovim [C]onfig" })

		keymap.set("n", "<leader>sn", function()
			extensions.notify.notify()
		end, { desc = "[S]earch [N]notifications" })
	end,
}
