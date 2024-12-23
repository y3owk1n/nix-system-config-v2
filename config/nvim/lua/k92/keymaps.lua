-- Better start & end line
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Move to start of line" })
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Move to end of line" })

-- Better up & down
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Better indentation
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Launch lazy window
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Location & Quickfix
vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- Diagnostics
local diagnostic_goto = function(next, severity)
	severity = severity and vim.diagnostic.severity[severity] or nil

	if vim.fn.has("nvim-0.11") == 0 then
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
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up and center" })
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zvzz'", { expr = true, desc = "Search next and center" })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zz'", { expr = true, desc = "Search next and center" })

--- Do things without affecting the registers
vim.keymap.set("n", "x", '"_x', { desc = "Delete a character without copying it" })

--- Move lines
vim.keymap.set("v", "K", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "J", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move line up" })

-- No op
vim.keymap.set("n", "Q", "<nop>", { desc = "No op" })

-- Mason
vim.keymap.set("n", "<leader>m", "<cmd>Mason<cr>", { desc = "Mason" })

-- Lazygit
vim.keymap.set("n", "<leader>gg", function()
	Snacks.lazygit()
end, { desc = "Lazygit (cwd)" })
vim.keymap.set("n", "<leader>gf", function()
	Snacks.lazygit.log_file()
end, { desc = "Lazygit Current File History" })
vim.keymap.set("n", "<leader>gl", function()
	Snacks.lazygit.log()
end, { desc = "Lazygit Log (cwd)" })
