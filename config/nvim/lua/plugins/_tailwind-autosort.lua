---@type PluginModule
local M = {}

M.requires = { "_nvim-treesitter" }

M.lazy = {
  on_lsp_attach = { "tailwindcss" },
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
