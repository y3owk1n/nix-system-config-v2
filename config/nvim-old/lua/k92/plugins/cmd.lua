---@type LazySpec
return {
  "y3owk1n/cmd.nvim",
  event = { "CmdlineEnter" },
  cmd = { "Cmd", "CmdCancel", "CmdHistory", "CmdRerun" },
  ---@type Cmd.Config
  opts = {
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
      adapter = nil,
    },
  },
  config = function(_, opts)
    opts.progress_notifier.adapter = require("cmd").builtins.spinner_adapters.notifier

    require("cmd").setup(opts)
  end,
}
