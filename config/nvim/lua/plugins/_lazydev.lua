---@type PluginModule
local M = {}

M.lazy = {
  ft = "lua",
  cmd = "LazyDev",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "lazydev")

  if not plugin_ok then
    return
  end

  ---@type lazydev.Config
  local plugin_opts = {
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      { path = "lazy.nvim", words = { "Lazy" } },
    },
  }

  plugin.setup(plugin_opts)
end

return M
