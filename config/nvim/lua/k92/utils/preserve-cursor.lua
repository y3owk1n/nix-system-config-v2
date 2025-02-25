local M = {}

function M.preserve_cursor()
	local pos = vim.fn.getpos(".")

	vim.schedule(function()
		vim.fn.setpos(".", pos)
	end)
end

return M
