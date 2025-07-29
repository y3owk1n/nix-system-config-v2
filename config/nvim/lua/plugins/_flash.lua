---@type PluginModule
local M = {}

M.lazy = {
  event = { "BufReadPost", "BufNewFile" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "flash")

  if not plugin_ok then
    return
  end

  ---@type Flash.Config
  local plugin_opts = {
    prompt = {
      enabled = false,
    },
  }

  plugin.setup(plugin_opts)

  vim.keymap.set({ "n", "x", "o" }, "s", function()
    plugin.jump()
  end, { desc = "Flash" })
end

return M
