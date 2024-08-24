local M = {}

M.is_writing_in_buffer_only = function()
	-- Check if we are in a buffer
	local in_buffer = vim.fn.buflisted(vim.fn.bufnr("%")) > 0

	return in_buffer
end

return M
