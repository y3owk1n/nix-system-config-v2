-- =========================================================
--  File explorer
-- =========================================================

vim.keymap.set("n", "<leader>e", function()
  if vim.bo.filetype == "directory" then
    local prev = vim.w.dir_prev_buf
    if prev and vim.api.nvim_buf_is_valid(prev) then
      vim.api.nvim_set_current_buf(prev)
    end
  else
    vim.w.dir_prev_buf = vim.api.nvim_get_current_buf()
    if vim.fn.maparg("-", "n") ~= "" then
      vim.cmd("normal -")
    else
      vim.cmd("e $PWD")
    end
  end
end, { desc = "Explorer" })

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
--  QOL improvements
-- =========================================================

vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Move cursor to most left" })
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Move cursor to most right" })

vim.keymap.set("n", "x", '"_x', { desc = "Delete the character under the cursor without putting it in the register" })

vim.keymap.set("v", "J", ":m '>+1<cr> | :normal gv=gv<cr>", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<cr> | :normal gv=gv<cr>", { desc = "Move line up" })

-- =========================================================
--  Disable some default mappings
-- =========================================================

vim.keymap.set({ "n", "x" }, "Q", "<nop>")
