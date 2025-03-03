-- Better start & end line
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Move to start of line" })
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Move to end of line" })

-- Better up & down
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Better indentation
vim.keymap.set("v", "<", "<gv", { desc = "Dedent" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent" })

-- Launch lazy window
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Better yank with cursor remain
vim.keymap.set({ "n", "x" }, "y", function()
	require("k92.utils.preserve-cursor").preserve_cursor()

	return "y"
end, { expr = true, noremap = true, desc = "Yank and remain cursor" })

-- Location & Quickfix
vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- Diagnostics
local diagnostic_goto = function(next, severity)
	severity = severity and vim.diagnostic.severity[severity] or nil

	-- TODO: Update this when update to 0.11
	if vim.fn.has("nvim-0.11") == 1 then
		local count
		if next then
			count = 1
		else
			count = -1
		end
		return function()
			vim.diagnostic.jump({ severity = severity, count = count, float = true })
		end
	else
		local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
		return function()
			go({ severity = severity })
		end
	end
end
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- Window Splitting
vim.keymap.set("n", "-", "<C-W>s", { desc = "Split Window Below", remap = true })
vim.keymap.set("n", "\\", "<C-W>v", { desc = "Split Window Right", remap = true })

--- Select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })

--- Center page during actions
-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down and center" })
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up and center" })
-- vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zvzz'", { expr = true, desc = "Search next and center" })
-- vim.keymap.set("n", "N", "'nN'[v:searchforward].'zz'", { expr = true, desc = "Search next and center" })

--- Do things without affecting the registers
vim.keymap.set("n", "x", '"_x', { desc = "Delete a character without copying it" })

--- Move lines
vim.keymap.set("v", "J", ":m '>+1<cr> | :normal gv=gv<cr>", { desc = "Move line up" })
vim.keymap.set("v", "K", ":m '<-2<cr> | :normal gv=gv<cr>", { desc = "Move line down" })

-- No op
vim.keymap.set({ "n", "x" }, "Q", "<nop>", { desc = "No op" })

-- Mason
vim.keymap.set("n", "<leader>m", "<cmd>Mason<cr>", { desc = "Mason" })

if vim.fn.has("nvim-0.11") == 1 then
	-- Delete default neovim lsp bindings
	vim.keymap.del("n", "gra")
	vim.keymap.del("n", "gri")
	vim.keymap.del("n", "grn")
	vim.keymap.del("n", "grr")
	vim.keymap.del("x", "gra")
end
