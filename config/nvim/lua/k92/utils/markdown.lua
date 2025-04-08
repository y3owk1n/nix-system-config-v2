local M = {}

function M.toggle_markdown_checkbox()
	local line_nr = vim.api.nvim_win_get_cursor(0)[1] - 1
	local line = vim.api.nvim_buf_get_lines(0, line_nr, line_nr + 1, false)[1]

	if line:find("%[ %]") then
		line = line:gsub("%[ %]", "[x]")
	elseif line:find("%[x%]") then
		line = line:gsub("%[x%]", "[ ]")
	end

	vim.api.nvim_buf_set_lines(0, line_nr, line_nr + 1, false, { line })
end

function M.insert_markdown_checkbox()
	local bufnr = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()
	local row, col = unpack(vim.api.nvim_win_get_cursor(win))
	row = row - 1

	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	local indent = line:match("^(%s*)") or ""

	local checkbox = indent .. "- [ ] " .. " "

	vim.api.nvim_buf_set_lines(bufnr, row + 1, row + 1, false, { checkbox })

	vim.api.nvim_win_set_cursor(win, { row + 2, #checkbox })

	vim.cmd("startinsert")
end

return M
