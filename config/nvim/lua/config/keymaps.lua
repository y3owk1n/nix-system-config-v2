-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Delete some default keymaps

-- better up/down
vim.keymap.del({ "n", "x" }, "<Down>")
vim.keymap.del({ "n", "x" }, "<Up>")

-- Resize window using <ctrl> arrow keys
vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Right>")

-- Move Lines
vim.keymap.del({ "n", "i", "v" }, "<A-j>")
vim.keymap.del({ "n", "i", "v" }, "<A-k>")

-- buffers
vim.keymap.del("n", "<S-h>")
vim.keymap.del("n", "<S-l>")
vim.keymap.del("n", "[b")
vim.keymap.del("n", "]b")
vim.keymap.del("n", "<leader>bb")
vim.keymap.del("n", "<leader>`")
vim.keymap.del("n", "<leader>,")
vim.keymap.del("n", "<leader>bd")
vim.keymap.del("n", "<leader>bD")

-- save file
vim.keymap.del({ "i", "x", "n", "s" }, "<C-s>")

-- floating terminal
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<c-/>")
vim.keymap.del("n", "<c-_>")

-- Terminal Mappings
vim.keymap.del("t", "<esc><esc>")
vim.keymap.del("t", "<C-h>")
vim.keymap.del("t", "<C-j>")
vim.keymap.del("t", "<C-k>")
vim.keymap.del("t", "<C-l>")
vim.keymap.del("t", "<C-/>")
vim.keymap.del("t", "<c-_>")

--- Window management
vim.keymap.del("n", "<leader>-")
vim.keymap.del("n", "<leader>|")

-- tabs
vim.keymap.del("n", "<leader><tab>l")
vim.keymap.del("n", "<leader><tab>o")
vim.keymap.del("n", "<leader><tab>f")
vim.keymap.del("n", "<leader><tab><tab>")
vim.keymap.del("n", "<leader><tab>]")
vim.keymap.del("n", "<leader><tab>d")
vim.keymap.del("n", "<leader><tab>[")

-- Start configuration

-- Better start & end line
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Move to start of line" })
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Move to end of line" })

-- Better yank
-- vim.keymap.set(
-- 	"x",
-- 	"y",
-- 	"ygv<Esc>",
-- 	{ desc = "Yank block and remain cursor", noremap = true, silent = true }
-- )

-- Window Splitting
vim.keymap.set(
	"n",
	"-",
	"<C-W>s",
	{ desc = "Split Window Below", remap = true }
)
vim.keymap.set(
	"n",
	"\\",
	"<C-W>v",
	{ desc = "Split Window Right", remap = true }
)

--- Select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })

--- Center page during actions
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up and center" })
vim.keymap.set(
	"n",
	"n",
	"'Nn'[v:searchforward].'zvzz'",
	{ expr = true, desc = "Search next and center" }
)
vim.keymap.set(
	"n",
	"N",
	"'nN'[v:searchforward].'zz'",
	{ expr = true, desc = "Search next and center" }
)

--- Do things without affecting the registers
vim.keymap.set(
	"n",
	"x",
	'"_x',
	{ desc = "Delete a character without copying it" }
)
-- vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "Delete without replacing" })
-- vim.keymap.set({ "n", "v" }, "c", '"_c', { desc = "Change without replacing" })

--- Find/replace for the word under the cursor
-- vim.keymap.set("n", "<leader>r", function()
-- 	local cmd = ":%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>"
-- 	local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
-- 	vim.api.nvim_feedkeys(keys, "n", false)
-- end, { desc = "Replace word under cursor" })

--- Move lines
vim.keymap.set("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move line up" })
vim.keymap.set("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move line down" })

-- No op
vim.keymap.set("n", "Q", "<nop>", { desc = "No op" })

-- Mason
vim.keymap.set("n", "<leader>m", "<cmd>Mason<cr>", { desc = "Mason" })

-- Terminal Actions
vim.keymap.set(
	"n",
	"<leader>tzr",
	":! zellij run -- ",
	{ desc = "Term: Zellij Run" }
)
