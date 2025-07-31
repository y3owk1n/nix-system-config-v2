---@type PluginModule
local M = {}

M.name = "dotmd"

M.lazy = {
  cmd = {
    "DotMdCreateNote",
    "DotMdCreateTodoToday",
    "DotMdInbox",
    "DotMdCreateJournal",
    "DotMdNavigate",
    "DotMdOpen",
    "DotMdPick",
  },
  keys = {
    "<leader>nc",
    "<leader>nt",
    "<leader>ni",
    "<leader>nj",
    "<leader>np",
    "<leader>nn",
    "<leader>no",
    "<leader>sna",
    "<leader>snA",
    "<leader>snn",
    "<leader>snN",
    "<leader>snt",
    "<leader>snT",
    "<leader>snj",
  },
}

M.registry = {
  "https://github.com/y3owk1n/dotmd.nvim",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "dotmd")

  if not plugin_ok then
    return
  end

  ---@type DotMd.Config
  local plugin_opts = {
    root_dir = "/Users/kylewong/Library/Mobile Documents/com~apple~CloudDocs/Cloud Notes",
    -- root_dir = "~/dotmd",
    default_split = "vertical",
    rollover_todo = {
      enabled = true,
    },
    picker = "mini",
  }

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>n", "", { desc = "dotmd" })
  vim.keymap.set("n", "<leader>nc", "<cmd>DotMdCreateNote<cr>", { desc = "[DotMd] Create new note" })
  vim.keymap.set("n", "<leader>nt", "<cmd>DotMdCreateTodoToday<cr>", { desc = "[DotMd] Create todo for today" })
  vim.keymap.set("n", "<leader>ni", "<cmd>DotMdInbox<cr>", { desc = "[DotMd] Inbox" })
  vim.keymap.set("n", "<leader>nj", "<cmd>DotMdCreateJournal<cr>", { desc = "[DotMd] Create journal" })
  vim.keymap.set("n", "<leader>np", "<cmd>DotMdNavigate previous<cr>", { desc = "[DotMd] Navigate to previous todo" })
  vim.keymap.set("n", "<leader>nn", "<cmd>DotMdNavigate next<cr>", { desc = "[DotMd] Navigate to next todo" })
  vim.keymap.set("n", "<leader>no", "<cmd>DotMdOpen<cr>", { desc = "[DotMd] Open" })
  vim.keymap.set("n", "<leader>sn", "", { desc = "dotmd" })
  vim.keymap.set("n", "<leader>sna", "<cmd>DotMdPick<cr>", { desc = "[DotMd] Search everything" })
  vim.keymap.set("n", "<leader>snA", "<cmd>DotMdPick grep<cr>", { desc = "[DotMd] Search everything grep" })
  vim.keymap.set("n", "<leader>snn", "<cmd>DotMdPick notes<cr>", { desc = "[DotMd] Search notes" })
  vim.keymap.set("n", "<leader>snN", "<cmd>DotMdPick notes grep<cr>", { desc = "[DotMd] Search notes grep" })
  vim.keymap.set("n", "<leader>snt", "<cmd>DotMdPick todos<cr>", { desc = "[DotMd] Search todos" })
  vim.keymap.set("n", "<leader>snT", "<cmd>DotMdPick todos grep<cr>", { desc = "[DotMd] Search todos grep" })
  vim.keymap.set("n", "<leader>snj", "<cmd>DotMdPick journals<cr>", { desc = "[DotMd] Search journal" })
end

return M
