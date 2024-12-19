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

-- Remove whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "",
	command = ":%s/\\s\\+$//e",
})

-- Don't auto commenting new lines
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "",
	command = "set fo-=c fo-=r fo-=o",
})

-- close mini.files with <q> or <esc>
vim.api.nvim_create_autocmd("FileType", {
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
	pattern = "*",
	command = "set nopaste",
})

-- vim: ts=2 sts=2 sw=2 et
