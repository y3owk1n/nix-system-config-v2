local M = {}

---@return string
M.find_root = function(ctx, file_patterns)
	return vim.fs.find(file_patterns, { path = ctx.filename, upward = true })[1]
end

---@return string
M.current_file_path_relative = function()
	return vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
end

---@param file string
---@return string
M.current_file_path_absolute = function(file)
	return vim.fn.fnamemodify(file, ":p")
end

---@param search_text string
---@param path string
M.find_text_in_file = function(search_text, path)
	local find_command =
		string.format("rg --count '\\\"%s\\\"' %s", search_text, path)

	local result = vim.fn.system(find_command)

	result = result:gsub("%s+", "")

	-- Convert the result to a number
	local count = tonumber(result)

	-- Return the count
	return count or 0 -- If the conversion fails, return 0
end

return M
