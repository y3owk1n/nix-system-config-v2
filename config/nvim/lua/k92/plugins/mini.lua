---@type LazySpec
return {
	{
		"echasnovski/mini.ai",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			n_lines = 500,
		},
	},
	{
		"echasnovski/mini.icons",
		event = "VeryLazy",
		opts = {
			file = {
				[".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
				["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
			},
			filetype = {
				dotenv = { glyph = "", hl = "MiniIconsYellow" },
			},
		},
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},
	{
		"echasnovski/mini.pairs",
		event = { "InsertEnter" },
		opts = {
			modes = { insert = true, command = true, terminal = false },
			-- skip autopair when next character is one of these
			skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
			-- skip autopair when the cursor is inside these treesitter nodes
			skip_ts = { "string" },
			-- skip autopair when next character is closing pair
			-- and there are more closing pairs than opening pairs
			skip_unbalanced = true,
			-- better deal with markdown code blocks
			markdown = true,
		},
	},
	{
		"echasnovski/mini.surround",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			mappings = {
				add = "gsa", -- Add surrounding in Normal and Visual modes
				delete = "gsd", -- Delete surrounding
				find = "gsf", -- Find surrounding (to the right)
				find_left = "gsF", -- Find surrounding (to the left)
				highlight = "gsh", -- Highlight surrounding
				replace = "gsr", -- Replace surrounding
			},
		},
	},
	{
		"echasnovski/mini-git",
		main = "mini.git",
		event = "VeryLazy",
		cmd = { "Git" },
		opts = {},
	},
	{
		"echasnovski/mini.diff",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			view = {
				style = "sign",
				signs = {
					add = "▎",
					change = "▎",
					delete = "",
				},
			},
		},
		keys = {
			{
				"]h",
				function()
					require("mini.diff").goto_hunk("next")
				end,
				mode = "n",
				desc = "Next hunk",
			},
			{
				"[h",
				function()
					require("mini.diff").goto_hunk("prev")
				end,
				mode = "n",
				desc = "Next hunk",
			},
			{
				"<leader>gd",
				function()
					require("mini.diff").toggle_overlay(0)
				end,
				mode = "n",
				desc = "Toggle diff overlay",
			},
		},
	},
	{
		"echasnovski/mini.indentscope",
		event = { "BufReadPre", "BufNewFile" },
		opts = function()
			return {
				symbol = "│",
				draw = {
					animation = require("mini.indentscope").gen_animation.none(),
				},
				options = { indent_at_cursor = true, try_as_border = true },
			}
		end,
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "help", "Trouble", "lazy", "mason" },
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},
	{
		"echasnovski/mini.files",
		event = "VeryLazy",
		opts = {
			windows = {
				preview = true,
				width_focus = 30,
				width_preview = 60,
			},
			mappings = {
				close = "q",
				go_in = "",
				go_in_plus = "l",
				go_out = "",
				go_out_plus = "h",
				mark_goto = "'",
				mark_set = "m",
				reset = "<BS>",
				reveal_cwd = "@",
				show_help = "g?",
				synchronize = "=",
				trim_left = "<",
				trim_right = ">",
			},
			options = { use_as_default_explorer = true },
		},
		init = function()
			local augroup = vim.api.nvim_create_augroup("MiniFilesRename", {})
			vim.api.nvim_create_autocmd("User", {
				group = augroup,
				pattern = "MiniFilesActionRename",
				callback = function(ev)
					local from, to = ev.data.from, ev.data.to
					vim.notify(("Renamed %q → %q"):format(from, to))
				end,
			})
		end,
		keys = {
			{
				"<leader>e",
				function()
					local mini_files = require("mini.files")

					if not mini_files.close() then
						mini_files.open(vim.api.nvim_buf_get_name(0), true)
					end
				end,
				desc = "Explorer (buffer path)",
			},
			{
				"<leader>E",
				function()
					local mini_files = require("mini.files")

					if not mini_files.close() then
						mini_files.open(vim.uv.cwd(), true)
					end
				end,
				desc = "Explorer (cwd)",
			},
		},
	},
	{
		"echasnovski/mini.pick",
		dependencies = { "echasnovski/mini.extra" },
		event = "VeryLazy",
		opts = {
			mappings = { choose_in_vsplit = "<C-v>", choose_in_split = "<C-s>" },
			options = { use_cache = true },

			window = {
				config = function()
					local height = math.floor(0.618 * vim.o.lines)
					local width = math.floor(0.618 * vim.o.columns)
					return {
						anchor = "NW",
						height = height,
						width = width,
						row = math.floor(0.5 * (vim.o.lines - height)),
						col = math.floor(0.5 * (vim.o.columns - width)),
					}
				end,
			},
		},
		config = function(_, opts)
			require("mini.pick").setup(opts)

			vim.ui.select = require("mini.pick").ui_select
		end,
		keys = {
			{
				"<leader><space>",
				function()
					require("mini.pick").builtin.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>sf",
				function()
					require("mini.pick").builtin.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>sh",
				function()
					require("mini.pick").builtin.help()
				end,
				desc = "Help Pages",
			},
			{
				"<leader>sH",
				function()
					require("mini.extra").pickers.hl_groups()
				end,
				desc = "Highlights",
			},
			{
				"<leader>sk",
				function()
					require("mini.extra").pickers.keymaps()
				end,
				desc = "Keymaps",
			},
			{
				"<leader>sg",
				function()
					require("mini.pick").builtin.grep_live()
				end,
				desc = "Grep",
			},
			{
				"<leader>sd",
				function()
					require("mini.extra").pickers.diagnostic()
				end,
				desc = "Diagnostics",
			},
			{
				"<leader>sR",
				function()
					require("mini.pick").builtin.resume()
				end,
				desc = "Resume",
			},
			{
				"<leader>sb",
				function()
					require("mini.pick").builtin.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>so",
				function()
					require("mini.extra").pickers.options()
				end,
				desc = "Options",
			},

			-- LSP
			{
				"grd",
				function()
					require("mini.extra").pickers.lsp({ scope = "definition" })
				end,
				desc = "Goto Definition",
			},
			{
				"grr",
				function()
					require("mini.extra").pickers.lsp({ scope = "references" })
				end,
				desc = "References",
			},
			{
				"gri",
				function()
					require("mini.extra").pickers.lsp({ scope = "implementation" })
				end,
				desc = "Implementation",
			},
			{
				"grt",
				function()
					require("mini.extra").pickers.lsp({ scope = "type_definition" })
				end,
				desc = "Type Definition",
			},
			{
				"gO",
				function()
					require("mini.extra").pickers.lsp({ scope = "document_symbol" })
				end,
				desc = "Document Symbols",
			},
		},
	},
	{
		"echasnovski/mini.notify",
		event = "VeryLazy",
		opts = {
			content = {
				format = function(notif)
					return notif.msg
				end,
			},
			window = {
				config = {
					width = 37, -- same as math.floor(vim.o.columns * 0.2), but hard code the value
				},
				winblend = 0,
			},
		},
		config = function(_, opts)
			require("mini.notify").setup(opts)

			vim.notify = require("mini.notify").make_notify()
		end,
		keys = {
			{
				"<leader>N",
				function()
					require("mini.notify").show_history()
				end,
				desc = "Notification History",
			},
			{
				"<leader>un",
				function()
					require("mini.notify").clear()
				end,
				desc = "Dismiss All",
			},
		},
	},
	{
		"echasnovski/mini.misc",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"<leader>z",
				function()
					require("mini.misc").zoom()
				end,
				desc = "Toggle Zen Mode",
			},
		},
	},
	{
		"echasnovski/mini.starter",
		event = "VimEnter",
		opts = function()
			local starter = require("mini.starter")

			local new_section = function(name, action, section)
				return { name = name, action = action, section = section }
			end

			local items = {
				new_section("Find File", "Pick files", "Files"),
				new_section("Grep Text", "Pick grep_live", "Search"),
				new_section("Restore", ":lua require('persistence').load()", "Session"),
				new_section("Quit", "qa", "Built-in"),
			}

			if not vim.g.disable_mason then
				table.insert(items, new_section("Mason Update", "MasonUpdate", "Tools"))
			end

			if package.loaded.lazy then
				table.insert(items, new_section("Lazy", "Lazy", "Tools"))
			end

			local config = {
				header = [[
██╗  ██╗██╗   ██╗██╗     ███████╗
██║ ██╔╝╚██╗ ██╔╝██║     ██╔════╝
█████╔╝  ╚████╔╝ ██║     █████╗
██╔═██╗   ╚██╔╝  ██║     ██╔══╝
██║  ██╗   ██║   ███████╗███████╗
╚═╝  ╚═╝   ╚═╝   ╚══════╝╚══════╝
]],
				evaluate_single = true,
				items = items,
				content_hooks = {
					starter.gen_hook.adding_bullet("░ ", false),
					starter.gen_hook.aligning("center", "center"),
				},
			}

			return config
		end,
		config = function(_, config)
			-- close Lazy and re-open when starter is ready
			if vim.o.filetype == "lazy" then
				vim.cmd.close()
				vim.api.nvim_create_autocmd("User", {
					pattern = "MiniStarterOpened",
					callback = function()
						require("lazy").show()
					end,
				})
			end

			local starter = require("mini.starter")
			starter.setup(config)

			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				callback = function(ev)
					local stats = require("lazy").stats()
					local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
					starter.config.footer = "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
					-- INFO: based on @echasnovski's recommendation (thanks a lot!!!)
					if vim.bo[ev.buf].filetype == "ministarter" then
						pcall(starter.refresh)
					end
				end,
			})
		end,
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				mini = {
					enabled = true,
					indentscope_color = "flamingo",
				},
			},
		},
	},
}
