---@type PluginModule
local M = {}

M.name = "custom.markdown-utils"

M.lazy = {
  ft = { "markdown", "markdown.mdx", "norg", "rmd", "org" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.markdown-utils")

  if not plugin_ok then
    return
  end

  ---@type MarkdownUtils.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)

  -- Set keymaps immediately since we're already in the right filetype
  vim.keymap.set(
    "n",
    "<leader>cc",
    plugin.toggle_markdown_checkbox,
    { buffer = true, desc = "Toggle markdown checkbox" }
  )
  vim.keymap.set(
    "n",
    "<leader>cgC",
    plugin.insert_markdown_checkbox,
    { buffer = true, desc = "Insert markdown checkbox" }
  )
  vim.keymap.set(
    "n",
    "<leader>cgc",
    plugin.insert_markdown_checkbox_below,
    { buffer = true, desc = "Insert checkbox below" }
  )
end

return M
