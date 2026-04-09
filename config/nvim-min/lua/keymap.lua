-- =========================================================
--  File explorer with mini.files
-- =========================================================
vim.keymap.set("n", "<leader>e", function()
  if not require("mini.files").close() then
    local buf_path = vim.api.nvim_buf_get_name(0)
    if buf_path == "" or not vim.uv.fs_stat(buf_path) then
      buf_path = vim.uv.cwd() or ""
    end
    require("mini.files").open(buf_path, true)
  end
end, { desc = "Explorer (buffer path)" })

vim.keymap.set("n", "<leader>E", function()
  if not require("mini.files").close() then
    require("mini.files").open(vim.uv.cwd(), true)
  end
end, { desc = "Explorer (cwd)" })

-- =========================================================
--  Toggle git diffs with mini.diff
-- =========================================================

vim.keymap.set("n", "<leader>gd", function()
  require("mini.diff").toggle_overlay(0)
end, { desc = "Toggle diff overlay" })

-- =========================================================
--  Restart
-- =========================================================

vim.keymap.set("n", "<leader>R", function()
  require("custom.restart").save_restart()
end, { desc = "Save and restart" })

-- =========================================================
--  Markdown utils
-- =========================================================

vim.keymap.set(
  "n",
  "<leader>cc",
  require("custom.markdown-utils").toggle_markdown_checkbox,
  { desc = "Toggle markdown checkbox" }
)

vim.keymap.set(
  "n",
  "<leader>cgC",
  require("custom.markdown-utils").insert_markdown_checkbox,
  { desc = "Insert markdown checkbox" }
)

vim.keymap.set(
  "n",
  "<leader>cgc",
  require("custom.markdown-utils").insert_markdown_checkbox_below,
  { desc = "Insert checkbox below" }
)

-- =========================================================
--  Update vim.pack
-- =========================================================
vim.keymap.set("n", "<leader>pu", function()
  vim.pack.update(nil, { target = "lockfile" })
end, { desc = "Pack update" })

-- =========================================================
--  Tmux navigation
-- =========================================================
vim.keymap.set("n", "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>", { desc = "Navigate left" })
vim.keymap.set("n", "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>", { desc = "Navigate down" })
vim.keymap.set("n", "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>", { desc = "Navigate up" })
vim.keymap.set("n", "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>", { desc = "Navigate right" })

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
--  Help
-- =========================================================
vim.keymap.set("n", "<leader>sh", ":help<space>", { desc = "Fuzzy find help" })

-- =========================================================
--  Fuzzy finder
-- =========================================================
vim.keymap.set("n", "<leader><leader>", ":find<space>", { desc = "Fuzzy find files" })

vim.keymap.set("n", "<leader>sf", require("custom.fuzzy-search").files, { desc = "Files fuzzy" })
vim.keymap.set("n", "<leader>sg", require("custom.fuzzy-search").grep, { desc = "Grep text" })
vim.keymap.set("n", "<leader>sw", function()
  require("custom.fuzzy-search").grep(vim.fn.expand("<cword>"))
end, { desc = "Grep word" })
vim.keymap.set("n", "<leader>sr", require("custom.fuzzy-search").grep_last, { desc = "Grep repeat" })
vim.keymap.set("n", "<leader>st", function()
  require("custom.fuzzy-search").grep({ "TODO", "FIXME", "HACK" })
end, { desc = "Grep TODOs" })

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
