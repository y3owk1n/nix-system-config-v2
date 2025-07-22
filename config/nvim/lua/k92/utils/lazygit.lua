local M = {}

local term_buf = nil -- holds the buffer number

function M.lazygit()
	-- If already running → close it
	if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
		vim.api.nvim_buf_delete(term_buf, { force = true })
		term_buf = nil
		return
	end

	-- Create scratch buffer and floating window
	term_buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.9)
	local height = math.floor(vim.o.lines * 0.9)
	vim.api.nvim_open_win(term_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = (vim.o.columns - width) / 2,
		row = (vim.o.lines - height) / 2,
		style = "minimal",
		border = "rounded",
	})

	-- Start the terminal job
	vim.fn.jobstart({ "lazygit" }, {
		term = true,
		on_exit = function()
			if vim.api.nvim_buf_is_valid(term_buf) then
				vim.api.nvim_buf_delete(term_buf, { force = true })
			end
			term_buf = nil
		end,
	})

	vim.cmd("startinsert")
end

return M
