---@type PluginModule
local M = {}

M.name = "cmd"

M.lazy = {
  cmd = {
    "Cmd",
    "CmdCancel",
    "CmdHistory",
    "CmdRerun",
  },
  event = {
    "CmdlineEnter",
  },
}

M.registry = {
  "https://github.com/y3owk1n/cmd.nvim",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "cmd")

  if not plugin_ok then
    return
  end

  ---@type Cmd.Config
  local plugin_opts = {
    create_usercmd = {
      gh = "Gh",
      git = "Git",
      just = "Just",
      nix = "Nix",
    },
    force_terminal = {
      git = {
        "add -p",
        "commit",
      },
      gh = {
        "pr create",
        "checks --watch",
      },
      just = {
        "rebuild",
        "update",
      },
      nix = { "flake update" },
    },
    env = {
      -- gh = {
      --   "GH_PAGER=cat",
      -- },
    },
    completion = {
      enabled = true,
      prompt_pattern_to_remove = "^",
    },
    progress_notifier = {
      -- adapter = plugin.builtins.spinner_adapters.mini,
      -- adapter = plugin.builtins.spinner_adapters.snacks,
      -- adapter = plugin.builtins.spinner_adapters.fidget,
      adapter = plugin.builtins.spinner_adapters.notifier,
    },
  }

  plugin.setup(plugin_opts)
end

return M
