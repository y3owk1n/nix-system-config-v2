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
        start = function(_, data)
          vim.notify("", vim.log.levels.INFO, {
            id = string.format("cmd_progress_%s", data.command_id),
            title = "cmd",
            group_name = "bottom-left",
            icon = " ",
            _notif_formatter = function(opts)
              local notif = opts.notif
              local _notif_formatter_data = notif._notif_formatter_data

              if not _notif_formatter_data then
                return {}
              end

              local separator = { text = " " }

              local icon = notif.icon or opts.config.icons[notif.level]
              local icon_hl = notif.hl_group or opts.log_level_map[notif.level].hl_group

              local id_text = string.format("#%s", _notif_formatter_data.command_id)

              return {
                icon and { text = icon, hl_group = icon_hl },
                icon and separator,
                { text = id_text, hl_group = "CmdHistoryIdentifier" },
                separator,
                { text = "running", hl_group = icon_hl },
                separator,
                { text = _notif_formatter_data.args, hl_group = "Comment" },
              }
            end,
            _notif_formatter_data = data,
          })
          return nil -- snacks uses the id internally
        end,

        update = function(_, _, data)
          vim.notify("", vim.log.levels.INFO, {
            id = string.format("cmd_progress_%s", data.command_id),
            title = "cmd",
            group_name = "bottom-left",
            icon = data.current_spinner_char,
            _notif_formatter = function(opts)
              local notif = opts.notif
              local _notif_formatter_data = notif._notif_formatter_data

              if not _notif_formatter_data then
                return {}
              end

              local separator = { text = " " }

              local icon = notif.icon or opts.config.icons[notif.level]
              local icon_hl = notif.hl_group or opts.log_level_map[notif.level].hl_group

              local id_text = string.format("#%s", _notif_formatter_data.command_id)

              return {
                icon and { text = icon, hl_group = icon_hl },
                icon and separator,
                { text = id_text, hl_group = "CmdHistoryIdentifier" },
                separator,
                { text = "running", hl_group = icon_hl },
                separator,
                { text = _notif_formatter_data.args, hl_group = "Comment" },
              }
            end,
            _notif_formatter_data = data,
          })
        end,

        finish = function(_, _, level, data)
          ---@type table<Cmd.CommandStatus, string>
          local icon_map = {
            success = " ",
            failed = " ",
            cancelled = " ",
          }

          local icon = icon_map[data.status]

          vim.notify("", vim.log.levels[level], {
            id = string.format("cmd_progress_%s", data.command_id),
            title = "cmd",
            group_name = "bottom-left",
            icon = icon,
            _notif_formatter = function(opts)
              local notif = opts.notif
              local _notif_formatter_data = notif._notif_formatter_data

              if not _notif_formatter_data then
                return {}
              end

              local separator = { text = " " }

              local _icon = notif.icon or opts.config.icons[notif.level]
              local icon_hl = notif.hl_group or opts.log_level_map[notif.level].hl_group

              local id_text = string.format("#%s", _notif_formatter_data.command_id)

              return {
                icon and { text = _icon, hl_group = icon_hl },
                icon and separator,
                { text = id_text, hl_group = "CmdHistoryIdentifier" },
                separator,
                { text = _notif_formatter_data.status, hl_group = icon_hl },
                separator,
                { text = _notif_formatter_data.args, hl_group = "Comment" },
              }
            end,
            _notif_formatter_data = data,
          })
        end,
      },
    },
  }

  plugin.setup(plugin_opts)
end

return M
