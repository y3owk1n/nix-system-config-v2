---@type PluginModule
local M = {}

M.name = "custom.cmd"

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
    async_notifier = {
      -- adapter = plugin.builtins.spinner_adapters.mini,
      -- adapter = plugin.builtins.spinner_adapters.snacks,
      -- adapter = plugin.builtins.spinner_adapters.fidget,
      adapter = {
        start = function(msg, data)
          vim.notify(
            msg,
            "INFO",
            { id = string.format("cmd_progress_%s", data.command_id), title = "cmd", group = "important" }
          )
          return nil -- snacks uses the id internally
        end,

        update = function(_, msg, data)
          vim.notify(
            msg,
            "INFO",
            { id = string.format("cmd_progress_%s", data.command_id), title = "cmd", group = "important" }
          )
        end,

        finish = function(_, msg, level, data)
          vim.notify(msg, level, {
            id = string.format("cmd_progress_%s", data.command_id),
            title = "cmd",
            group = "important",
          })
        end,
      },
    },
  }

  plugin.setup(plugin_opts)
end

return M
