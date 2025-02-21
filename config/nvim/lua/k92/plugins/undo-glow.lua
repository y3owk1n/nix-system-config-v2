---@type LazySpec
return {
	{
		-- "y3owk1n/undo-glow.nvim",
		dir = "~/Dev/undo-glow.nvim", -- Your path
		event = { "VeryLazy" },
		---@type UndoGlow.Config
		opts = {
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
				paste_below = {
					hl_color = { bg = "#5A496E" },
				},
				paste_above = {
					hl_color = { bg = "#6D4B5E" },
				},
				search_next = {
					hl_color = { bg = "#6D5640" },
				},
				search_prev = {
					hl_color = { bg = "#3E4C63" },
				},
			},
		},
		---@param _ any
		---@param opts UndoGlow.Config
		config = function(_, opts)
			local undo_glow = require("undo-glow")

			undo_glow.setup(opts)

			vim.keymap.set("n", "u", require("undo-glow").undo, { noremap = true, silent = true })
			vim.keymap.set("n", "U", require("undo-glow").redo, { noremap = true, silent = true })
			vim.keymap.set("n", "p", require("undo-glow").paste_below, { noremap = true, silent = true })
			vim.keymap.set("n", "P", require("undo-glow").paste_above, { noremap = true, silent = true })
			vim.keymap.set("n", "n", require("undo-glow").search_next, { noremap = true, silent = true })
			vim.keymap.set("n", "N", require("undo-glow").search_prev, { noremap = true, silent = true })

			vim.api.nvim_create_autocmd("TextYankPost", {
				desc = "Highlight when yanking (copying) text",
				callback = require("undo-glow").yank,
			})

			vim.keymap.set({ "n", "x" }, "gc", function()
				require("undo-glow").highlight_changes({
					hlgroup = "UgUndo",
				})
				return require("vim._comment").operator()
			end, { expr = true, desc = "Toggle comment highlight" })

			vim.keymap.set("o", "gc", function()
				require("undo-glow").highlight_changes({
					hlgroup = "UgUndo",
				})
				return require("vim._comment").textobject()
			end, { desc = "Comment textobject with highlight" })

			vim.keymap.set({ "n" }, "gcc", function()
				require("undo-glow").highlight_changes({
					hlgroup = "UgUndo",
				})
				return require("vim._comment").operator() .. "_"
			end, { expr = true, desc = "Toggle comment line with highlight" })

			vim.keymap.set("n", "*", function()
				vim.cmd("normal! *")

				local bufnr = vim.api.nvim_get_current_buf()
				local cursor = vim.api.nvim_win_get_cursor(0)
				local row = cursor[1] - 1

				local search_pattern = vim.fn.getreg("/")
				if search_pattern == "" then
					return
				end

				local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
				if not line then
					return
				end

				local reg = vim.regex(search_pattern)
				local match_start = reg:match_str(line)
				if match_start == nil then
					return
				end

				local matched_text = vim.fn.matchstr(line, search_pattern)
				local match_end = match_start + #matched_text

				require("undo-glow").highlight_region({
					hlgroup = "UgUndo",
					s_row = row,
					s_col = match_start,
					e_row = row,
					e_col = match_end,
				})
			end, { silent = true })
		end,
	},
}
