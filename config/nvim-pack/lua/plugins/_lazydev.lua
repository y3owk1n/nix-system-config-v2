---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "lazydev")

  if not plugin_ok then
    return
  end

  plugin.setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      { path = "lazy.nvim", words = { "Lazy" } },
    },
  })
end

return M
