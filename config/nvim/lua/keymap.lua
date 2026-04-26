-- =========================================================
--  Update vim.pack
-- =========================================================

vim.keymap.set("n", "<leader>pu", function()
  vim.pack.update()
end, { desc = "Pack update" })

-- =========================================================
--  Arglist (harpoon like but not persistent)
-- =========================================================

vim.keymap.set("n", "<leader>ha", function()
  vim.cmd("$argadd %")
  vim.cmd("argdedup")
end, { desc = "Arglist add current file" })

vim.keymap.set("n", "<leader>he", function()
  local args = vim.fn.argv()
  local items = {}

  if type(args) == "string" then
    args = { args }
  end

  for _, file in ipairs(args) do
    table.insert(items, {
      filename = file,
      lnum = 1,
      text = file,
    })
  end

  vim.fn.setqflist({}, " ", {
    title = "Arglist",
    items = items,
  })

  vim.cmd("copen")
end, { desc = "Arglist explore" })

-- Arglist jump
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. tostring(i), function()
    vim.cmd("silent! " .. tostring(i) .. "argument")
  end, { desc = "Arglist jump to " .. tostring(i) })
end

-- =========================================================
--  Movement enhancements
-- =========================================================

vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move down" })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move up" })

-- =========================================================
--  Visual indent
-- =========================================================

vim.keymap.set("v", "<", "<gv", { desc = "Visual indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Visual indent right" })

-- =========================================================
--  Splits
-- =========================================================

vim.keymap.set("n", "-", "<C-W>s", { remap = true, desc = "Horizontal split" })
vim.keymap.set("n", "\\", "<C-W>v", { remap = true, desc = "Vertical split" })

-- =========================================================
--  QOL improvements
-- =========================================================

vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Move cursor to most left" })
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Move cursor to most right" })

vim.keymap.set("n", "<C-a>", "gg<S-v>G", { desc = "Select the whole buffer content" })
vim.keymap.set("n", "x", '"_x', { desc = "Delete the character under the cursor without putting it in the register" })

vim.keymap.set("v", "J", ":m '>+1<cr> | :normal gv=gv<cr>", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<cr> | :normal gv=gv<cr>", { desc = "Move line up" })

-- =========================================================
--  Disable some default mappings
-- =========================================================

vim.keymap.set({ "n", "x" }, "Q", "<nop>")
