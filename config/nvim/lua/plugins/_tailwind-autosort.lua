---@type PluginModule
local M = {}

M.name = "tailwind-autosort"

M.requires = { "nvim-treesitter" }

M.lazy = {
  on_lsp_attach = { "tailwindcss" },
}

M.registry = {
  "https://github.com/y3owk1n/tailwind-autosort.nvim",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "tailwind-autosort")

  if not plugin_ok then
    return
  end

  ---@type TailwindAutoSort.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
