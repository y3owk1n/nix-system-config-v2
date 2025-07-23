local M = {}

---Find a window displaying a buffer with the given filetype.
---@param filetype string
---@return integer|nil win_id Returns window ID or nil if not found.
M.find_buf_win_by_ft = function(filetype)
	local wins = vim.api.nvim_tabpage_list_wins(0)
	for _, win in ipairs(wins) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == filetype then
			return win
		end
	end
end

---Set the name of a buffer in a structured format.
---@param buf_id integer
---@param buf_prefix string
---@param name string
M.set_buf_name = function(buf_id, buf_prefix, name)
	vim.api.nvim_buf_set_name(buf_id, buf_prefix .. "://" .. buf_id .. "/" .. name)
end

---Create (or reuse) a buffer and populate it with content.
---@param buf_id? integer If nil, a new buffer will be created.
---@param filetype string Filetype to assign to the buffer.
---@param content string|string[] Content to set in the buffer.
---@param syntax? string Optional syntax for Treesitter or `:syntax`.
M.create = function(buf_id, filetype, content, syntax)
	for _, id in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[id].filetype == filetype then
			buf_id = id
		end
	end
	if buf_id == nil then
		buf_id = vim.api.nvim_create_buf(true, true)
		M.set_buf_name(buf_id, filetype, filetype)
		vim.bo[buf_id].filetype = filetype
	end

	vim.bo[buf_id].modifiable = true
	vim.bo[buf_id].readonly = false

	if syntax then
		local lang = vim.treesitter.language.get_lang(syntax)
		if not (lang and pcall(vim.treesitter.start, buf_id, lang)) then
			vim.bo[buf_id].syntax = syntax
		end
	end

	if type(content) == "string" then
		content = vim.split(content, "\n")
	end

	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, content)

	vim.api.nvim_win_set_buf(0, buf_id)

	vim.bo[buf_id].bufhidden = "wipe"
	vim.bo[buf_id].modifiable = false
	vim.bo[buf_id].readonly = true
end

---Open the buffer in a vertical split, or jump to the existing window.
---@param buf_id? integer Buffer ID (optional; will create new if nil).
---@param filetype string Filetype to identify window reuse.
---@param content string|string[] Content to populate in the buffer.
---@param syntax? string Optional syntax language.
M.open = function(buf_id, filetype, content, syntax)
	local win_id = M.find_buf_win_by_ft(filetype)

	if not win_id then
		vim.cmd.vsplit()
		M.create(buf_id, filetype, content, syntax)
		return
	end

	vim.api.nvim_set_current_win(win_id)
	M.create(buf_id, filetype, content, syntax)
end

return M
