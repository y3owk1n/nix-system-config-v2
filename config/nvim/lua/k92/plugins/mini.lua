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
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				mini = {
					enabled = true,
				},
			},
		},
	},
}
