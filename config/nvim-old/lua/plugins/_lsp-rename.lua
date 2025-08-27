---@type PluginModule
local M = {}

M.name = "custom.lsp-rename"

M.lazy = {
  keys = {
    "<leader>cr",
  },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.lsp-rename")

  if not plugin_ok then
    return
  end

  ---@type LspRename.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>cr", function()
    plugin.rename_file({
      on_rename = function(to, from)
        require("warp").on_file_update(from, to)
      end,
    })
  end, { desc = "Rename file" })
end

return M
