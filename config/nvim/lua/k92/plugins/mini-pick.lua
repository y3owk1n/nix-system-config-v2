---@type LazySpec
return {
  {
    "echasnovski/mini.pick",
    dependencies = { "echasnovski/mini.extra" },
    event = "VeryLazy",
    opts = {
      mappings = { choose_in_vsplit = "<C-v>", choose_in_split = "<C-s>" },
      window = {
        config = function()
          local height = math.floor(0.618 * vim.o.lines)
          local width = math.floor(0.618 * vim.o.columns)
          return {
            anchor = "NW",
            height = height,
            width = width,
            row = math.floor(0.5 * (vim.o.lines - height)),
            col = math.floor(0.5 * (vim.o.columns - width)),
          }
        end,
        prompt_prefix = " ",
      },
    },
    config = function(_, opts)
      require("mini.pick").setup(opts)

      vim.ui.select = require("mini.pick").ui_select
    end,
    keys = {
      {
        "<leader><space>",
        function()
          require("mini.pick").builtin.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>sf",
        function()
          require("mini.pick").builtin.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>sh",
        function()
          require("mini.pick").builtin.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>sg",
        function()
          require("mini.pick").builtin.grep_live()
        end,
        desc = "Grep",
      },
      {
        "<leader>sR",
        function()
          require("mini.pick").builtin.resume()
        end,
        desc = "Resume",
      },
      {
        "<leader>sb",
        function()
          require("mini.pick").builtin.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>st",
        function()
          local keywords = { "TODO", "FIXME", "HACK", "WARN", "PERF", "NOTE", "TEST", "BUG", "ISSUE" }
          local rg_pattern = [[\b(]] .. table.concat(keywords, "|") .. [[)\b:]]
          require("mini.pick").builtin.grep({ pattern = rg_pattern })
        end,
        desc = "Todo",
      },
      -- setting up extras
      {
        "<leader>gf",
        function()
          require("mini.extra").pickers.git_files({
            path = require("git-head").get_root(),
            scope = "modified",
          })
        end,
        desc = "Highlights",
      },
      {
        "<leader>sH",
        function()
          require("mini.extra").pickers.hl_groups()
        end,
        desc = "Highlights",
      },
      {
        "<leader>sk",
        function()
          require("mini.extra").pickers.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sd",
        function()
          require("mini.extra").pickers.diagnostic()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>so",
        function()
          require("mini.extra").pickers.options()
        end,
        desc = "Options",
      },
      -- LSP
      {
        "grd",
        function()
          require("mini.extra").pickers.lsp({ scope = "definition" })
        end,
        desc = "Goto Definition",
      },
      {
        "grr",
        function()
          require("mini.extra").pickers.lsp({ scope = "references" })
        end,
        desc = "References",
      },
      {
        "gri",
        function()
          require("mini.extra").pickers.lsp({ scope = "implementation" })
        end,
        desc = "Implementation",
      },
      {
        "grt",
        function()
          require("mini.extra").pickers.lsp({ scope = "type_definition" })
        end,
        desc = "Type Definition",
      },
      {
        "gO",
        function()
          require("mini.extra").pickers.lsp({ scope = "document_symbol" })
        end,
        desc = "Document Symbols",
      },
    },
  },
}
