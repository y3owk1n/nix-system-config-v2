local M = {}

--- Inserts a new line after the current line in the buffer while preserving indentation
---@param text string
local function insert_line_after_cursor(text)
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor[1] -- 1-indexed

	-- Get the current line text to capture its indentation
	local current_line_text = vim.api.nvim_buf_get_lines(bufnr, current_line - 1, current_line, false)[1]
	local indent = current_line_text:match("^%s*") or ""
	local indented_text = indent .. text

	-- Insert the indented text as a new line after the current line
	vim.api.nvim_buf_set_lines(bufnr, current_line, current_line, false, { indented_text })
end

--- Gets the token based on visual mode or current word
---@return string | nil
local function get_token()
	local mode = vim.fn.mode()

	if mode:match("[vV]") then -- Visual mode
		-- Wait for selection to complete
		vim.cmd([[execute "normal! \<ESC>"]])

		local start_line = vim.fn.line("'<") - 1 -- 0-based
		local end_line = vim.fn.line("'>") - 1
		local start_col = vim.fn.col("'<") - 1 -- 0-based
		local end_col = vim.fn.col("'>") -- 1-based

		local visual_mode = vim.fn.visualmode()

		if visual_mode == "V" then -- Linewise
			local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
			return table.concat(lines, " ")
		else
			-- Handle multi-line selections
			local lines = vim.api.nvim_buf_get_text(0, start_line, start_col, end_line, end_col, {})
			return table.concat(lines, " ")
		end
	else -- Normal mode
		return vim.fn.expand("<cword>")
	end
end

--- Function to check if the current filetype is a JS filetype
---@param filetype string
---@return boolean
local function is_js(filetype)
	local js_filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
	}

	for _, ft in ipairs(js_filetypes) do
		if filetype == ft then
			return true
		end
	end

	return false
end

--- Function to check if the current filetype is a lua filetype
---@param filetype string
---@return boolean
local function is_lua(filetype)
	return filetype == "lua"
end

--- Generates a JS log statement
---@param token string
---@return string
local function js_log(token)
	return 'console.log(">>>>>>>>>> ' .. token .. ': ", ' .. token .. ")"
end

--- Generates a lua log statement
---@param token string
---@return string
local function lua_log(token)
	if vim.fn.exists("*Snacks#debug") then
		return "Snacks.debug(" .. token .. ")"
	end

	return "vim.notify(" .. token .. ")"
end

--- Processes the current filetype and generates a log statement
---@param filetype string
---@param token string
---@return string | nil
local function process_filetype(filetype, token)
	if is_js(filetype) then
		return js_log(token)
	end

	if is_lua(filetype) then
		return lua_log(token)
	end
end

--- Sets a log statement in the current buffer
---@return nil
function M.set_log_statement()
	local filetype = vim.bo.filetype

	local token = get_token()

	if not token or token == "" then
		vim.notify("No token available", vim.log.levels.ERROR)
		return
	end

	local log_statement = process_filetype(filetype, token)

	if not log_statement then
		vim.notify("Unsupported filetype: " .. filetype, vim.log.levels.ERROR)
		return
	end

	insert_line_after_cursor(log_statement)
end

return M
