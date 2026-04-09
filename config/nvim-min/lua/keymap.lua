-- =========================================================
--  Update vim.pack
-- =========================================================

vim.keymap.set("n", "<leader>pu", function()
  vim.pack.update(nil, { target = "lockfile" })
end, { desc = "Pack update" })

-- =========================================================
--  Arglist (harpoon like but not persistent)
-- =========================================================

vim.keymap.set("n", "<leader>ha", function()
  vim.cmd("$argadd %")
  vim.cmd("argdedup")
end)

vim.keymap.set("n", "<leader>he", function()
  local args = vim.fn.argv()
  local items = {}

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
end)

-- Arglist jump
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. tostring(i), function()
    vim.cmd("silent! " .. tostring(i) .. "argument")
  end)
end

-- =========================================================
--  Movement enhancements
-- =========================================================

vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- =========================================================
--  Visual indent
-- =========================================================

vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- =========================================================
--  Splits
-- =========================================================

vim.keymap.set("n", "-", "<C-W>s", { remap = true })
vim.keymap.set("n", "\\", "<C-W>v", { remap = true })

-- =========================================================
--  QOL improvements
-- =========================================================

vim.keymap.set({ "n", "v" }, "H", "^")
vim.keymap.set({ "n", "v" }, "L", "$")

vim.keymap.set("n", "<C-a>", "gg<S-v>G")
vim.keymap.set("n", "x", '"_x')

vim.keymap.set("v", "J", ":m '>+1<cr> | :normal gv=gv<cr>")
vim.keymap.set("v", "K", ":m '<-2<cr> | :normal gv=gv<cr>")

-- =========================================================
--  Disable some default mappings
-- =========================================================

vim.keymap.set({ "n", "x" }, "Q", "<nop>")
