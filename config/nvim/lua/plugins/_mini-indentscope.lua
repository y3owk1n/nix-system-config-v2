---@type PluginModule
local M = {}

M.name = "mini.indentscope"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.indentscope")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    symbol = "│",
    draw = {
      animation = plugin.gen_animation.none(),
    },
    options = { indent_at_cursor = true, try_as_border = true },
  }

  plugin.setup(plugin_opts)

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "Trouble", "mason", "time-machine-list", "float_info", "checkhealth" },
    callback = function()
      vim.b.miniindentscope_disable = true
    end,
  })
end

return M
