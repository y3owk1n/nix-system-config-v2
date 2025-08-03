---@type PluginModule
local M = {}

M.name = "custom.cmd"

M.lazy = {
  cmd = {
    "Cmd",
  },
  event = {
    "CmdlineEnter",
  },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.cmd")

  if not plugin_ok then
    return
  end

  ---@type Cmd.Config
  local plugin_opts = {
    create_usercmd = {
      gh = "Gh",
      git = "Git",
    },
    force_terminal = {
      git = {
        "-p",
        "commit",
      },
      gh = {
        "create",
        "--watch",
      },
    },
    env = {
      -- gh = {
      --   "GH_PAGER=cat",
      -- },
    },
  }

  plugin.setup(plugin_opts)
end

return M
