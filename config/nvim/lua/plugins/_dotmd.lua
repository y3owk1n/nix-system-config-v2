---@type PluginModule
local M = {}

M.lazy = {
  cmd = {
    "DotMdCreateNote",
    "DotMdCreateTodoToday",
    "DotMdCreateJournal",
    "DotMdInbox",
    "DotMdNavigate",
    "DotMdPick",
    "DotMdOpen",
  },
  keys = {
    { lhs = "<leader>n", rhs = "", opts = { desc = "dotmd" } },
    { lhs = "<leader>nc", rhs = "<cmd>DotMdCreateNote<cr>", opts = { desc = "[DotMd] Create new note" } },
    { lhs = "<leader>nt", rhs = "<cmd>DotMdCreateTodoToday<cr>", opts = { desc = "[DotMd] Create todo for today" } },
    { lhs = "<leader>ni", rhs = "<cmd>DotMdInbox<cr>", opts = { desc = "[DotMd] Inbox" } },
    { lhs = "<leader>nj", rhs = "<cmd>DotMdCreateJournal<cr>", opts = { desc = "[DotMd] Create journal" } },
    {
      lhs = "<leader>np",
      rhs = "<cmd>DotMdNavigate previous<cr>",
      opts = { desc = "[DotMd] Navigate to previous todo" },
    },
    { lhs = "<leader>nn", rhs = "<cmd>DotMdNavigate next<cr>", opts = { desc = "[DotMd] Navigate to next todo" } },
    { lhs = "<leader>no", rhs = "<cmd>DotMdOpen<cr>", opts = { desc = "[DotMd] Open" } },
    { lhs = "<leader>sn", rhs = "", opts = { desc = "dotmd" } },
    { lhs = "<leader>sna", rhs = "<cmd>DotMdPick<cr>", opts = { desc = "[DotMd] Search everything" } },
    { lhs = "<leader>snA", rhs = "<cmd>DotMdPick grep<cr>", opts = { desc = "[DotMd] Search everything grep" } },
    { lhs = "<leader>snn", rhs = "<cmd>DotMdPick notes<cr>", opts = { desc = "[DotMd] Search notes" } },
    { lhs = "<leader>snN", rhs = "<cmd>DotMdPick notes grep<cr>", opts = { desc = "[DotMd] Search notes grep" } },
    { lhs = "<leader>snt", rhs = "<cmd>DotMdPick todos<cr>", opts = { desc = "[DotMd] Search todos" } },
    { lhs = "<leader>snT", rhs = "<cmd>DotMdPick todos grep<cr>", opts = { desc = "[DotMd] Search todos grep" } },
    { lhs = "<leader>snj", rhs = "<cmd>DotMdPick journals<cr>", opts = { desc = "[DotMd] Search journal" } },
    { lhs = "<leader>snJ", rhs = "<cmd>DotMdPick journals grep<cr>", opts = { desc = "[DotMd] Search journal grep" } },
  },
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
end

return M
