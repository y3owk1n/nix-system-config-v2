---@type PluginModule
local M = {}

M.name = "custom.cmd"

M.lazy = {
  cmd = {
    "Cmd",
  },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.cmd")

  if not plugin_ok then
    return
  end

  ---@type Cmd.Config
  local plugin_opts = {
    force_terminal = {
      git = {
        "-p",
      },
      gh = {
        "create",
        "--watch",
      },
    },
  }

  plugin.setup(plugin_opts)
end

return M
