---@type PluginModule
local M = {}

M.name = "render-markdown"

M.lazy = {
  ft = { "markdown", "markdown.mdx", "norg", "rmd", "org" },
}

function M.setup()
  vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })

  local plugin_ok, plugin = pcall(require, "render-markdown")

  if not plugin_ok then
    return
  end

  ---@type render.md.UserConfig
  local plugin_opts = {
    code = {
      sign = false,
      width = "block",
      right_pad = 1,
    },
    heading = {
      sign = false,
      icons = {},
    },
    checkbox = {
      enabled = false,
    },
  }

  plugin.setup(plugin_opts)
end

return M
