local M = {}

M.augroup = function(name)
	return vim.api.nvim_create_augroup("k92_" .. name, { clear = true })
end

return M
