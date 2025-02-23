---@type LazySpec
return {
	{
		"y3owk1n/undo-glow.nvim",
		-- dir = "~/Dev/undo-glow.nvim", -- Your path
		event = { "VeryLazy" },
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
		---@param _ any
		---@param opts UndoGlow.Config
		config = function(_, opts)
			local undo_glow = require("undo-glow")

			undo_glow.setup(opts)

			vim.keymap.set("n", "u", undo_glow.undo, { noremap = true, desc = "Undo with highlight" })
			vim.keymap.set("n", "U", undo_glow.redo, { noremap = true, desc = "Redo with highlight" })
			vim.keymap.set("n", "p", undo_glow.paste_below, { noremap = true, desc = "Paste below with highlight" })
			vim.keymap.set("n", "P", undo_glow.paste_above, { noremap = true, desc = "Paste above with highlight" })
			vim.keymap.set("n", "n", undo_glow.search_next, { noremap = true, desc = "Search next with highlight" })
			vim.keymap.set("n", "N", undo_glow.search_prev, { noremap = true, desc = "Search previous with highlight" })
			vim.keymap.set("n", "*", undo_glow.search_star, { noremap = true, desc = "Search * with highlight" })
			vim.keymap.set(
				{ "n", "x" },
				"gc",
				undo_glow.comment,
				{ expr = true, noremap = true, desc = "Toggle comment with highlight" }
			)

			vim.keymap.set(
				"o",
				"gc",
				undo_glow.comment_textobject,
				{ noremap = true, desc = "Comment textobject with highlight" }
			)

			vim.keymap.set(
				"n",
				"gcc",
				undo_glow.comment_line,
				{ expr = true, noremap = true, desc = "Toggle comment line with highlight" }
			)

			vim.api.nvim_create_autocmd("TextYankPost", {
				desc = "Highlight when yanking (copying) text",
				callback = require("undo-glow").yank,
			})
		end,
	},
}
