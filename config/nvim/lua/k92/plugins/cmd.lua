---@type LazySpec
return {
  "y3owk1n/cmd.nvim",
  enabled = false,
  event = { "CmdlineEnter" },
  cmd = { "Cmd", "CmdCancel", "CmdHistory", "CmdRerun" },
  opts = function()
    local plugin = require("cmd")

    ---@type Cmd.Config
    local opts = {
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
        adapter = plugin.builtins.spinner_adapters.notifier,
      },
    }

    return opts
  end,
}
