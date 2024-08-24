local augroup = require("k92.utils.autocmds").augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	desc = "Check if buffers changed on editor focus",
	group = augroup("checktime"),
	command = "checktime",
})

-- Highlight on yank
autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- resize splits if window got resized
autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- go to last loc when opening a buffer
autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function(event)
		local exclude = { "gitcommit" }
		local buf = event.buf
		if
			vim.tbl_contains(exclude, vim.bo[buf].filetype)
			or vim.b[buf].lazyvim_last_loc
		then
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

-- close some filetypes with <q> or <esc>
autocmd("FileType", {
	group = augroup("close_with_q_or_esc"),
	pattern = {
		"PlenaryTestPopup",
		"help",
		"lspinfo",
		"man",
		"notify",
		"qf",
		"query",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"neotest-output",
		"checkhealth",
		"neotest-summary",
		"neotest-output-panel",
		"oil",
		"Trouble",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set(
			"n",
			"q",
			"<cmd>close<cr>",
			{ buffer = event.buf, silent = true }
		)
		vim.keymap.set(
			"n",
			"<esc>",
			"<cmd>close<cr>",
			{ buffer = event.buf, silent = true }
		)
	end,
})

-- wrap and check for spell in text filetypes
autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- -- Make cmdheight 1 if entering macro
-- autocmd("RecordingEnter", {
-- 	pattern = "*",
-- 	command = "set cmdheight=2",
-- })
--
-- -- Make cmdheight 0 if leaving macro
-- autocmd("RecordingLeave", {
-- 	pattern = "*",
-- 	command = "set cmdheight=0",
-- })

-- Turn off paste mode when leaving insert
autocmd("InsertLeave", {
	pattern = "*",
	command = "set nopaste",
})

-- Fix conceallevel for json files
autocmd("FileType", {
	pattern = { "json", "jsonc" },
	callback = function()
		vim.wo.spell = false
		vim.wo.conceallevel = 0
	end,
})

-- Fix conceallevel for markdown files
autocmd("FileType", {
	pattern = { "markdown" },
	callback = function()
		vim.wo.conceallevel = 2
	end,
})

-- Add border to lspinfo
autocmd({ "FileType" }, {
	group = augroup("lspinfo_border"),
	pattern = {
		"lspinfo",
		"mason.nvim",
	},
	callback = function()
		require("lspconfig.ui.windows").default_options.border = "rounded"
	end,
})

-- Make help page open in vertical split
autocmd("FileType", {
	group = augroup("vertical_help"),
	pattern = "help",
	callback = function()
		vim.bo.bufhidden = "unload"
		vim.cmd.wincmd("L")
		vim.cmd.wincmd("=")
	end,
})
