------------------------------------------------------------
-- Navigation: Start & End of Line
------------------------------------------------------------
-- Move to the start of the line in normal and visual modes.
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Move to start of line" })
-- Move to the end of the line in normal and visual modes.
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Move to end of line" })

------------------------------------------------------------
-- Navigation: Better Up & Down Movement
------------------------------------------------------------
-- Move down: Use 'gj' if no count is given, otherwise 'j'.
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
-- Move up: Use 'gk' if no count is given, otherwise 'k'.
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

------------------------------------------------------------
-- Visual Mode: Indentation Adjustments
------------------------------------------------------------
-- In visual mode, dedent and reselect the block.
vim.keymap.set("v", "<", "<gv", { desc = "Dedent" })
-- In visual mode, indent and reselect the block.
vim.keymap.set("v", ">", ">gv", { desc = "Indent" })

------------------------------------------------------------
-- Yank Behavior: Preserve Cursor Position
------------------------------------------------------------
-- Yank text in normal and visual modes while keeping the cursor in place.
vim.keymap.set({ "n", "x" }, "y", function()
  -- Preserve the current cursor position when yanking.
  local pos = vim.fn.getpos(".")

  vim.schedule(function()
    vim.g.ug_ignore_cursor_moved = true
    vim.fn.setpos(".", pos)
  end)
  return "y"
end, { expr = true, noremap = true, desc = "Yank and remain cursor" })

------------------------------------------------------------
-- Location & Quickfix
------------------------------------------------------------
-- Open the location list.
vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
-- Open the quickfix list.
vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

------------------------------------------------------------
-- Window Splitting
------------------------------------------------------------
-- Split window horizontally (new window appears below).
vim.keymap.set("n", "-", "<C-W>s", { desc = "Split Window Below", remap = true })
-- Split window vertically (new window appears to the right).
vim.keymap.set("n", "\\", "<C-W>v", { desc = "Split Window Right", remap = true })

------------------------------------------------------------
-- Miscellaneous Editing
------------------------------------------------------------
-- Select all text in the buffer.
vim.keymap.set("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })
-- Delete a character without copying it to a register.
vim.keymap.set("n", "x", '"_x', { desc = "Delete a character without copying it" })

------------------------------------------------------------
-- Moving Lines in Visual Mode
------------------------------------------------------------
-- Move selected lines down and reselect the block.
vim.keymap.set("v", "J", ":m '>+1<cr> | :normal gv=gv<cr>", { desc = "Move line down" })
-- Move selected lines up and reselect the block.
vim.keymap.set("v", "K", ":m '<-2<cr> | :normal gv=gv<cr>", { desc = "Move line up" })

------------------------------------------------------------
-- Disable Unwanted Commands
------------------------------------------------------------
-- Map Q to no operation to avoid accidental use.
vim.keymap.set({ "n", "x" }, "Q", "<nop>", { desc = "No op" })

------------------------------------------------------------
-- Remove Default Neovim LSP Bindings
------------------------------------------------------------
-- Delete default Neovim LSP bindings that are not needed.
vim.keymap.del("s", "<C-s>") -- macos stealed the key, use `grs` instead
vim.keymap.del("i", "<C-S>") -- macos stealed the key, use `grs` instead
