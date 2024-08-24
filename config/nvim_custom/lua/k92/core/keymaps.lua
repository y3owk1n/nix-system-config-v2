local keymap = require("k92.utils.keymaps")
local map = keymap.map
local terminal = require("k92.utils.terminal")

-- Better up/down
map(
	{ "n", "x" },
	"j",
	"v:count == 0 ? 'gj' : 'j'",
	{ expr = true, silent = true, desc = "Move line down" }
)
map(
	{ "n", "x" },
	"<Down>",
	"v:count == 0 ? 'gj' : 'j'",
	{ expr = true, silent = true, desc = "Move line down" }
)
map(
	{ "n", "x" },
	"k",
	"v:count == 0 ? 'gk' : 'k'",
	{ expr = true, silent = true, desc = "Move line up" }
)
map(
	{ "n", "x" },
	"<Up>",
	"v:count == 0 ? 'gk' : 'k'",
	{ expr = true, silent = true, desc = "Move line up" }
)

-- Better start & end line
map({ "n", "v" }, "H", "^", { desc = "Move to start of line" })
map({ "n", "v" }, "L", "$", { desc = "Move to end of line" })

-- Better redo
-- map("n", "U", "<C-r>", { desc = "Dedent line" })

-- Better yank
map(
	"x",
	"y",
	"ygv<Esc>",
	{ desc = "Yank block and remain cursor", noremap = true, silent = true }
)

-- Better indenting
map("v", "<", "<gv", { desc = "Dedent line" })
map("v", ">", ">gv", { desc = "Indent line" })

-- Window management
map("n", "-", "<C-W>s", { desc = "Split window below" })
map("n", "\\", "<C-W>v", { desc = "Split window right" })
map("n", "<leader>wx", ":close<CR>", { desc = "Close current split" })

-- Clear search with <esc>
map(
	{ "i", "n" },
	"<esc>",
	"<cmd>noh<cr><esc>",
	{ desc = "Escape and clear hlsearch" }
)

-- Center page during actions
map("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up and center" })
map("n", "n", "nzzzv", { desc = "Search next and center" })
map("n", "N", "Nzzzv", { desc = "Search previous and center" })

-- Do things without affecting the registers
map("n", "x", '"_x', { desc = "Delete a character without copying it" })
map("x", "<leader>p", '"_dP', { desc = "Paste without replacing" })
map({ "n", "v" }, "<leader>d", '"_d', { desc = "[D]elete without replacing" })

-- Press 'S' for quick find/replace for the word under the cursor
map("n", "<leader>r", function()
	local cmd = ":%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>"
	local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "[R]eplace word under cursor" })

-- Quick SO
map("n", "<leader>S", function()
	vim.cmd("so")
	print("source file")
end, { desc = "[S]ource file" })

-- Make file executable
map(
	"n",
	"<leader>fx",
	"<cmd>!chmod +x %<cr>",
	{ desc = "Make file executable" }
)

-- Move lines
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move line up" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move line down" })

-- Lazygit
map("n", "<leader>gg", function()
	terminal({ "lazygit" }, { esc_esc = false, ctrl_hjkl = false })
end, { desc = "Lazygit (cwd)" })

-- Color conversion
map("n", "<leader>ch", function()
	require("utils.color").replaceHexWithHSL()
end, {
	desc = "Replace Hex With HSL",
})

-- No op
map("n", "Q", "<nop>", { desc = "No op" })
