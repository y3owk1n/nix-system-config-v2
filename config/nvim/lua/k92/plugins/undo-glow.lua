---@type LazySpec
return {
	{
		"y3owk1n/undo-glow.nvim",
		-- dir = "~/Dev/undo-glow.nvim", -- Your path
		event = { "VeryLazy" },
		---@module 'undo-glow'
		---@type UndoGlow.Config
		opts = {
			animation = {
				enabled = true,
				duration = 500,
			},
			highlights = {
				undo = {
					hl_color = { bg = "#48384B" },
				},
				redo = {
					hl_color = { bg = "#3B474A" },
				},
				yank = {
					hl_color = { bg = "#5A513C" },
				},
				search = {
					hl_color = { bg = "#6D4B5E" },
				},
				comment = {
					hl_color = { bg = "#6D5640" },
				},
				-- search_prev = {
				-- 	hl_color = { bg = "#3E4C63" },
				-- },
			},
		},
		keys = {
			{
				"u",
				function()
					require("undo-glow").undo()
				end,
				mode = "n",
				desc = "Undo with highlight",
				noremap = true,
			},
			{
				"U",
				function()
					require("undo-glow").redo()
				end,
				mode = "n",
				desc = "Redo with highlight",
				noremap = true,
			},
			{
				"p",
				function()
					require("undo-glow").paste_below()
				end,
				mode = "n",
				desc = "Paste below with highlight",
				noremap = true,
			},
			{
				"P",
				function()
					require("undo-glow").paste_above()
				end,
				mode = "n",
				desc = "Paste above with highlight",
				noremap = true,
			},
			{
				"n",
				function()
					require("undo-glow").search_next()
				end,
				mode = "n",
				desc = "Search next with highlight",
				noremap = true,
			},
			{
				"N",
				function()
					require("undo-glow").search_prev()
				end,
				mode = "n",
				desc = "Search prev with highlight",
				noremap = true,
			},
			{
				"*",
				function()
					require("undo-glow").search_star()
				end,
				mode = "n",
				desc = "Search star with highlight",
				noremap = true,
			},
			{
				"gc",
				function()
					require("k92.utils.preserve-cursor").preserve_cursor()

					return require("undo-glow").comment()
				end,
				mode = { "n", "x" },
				desc = "Toggle comment with highlight",
				expr = true,
				noremap = true,
			},
			{
				"gc",
				function()
					require("undo-glow").comment_textobject()
				end,
				mode = "o",
				desc = "Comment textobject with highlight",
				noremap = true,
			},
			{
				"gcc",
				function()
					return require("undo-glow").comment_line()
				end,
				mode = "n",
				desc = "Toggle comment line with highlight",
				expr = true,
				noremap = true,
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("TextYankPost", {
				desc = "Highlight when yanking (copying) text",
				callback = require("undo-glow").yank,
			})
		end,
	},
}
