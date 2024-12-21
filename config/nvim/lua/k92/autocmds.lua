-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

local function augroup(name)
	return vim.api.nvim_create_augroup("k92_" .. name, { clear = true })
end

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = augroup("highlight_yank"),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"PlenaryTestPopup",
		"checkhealth",
		"dbout",
		"gitsigns-blame",
		"grug-far",
		"help",
		"lspinfo",
		"neotest-output",
		"neotest-output-panel",
		"neotest-summary",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				vim.cmd("close")
				pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
			end, {
				buffer = event.buf,
				silent = true,
				desc = "Quit buffer",
			})
		end)
	end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function(event)
		local exclude = { "gitcommit" }
		local buf = event.buf
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
			return
		end
		vim.b[buf].lazyvim_last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Remove whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("remove_whitespace_on_save"),
	pattern = "",
	command = ":%s/\\s\\+$//e",
})

-- Don't auto commenting new lines
vim.api.nvim_create_autocmd("BufEnter", {
	group = augroup("no_auto_commeting_new_lines"),
	pattern = "",
	command = "set fo-=c fo-=r fo-=o",
})

-- close mini.files with <q> or <esc>
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q_mini_files"),
	pattern = {
		"MiniFiles",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", function()
			require("mini.files").close()
		end, { buffer = event.buf, silent = true })
		vim.keymap.set("n", "<esc>", function()
			require("mini.files").close()
		end, { buffer = event.buf, silent = true })
	end,
})

-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
	group = augroup("paste_mode_off_leaving_insert"),
	pattern = "*",
	command = "set nopaste",
})

-- Always keep the cursor vertically centered
local obs = false
local function set_scrolloff(winid)
	if obs then
		vim.wo[winid].scrolloff = math.floor(math.max(10, vim.api.nvim_win_get_height(winid) / 10))
	else
		vim.wo[winid].scrolloff = 1 + math.floor(vim.api.nvim_win_get_height(winid) / 2)
	end
end
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinNew", "VimResized" }, {
	desc = "Always keep the cursor vertically centered",
	pattern = "*",
	group = augroup("scrolloff_centered"),
	callback = function()
		set_scrolloff(0)
	end,
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

-- Resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- Close the scratch preview automatically
vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertLeave" }, {
	group = augroup("close_scratch_preview"),
	desc = "Close the popup-menu automatically",
	pattern = "*",
	command = "if pumvisible() == 0 && !&pvw && getcmdwintype() == ''|pclose|endif",
})

vim.api.nvim_create_autocmd("BufNew", {
	group = augroup("edit_files_with_line"),
	desc = "Edit files with :line at the end",
	pattern = "*",
	callback = function(args)
		local bufname = vim.api.nvim_buf_get_name(args.buf)
		local root, line = bufname:match("^(.*):(%d+)$")
		if vim.fn.filereadable(bufname) == 0 and root and line and vim.fn.filereadable(root) == 1 then
			vim.schedule(function()
				vim.cmd.edit({ args = { root } })
				pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
				vim.api.nvim_buf_delete(args.buf, { force = true })
			end)
		end
	end,
})

-- show cursor line only in active window
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
	group = augroup("auto_cursorline_show"),
	callback = function()
		if vim.w.auto_cursorline then
			vim.wo.cursorline = true
			vim.w.auto_cursorline = nil
		end
	end,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
	group = augroup("auto_cursorline_hide"),
	callback = function()
		if vim.wo.cursorline then
			vim.w.auto_cursorline = true
			vim.wo.cursorline = false
		end
	end,
})
