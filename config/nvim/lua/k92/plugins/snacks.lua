---@type LazySpec
return {
	--- general snacks
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			bigfile = { enabled = true },
			quickfile = { enabled = true, exclude = { "latex" } },
			statuscolumn = {
				enabled = true,
			},
			input = {
				enabled = true,
			},
			image = {
				enabled = true,
				doc = {
					enabled = false,
				},
			},
		},
		init = function()
			local augroup = require("k92.utils.autocmds").augroup

			vim.api.nvim_create_autocmd("User", {
				group = augroup("snacks_init"),
				pattern = "VeryLazy",
				callback = function()
					-- Setup some globals for debugging (lazy-loaded)
					_G.dd = function(...)
						Snacks.debug.inspect(...)
					end
					_G.bt = function()
						Snacks.debug.backtrace()
					end
					vim.print = _G.dd -- Override print to use snacks for `:=` command

					-- Create some toggle mappings
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					Snacks.toggle.diagnostics():map("<leader>ud")
					Snacks.toggle.line_number():map("<leader>ul")
					Snacks.toggle
						.option("conceallevel", {
							off = 0,
							on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
						})
						:map("<leader>uc")
					Snacks.toggle.inlay_hints():map("<leader>uh")
				end,
			})
		end,
	},
	--- explorer
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			---@class snacks.explorer.Config
			explorer = {},
			---@class snacks.picker.Config
			picker = {
				sources = {
					explorer = {},
				},
			},
		},
		keys = {
			{
				"<leader>e",
				function()
					Snacks.explorer.open()
				end,
				desc = "Explorer",
			},
		},
	},
	--- picker
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			---@class snacks.picker.Config
			picker = {
				enabled = true,
				formatters = {
					file = {
						filename_first = true,
					},
				},
				layout = {
					cycle = false,
				},
				matcher = {
					frecency = true,
				},
			},
		},
		keys = {
			{
				"<leader><space>",
				"<leader>sf",
				remap = true,
				desc = "Find Files",
			},
			{
				"<leader>sa",
				function()
					Snacks.picker.autocmds()
				end,
				desc = "Autocmds",
			},
			{
				"<leader>su",
				function()
					Snacks.picker.undo()
				end,
				desc = "Undo",
			},
			{
				"<leader>sh",
				function()
					Snacks.picker.help()
				end,
				desc = "Help Pages",
			},
			{
				"<leader>sH",
				function()
					Snacks.picker.highlights()
				end,
				desc = "Highlights",
			},
			{
				"<leader>sk",
				function()
					Snacks.picker.keymaps()
				end,
				desc = "Keymaps",
			},
			{
				"<leader>sf",
				function()
					Snacks.picker.files({
						format = "file", -- use `file` format for all sources
						matcher = {
							cwd_bonus = true, -- boost cwd matches
							frecency = true, -- use frecency boosting
							sort_empty = true, -- sort even when the filter is empty
						},
					})
				end,
				desc = "Find Files",
			},
			{
				"<leader>sw",
				function()
					Snacks.picker.grep_word()
				end,
				desc = "Visual selection or word",
				mode = { "n", "x" },
			},
			{
				"<leader>sg",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>sd",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "Diagnostics",
			},
			{
				"<leader>sR",
				function()
					Snacks.picker.resume()
				end,
				desc = "Resume",
			},
			{
				"<leader>sb",
				function()
					Snacks.picker.grep_buffers()
				end,
				desc = "Grep Open Buffers",
			},
			-- LSP
			{
				"gd",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "Goto Definition",
			},
			{
				"gr",
				function()
					Snacks.picker.lsp_references()
				end,
				nowait = true,
				desc = "References",
			},
			{
				"gi",
				function()
					Snacks.picker.lsp_implementations()
				end,
				desc = "Goto Implementation",
			},
			{
				"gy",
				function()
					Snacks.picker.lsp_type_definitions()
				end,
				desc = "Goto Type Definition",
			},
			{
				"<leader>ss",
				function()
					Snacks.picker.lsp_symbols()
				end,
				desc = "LSP Symbols",
			},
		},
	},
	--- indent
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			indent = {
				enabled = true,
				scope = {
					enabled = false, -- enable highlighting the current scope
				},
				chunk = {
					enabled = true,
					only_current = true,
				},
			},
		},
	},
	--- zen mode
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			zen = {
				enabled = true,
				toggles = {
					dim = false,
					git_signs = true,
					mini_diff_signs = true,
					diagnostics = true,
					inlay_hints = true,
				},
				show = {
					statusline = true, -- can only be shown when using the global statusline
				},
			},
		},
		keys = {
			{
				"<leader>z",
				function()
					Snacks.zen()
				end,
				desc = "Toggle Zen Mode",
			},
		},
	},
	--- notifier
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			notifier = {
				enabled = true,
				timeout = 3000,
			},
		},
		keys = {
			{
				"<leader>N",
				function()
					Snacks.notifier.show_history()
				end,
				desc = "Notification History",
			},
			{
				"<leader>un",
				function()
					Snacks.notifier.hide()
				end,
				desc = "Dismiss All Notifications",
			},
		},
	},
	--- rename file
	{
		"folke/snacks.nvim",
		opts = function()
			local augroup = require("k92.utils.autocmds").augroup

			vim.api.nvim_create_autocmd("User", {
				group = augroup("snacks_rename"),
				pattern = "MiniFilesActionRename",
				callback = function(event)
					Snacks.rename.on_rename_file(event.data.from, event.data.to)
				end,
			})
		end,
		keys = {
			{
				"<leader>fr",
				function()
					Snacks.rename.rename_file()
				end,
				desc = "Rename File",
			},
		},
	},
	--- git
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			picker = {
				previewers = {
					git = {
						native = true,
					},
				},
			},
			lazygit = {
				configure = false,
				config = {
					os = { editPreset = "nvim-remote" },
				},
			},
		},
		keys = {
			{
				"<leader>gB",
				function()
					Snacks.gitbrowse()
				end,
				desc = "Git Browse",
				mode = { "n", "v" },
			},
			{
				"<leader>gb",
				function()
					Snacks.git.blame_line()
				end,
				desc = "Git Blame Line",
			},
			{
				"<leader>gf",
				function()
					Snacks.lazygit.log_file()
				end,
				desc = "Lazygit Current File History",
			},
			{
				"<leader>gg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},
			{
				"<leader>gl",
				function()
					Snacks.lazygit.log()
				end,
				desc = "Lazygit Log (cwd)",
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status()
				end,
				desc = "Git Status",
			},
		},
	},
	--- dashboard
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			dashboard = {
				enabled = true,
				preset = {
					keys = {
						{
							icon = " ",
							key = "f",
							desc = "Find File",
							action = ":lua Snacks.dashboard.pick('files')",
						},
						{
							icon = " ",
							key = "r",
							desc = "Recent Files",
							action = ":lua Snacks.dashboard.pick('oldfiles')",
						},
						{
							icon = " ",
							key = "g",
							desc = "Find Text",
							action = ":lua Snacks.dashboard.pick('live_grep')",
						},
						{
							icon = " ",
							key = "c",
							desc = "Config",
							action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
						},
						{
							icon = " ",
							key = "s",
							desc = "Restore Session",
							section = "session",
						},
						{
							icon = "󰛦 ",
							key = "m",
							desc = "Mason",
							action = ":Mason",
						},
						{
							icon = "󰒲 ",
							key = "z",
							desc = "Lazy",
							action = ":Lazy",
							enabled = package.loaded.lazy,
						},
						{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
					},
					header = [[
██╗  ██╗██╗   ██╗██╗     ███████╗
██║ ██╔╝╚██╗ ██╔╝██║     ██╔════╝
█████╔╝  ╚████╔╝ ██║     █████╗
██╔═██╗   ╚██╔╝  ██║     ██╔══╝
██║  ██╗   ██║   ███████╗███████╗
╚═╝  ╚═╝   ╚═╝   ╚══════╝╚══════╝
]],
				},
			},
		},
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				snacks = {
					enabled = true,
					indent_scope_color = "flamingo",
				},
			},
		},
	},
}
