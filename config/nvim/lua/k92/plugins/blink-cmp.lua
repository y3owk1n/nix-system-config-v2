---@type LazySpec
return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    dependencies = "rafamadriz/friendly-snippets",
    version = "*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
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
        default = { "lsp", "path", "snippets", "buffer" },
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
    },
    -- allows extending the providers array elsewhere in your config
    -- without having to redefine it
    opts_extend = { "sources.default" },
  },
  {
    "catppuccin/nvim",
    optional = true,
    opts = function(_, opts)
      local colors = require("catppuccin.palettes").get_palette()

      local highlights = {
        BlinkCmpLabel = { fg = colors.overlay2 },
        BlinkCmpMenu = { fg = colors.text },
        BlinkCmpMenuBorder = { fg = colors.blue },
        BlinkCmpDoc = { fg = colors.overlay2 },
        BlinkCmpDocBorder = { fg = colors.blue },
        BlinkCmpSignatureHelpBorder = { fg = colors.blue },
      }

      opts.custom_highlights = opts.custom_highlights or {}

      for key, value in pairs(highlights) do
        opts.custom_highlights[key] = value
      end

      opts.integrations = {
        blink_cmp = {
          style = "bordered",
        },
      }
    end,
  },
}
