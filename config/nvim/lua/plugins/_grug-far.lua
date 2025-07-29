---@type PluginModule
local M = {}

M.lazy = {
  cmd = { "GrugFar", "GrugFarWithin" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "grug-far")

  if not plugin_ok then
    return
  end

  ---@type grug.far.OptionsOverride
  local plugin_opts = {}

  plugin.setup(plugin_opts)

  --- setting keymaps
  vim.keymap.set("n", "<leader>sr", function()
    local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
    plugin.open({
      transient = true,
      prefills = {
        filesFilter = ext and ext ~= "" and "*." .. ext or nil,
      },
    })
  end, { desc = "Search and Replace" })

  vim.keymap.set("x", "<leader>sr", function()
    plugin.open({
      visualSelectionUsage = "operate-within-range",
    })
  end, { desc = "Search and Replace Within" })
end

return M
