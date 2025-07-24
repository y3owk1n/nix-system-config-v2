local augroup = require("k92.utils.autocmds").augroup

------------------------------------------------------------
-- Yank Highlight (Optional)
------------------------------------------------------------
-- Currently highlight with `undo-glow.nvim`.
-- Only enable it when personal plugins are stripped.
if vim.g.strip_personal_plugins then
	vim.api.nvim_create_autocmd("TextYankPost", {
		desc = "Highlight when yanking (copying) text",
		group = augroup("highlight_yank"),
		callback = function()
			(vim.hl or vim.highlight).on_yank()
		end,
	})
end

------------------------------------------------------------
-- Close Certain Filetypes with <q>
------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"checkhealth",
		"dbout",
		"grug-far",
		"help",
		"qf",
		"startuptime",
		"tsplayground",
		"mininotify-history",
		"lspinfo",
		"lsplog",
		"lintinfo",
	},
	callback = function(event)
		-- Prevent the buffer from appearing in the buffer list.
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			-- Map <q> in the buffer to close it and delete the buffer.
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

------------------------------------------------------------
-- Open Buffer: Restore Last Cursor Location
------------------------------------------------------------
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function(event)
		local exclude = { "gitcommit" }
		local buf = event.buf
		-- Skip if filetype is excluded or already processed.
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
			return
		end
		vim.b[buf].last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		-- Jump to last cursor position if it's within file bounds.
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

------------------------------------------------------------
-- Remove Trailing Whitespace on Save
------------------------------------------------------------
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("remove_whitespace_on_save"),
	pattern = "",
	-- Remove trailing whitespace before saving.
	command = ":%s/\\s\\+$//e",
})

------------------------------------------------------------
-- Disable Auto-Commenting on New Lines
------------------------------------------------------------
vim.api.nvim_create_autocmd("BufEnter", {
	group = augroup("no_auto_commeting_new_lines"),
	pattern = "",
	-- Remove automatic insertion of comment leaders on new lines.
	command = "set fo-=c fo-=r fo-=o",
})

------------------------------------------------------------
-- Turn Off Paste Mode When Leaving Insert Mode
------------------------------------------------------------
vim.api.nvim_create_autocmd("InsertLeave", {
	group = augroup("paste_mode_off_leaving_insert"),
	pattern = "*",
	-- Disable paste mode upon exiting insert mode.
	command = "set nopaste",
})

------------------------------------------------------------
-- Keep Cursor Vertically Centered
------------------------------------------------------------
local obs = false
local function set_scrolloff(winid)
	if obs then
		-- If obs (option scrolloff balance) is true, set a smaller scrolloff.
		vim.wo[winid].scrolloff = math.floor(math.max(10, vim.api.nvim_win_get_height(winid) / 10))
	else
		-- Otherwise, keep the cursor roughly centered.
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

------------------------------------------------------------
-- Auto-Reload File if Changed Externally
------------------------------------------------------------
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	callback = function()
		-- Check if the file has changed on disk and reload if necessary.
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

------------------------------------------------------------
-- Resize Splits on Vim Window Resize
------------------------------------------------------------
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		-- Adjust all splits to be equal size.
		vim.cmd("tabdo wincmd =")
		-- Return to the original tab.
		vim.cmd("tabnext " .. current_tab)
	end,
})

------------------------------------------------------------
-- Close Scratch Preview Automatically
------------------------------------------------------------
vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertLeave" }, {
	group = augroup("close_scratch_preview"),
	desc = "Close the popup-menu automatically",
	pattern = "*",
	-- Close the popup menu if it's not visible.
	command = "if pumvisible() == 0 && !&pvw && getcmdwintype() == ''|pclose|endif",
})

------------------------------------------------------------
-- Open Files with :line Suffix at Specific Line
------------------------------------------------------------
vim.api.nvim_create_autocmd("BufNew", {
	group = augroup("edit_files_with_line"),
	desc = "Edit files with :line at the end",
	callback = function(args)
		local bufname = vim.api.nvim_buf_get_name(args.buf)
		-- Match files specified with a line number, e.g., "file.txt:123"
		local root, line = bufname:match("^(.*):(%d+)$")
		if vim.fn.filereadable(bufname) == 0 and root and line and vim.fn.filereadable(root) == 1 then
			vim.schedule(function()
				-- Edit the root file and jump to the specified line.
				vim.cmd.edit({ args = { root } })
				pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
				-- Remove the temporary buffer.
				vim.api.nvim_buf_delete(args.buf, { force = true })
			end)
		end
	end,
})

------------------------------------------------------------
-- Auto Toggle Cursorline Based on Window Focus
------------------------------------------------------------
-- Show the cursorline only in the active window.
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
	group = augroup("auto_cursorline_show"),
	callback = function()
		local win = vim.api.nvim_get_current_win()

		if vim.w[win].auto_cursorline then
			vim.wo[win].cursorline = true
			vim.w[win].auto_cursorline = nil
		end
	end,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
	group = augroup("auto_cursorline_hide"),
	callback = function()
		local win = vim.api.nvim_get_current_win()

		if vim.wo[win].cursorline then
			vim.w[win].auto_cursorline = true
			vim.wo[win].cursorline = false
		end
	end,
})

------------------------------------------------------------
-- Automatically Split Help Buffers to the Right
------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("split_help_right"),
	pattern = "help",
	-- Move help buffers to the right side.
	command = "wincmd L",
})

------------------------------------------------------------
-- Setup markdown checkbox toggle
------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("toggle_markdown_checkbox"),
	pattern = "markdown",
	callback = function()
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"<leader>cc",
			":lua require('k92.utils.markdown').toggle_markdown_checkbox()<CR>",
			{ desc = "Toggle Markdown Checkbox", noremap = true, silent = true }
		)

		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"<leader>cgc",
			":lua require('k92.utils.markdown').insert_markdown_checkbox()<CR>",
			{ desc = "Insert Markdown Checkbox", noremap = true, silent = true }
		)
	end,
})

------------------------------------------------------------
-- Disable laststatus on certain filetypes
------------------------------------------------------------
local ft_exclude_laststatus = { "ministarter" }

vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("buf_read_post_laststatus"),
	callback = function(ev)
		if vim.tbl_contains(ft_exclude_laststatus, vim.bo[ev.buf].filetype) then
			return
		end

		vim.o.laststatus = 3
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	group = augroup("vim_enter_laststatus"),
	pattern = "*",
	callback = function()
		if vim.tbl_contains(ft_exclude_laststatus, vim.bo.filetype) then
			vim.o.laststatus = 0
		end
	end,
})
