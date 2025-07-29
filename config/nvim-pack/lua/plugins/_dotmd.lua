---@type PluginModule
local M = {}

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
  vim.keymap.set("n", "<leader>nc", function()
    plugin.create_note()
  end, { desc = "[DotMd] Create new note" })
  vim.keymap.set("n", "<leader>nt", function()
    plugin.create_todo_today()
  end, { desc = "[DotMd] Create todo for today" })
  vim.keymap.set("n", "<leader>ni", function()
    plugin.inbox()
  end, { desc = "[DotMd] Inbox" })
  vim.keymap.set("n", "<leader>nj", function()
    plugin.create_journal()
  end, { desc = "[DotMd] Create journal" })
  vim.keymap.set("n", "<leader>np", function()
    plugin.navigate("previous")
  end, { desc = "[DotMd] Navigate to previous todo" })
  vim.keymap.set("n", "<leader>nn", function()
    plugin.navigate("next")
  end, { desc = "[DotMd] Navigate to next todo" })
  vim.keymap.set("n", "<leader>no", function()
    plugin.open({ pluralise_query = true })
  end, { desc = "[DotMd] Open" })
  vim.keymap.set("n", "<leader>sn", "", { desc = "dotmd" })
  vim.keymap.set("n", "<leader>sna", function()
    plugin.pick()
  end, { desc = "[DotMd] Search everything" })
  vim.keymap.set("n", "<leader>snA", function()
    plugin.pick({ grep = true })
  end, { desc = "[DotMd] Search everything grep" })
  vim.keymap.set("n", "<leader>snn", function()
    plugin.pick({
      type = "notes",
    })
  end, { desc = "[DotMd] Search notes" })
  vim.keymap.set("n", "<leader>snN", function()
    plugin.pick({
      type = "notes",
      grep = true,
    })
  end, { desc = "[DotMd] Search notes grep" })
  vim.keymap.set("n", "<leader>snt", function()
    plugin.pick({
      type = "todos",
    })
  end, { desc = "[DotMd] Search todos" })
  vim.keymap.set("n", "<leader>snT", function()
    plugin.pick({
      type = "todos",
      grep = true,
    })
  end, { desc = "[DotMd] Search todos grep" })
  vim.keymap.set("n", "<leader>snj", function()
    plugin.pick({
      type = "journals",
    })
  end, { desc = "[DotMd] Search journal" })
  vim.keymap.set("n", "<leader>snJ", function()
    plugin.pick({
      type = "journals",
      grep = true,
    })
  end, { desc = "[DotMd] Search journal grep" })
end

return M
