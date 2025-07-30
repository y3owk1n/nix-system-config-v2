---@type PluginModule
local M = {}

M.name = "blink.cmp"

M.requires = { "lazydev", "mini.icons" }

M.lazy = { event = "InsertEnter" }

function M.setup()
  vim.pack.add({
    { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("*") },
    { src = "https://github.com/rafamadriz/friendly-snippets" },
  })

  local plugin_ok, plugin = pcall(require, "blink.cmp")

  if not plugin_ok then
    return
  end

  ---@type blink.cmp.Config
  local plugin_opts = {
    keymap = {
      preset = "none",
      ["<CR>"] = { "select_and_accept", "fallback" },
      ["<C-n>"] = {
        "show",
        "select_next",
        "fallback",
      },
      ["<C-p>"] = {
        "show",
        "select_prev",
        "fallback",
      },
      ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      ["<C-d>"] = { "scroll_documentation_down", "fallback" },
    },

    appearance = {
      nerd_font_variant = "mono",
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer", "lazydev" },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100, -- show at a higher priority than lsp
        },
      },
    },
    cmdline = {
      enabled = false,
    },
    completion = {
      list = {
        selection = {
          preselect = false,
        },
      },
      menu = {
        draw = {
          treesitter = { "lsp" },
          components = {
            kind_icon = {
              text = function(ctx)
                local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                return kind_icon
              end,
              -- (optional) use highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
            kind = {
              -- (optional) use highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
          },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      },
    },

    signature = {
      enabled = true,
    },
  }

  plugin.setup(plugin_opts)
end

return M
