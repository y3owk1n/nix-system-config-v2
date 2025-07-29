---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "flash")

  if not plugin_ok then
    return
  end

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
