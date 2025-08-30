---@type PluginModule
local M = {}

M.name = "lsp-rename"

M.lazy = {
  keys = {
    "<leader>cr",
  },
}

M.registry = {
  { src = vim.fn.stdpath("config") .. "/lua/custom-plugins/lsp-rename", name = "lsp-rename" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "lsp-rename")

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
