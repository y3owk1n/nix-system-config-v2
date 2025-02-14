local M = {}

-- Create a namespace for our highlights.
local ns = vim.api.nvim_create_namespace("highlight-undo")
local duration = 300 -- Duration (in ms) to keep the highlight

-- Internal state for tracking which highlight group to use
local current_hlgroup = "HighlightUndo"
local should_detach = false
local timer = vim.loop.new_timer()

-- Highlights a range in the buffer. Works for single‐line or multi‐line regions.
local function highlight_range(bufnr, hlgroup, s_row, s_col, e_row, e_col)
	if s_row == e_row then
		vim.api.nvim_buf_add_highlight(bufnr, ns, hlgroup, s_row, s_col, e_col)
	else
		-- First line: from s_col to end of line.
		vim.api.nvim_buf_add_highlight(bufnr, ns, hlgroup, s_row, s_col, -1)
		-- Intermediate lines: whole lines.
		for l = s_row + 1, e_row - 1 do
			vim.api.nvim_buf_add_highlight(bufnr, ns, hlgroup, l, 0, -1)
		end
		-- Last line: from beginning up to e_col.
		vim.api.nvim_buf_add_highlight(bufnr, ns, hlgroup, e_row, 0, e_col)
	end
end

-- on_bytes callback: computes the changed region based on the callback parameters.
-- The signature is:
--    on_bytes(err, bufnr, changedtick, start_row, start_col, byte_offset,
--             old_end_row, old_end_col, old_byte_offset,
--             new_end_row, new_end_col, new_byte_offset)
function M.on_bytes(_, bufnr, _, s_row, s_col, _, _old_er, _old_ec, _old_off, new_er, new_ec, _new_off)
	if should_detach then
		return true -- detach if we're done
	end

	-- Calculate the ending position.
	local end_row, end_col
	if new_er == 0 then
		-- Single-line change: new_ec is relative to the start column.
		end_row = s_row
		end_col = s_col + new_ec
	else
		-- Multi-line change: new_er is the number of lines added,
		-- and new_ec is the absolute column on the last line.
		end_row = s_row + new_er
		end_col = new_ec
	end

	vim.schedule(function()
		highlight_range(bufnr, current_hlgroup, s_row, s_col, end_row, end_col)
	end)
	return false
end

-- Clear the highlights after the specified duration.
function M.clear_highlights(bufnr)
	timer:stop()
	timer:start(
		duration,
		0,
		vim.schedule_wrap(function()
			vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
			should_detach = true
		end)
	)
end

-- Wrap the undo command.
function M.undo()
	local bufnr = vim.api.nvim_get_current_buf()
	current_hlgroup = "HighlightUndo"
	should_detach = false
	vim.api.nvim_buf_attach(bufnr, false, { on_bytes = M.on_bytes })
	vim.cmd("undo")
	vim.schedule(function()
		M.clear_highlights(bufnr)
	end)
end

-- Wrap the redo command.
function M.redo()
	local bufnr = vim.api.nvim_get_current_buf()
	current_hlgroup = "HighlightRedo"
	should_detach = false
	vim.api.nvim_buf_attach(bufnr, false, { on_bytes = M.on_bytes })
	vim.cmd("redo")
	vim.schedule(function()
		M.clear_highlights(bufnr)
	end)
end

return M
