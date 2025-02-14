local M = {}

-- Create a namespace for our highlights.
local ns = vim.api.nvim_create_namespace("highlight-undo")
local duration = 300 -- Duration (in ms) to keep the highlight

-- Helper: highlight the current line using the given highlight group.
local function highlight_line(hlgroup)
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0) -- returns {line, col}
	local line = cursor[1] - 1 -- zero-indexed
	vim.api.nvim_buf_add_highlight(bufnr, ns, hlgroup, line, 0, -1)
	vim.defer_fn(function()
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	end, duration)
end

-- Wrap the "undo" command: run it then highlight.
function M.undo()
	vim.cmd("undo")
	highlight_line("HighlightUndo")
end

-- Wrap the "redo" command: run it then highlight.
function M.redo()
	vim.cmd("redo")
	highlight_line("HighlightRedo")
end

return M
