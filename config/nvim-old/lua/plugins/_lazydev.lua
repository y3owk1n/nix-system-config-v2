---@type PluginModule
local M = {}

M.name = "lazydev"

M.lazy = {
  ft = "lua",
  cmd = "LazyDev",
}

M.registry = {
  { src = "https://github.com/folke/lazydev.nvim", name = "lazydev" },
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
    },
  }

  plugin.setup(plugin_opts)
end

return M
