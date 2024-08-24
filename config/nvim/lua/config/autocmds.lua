-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	command = "set nopaste",
})

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "jsonc", "markdown.mdx" },
	callback = function()
		vim.opt.conceallevel = 0
	end,
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
