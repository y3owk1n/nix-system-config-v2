---@type LazySpec
return {
  --- general snacks
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = {
        enabled = true,
      },
      input = {
        enabled = true,
      },
    },
    init = function()
      local augroup = require("k92.utils.autocmds").augroup

      vim.api.nvim_create_autocmd("User", {
        group = augroup("snacks_init"),
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Create some toggle mappings
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.line_number():map("<leader>ul")
          Snacks.toggle
            .option("conceallevel", {
              off = 0,
              on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
            })
            :map("<leader>uc")
          Snacks.toggle.inlay_hints():map("<leader>uh")
          Snacks.toggle.option("foldenable", { name = "Fold" }):map("<leader>uf")
        end,
      })
    end,
  },
  --- notifier
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      notifier = {
        enabled = true,
        timeout = 3000,
      },
    },
    keys = {
      {
        "<leader>N",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification History",
      },
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
      },
    },
  },
  --- rename file
  {
    "folke/snacks.nvim",
    opts = {},
    keys = {
      {
        "<leader>cr",
        function()
          Snacks.rename.rename_file({
            on_rename = function(to, from)
              require("warp").on_file_update(from, to)
            end,
          })
        end,
        desc = "Rename File",
      },
    },
  },
  --- git
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      lazygit = {
        configure = false,
        config = {
          os = { editPreset = "nvim-remote" },
        },
      },
    },
    keys = {
      {
        "<leader>gb",
        function()
          Snacks.gitbrowse()
        end,
        desc = "Git Browse",
        mode = { "n", "v" },
      },
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
    },
  },
  {
    "catppuccin/nvim",
    optional = true,
    opts = {
      integrations = {
        snacks = {
          enabled = true,
        },
      },
    },
  },
}
