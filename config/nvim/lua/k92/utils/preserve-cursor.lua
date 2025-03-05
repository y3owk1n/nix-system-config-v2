local M = {}

function M.preserve_cursor()
	local pos = vim.fn.getpos(".")

	vim.schedule(function()
		vim.g.ug_ignore_cursor_moved = true
		vim.fn.setpos(".", pos)
	end)
end

return M
