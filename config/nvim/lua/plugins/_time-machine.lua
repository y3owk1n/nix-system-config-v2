---@type PluginModule
local M = {}

M.name = "time-machine"

M.lazy = {
  cmd = {
    "TimeMachineToggle",
    "TimeMachinePurgeBuffer",
    "TimeMachinePurgeAll",
    "TimeMachineLogShow",
  },
  keys = {
    "<leader>tt",
    "<leader>tx",
    "<leader>tX",
    "<leader>tl",
  },
}

M.registry = {
  "https://github.com/y3owk1n/time-machine.nvim",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "time-machine")

  if not plugin_ok then
    return
  end

  ---@type TimeMachine.Config
  local plugin_opts = {
    diff_tool = "difft",
    keymaps = {
      redo = "U",
    },
  }

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>t", "", { desc = "time machine" })
  vim.keymap.set("n", "<leader>tt", "<cmd>TimeMachineToggle<cr>", { desc = "[Time Machine] Toggle Tree" })
  vim.keymap.set("n", "<leader>tx", "<cmd>TimeMachinePurgeBuffer<cr>", { desc = "[Time Machine] Purge current" })
  vim.keymap.set("n", "<leader>tX", "<cmd>TimeMachinePurgeAll<cr>", { desc = "[Time Machine] Purge all" })
  vim.keymap.set("n", "<leader>tl", "<cmd>TimeMachineLogShow<cr>", { desc = "[Time Machine] Show log" })
end

return M
