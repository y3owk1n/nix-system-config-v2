---@type PluginModule
local M = {}

M.name = "custom.markdown-utils"

M.lazy = {
  ft = "markdown",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.markdown-utils")

  if not plugin_ok then
    return
  end

  ---@type MarkdownUtils.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("toggle_markdown_checkbox", { clear = true }),
    pattern = { "markdown" },
    callback = function()
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
    end,
  })
end

return M
