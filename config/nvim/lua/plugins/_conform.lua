---@type PluginModule
local M = {}

M.name = "conform"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
  keys = { "<leader>cf", "<leader>ic" },
}

function M.setup()
  vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

  local plugin_ok, plugin = pcall(require, "conform")

  if not plugin_ok then
    return
  end

  local formatters = {
    biome = {
      require_cwd = true,
    },
    ["markdownlint-cli2"] = {
      condition = function(_, ctx)
        local diag = vim.tbl_filter(function(d)
          return d.source == "markdownlint"
        end, vim.diagnostic.get(ctx.buf))
        return #diag > 0
      end,
    },
  }

  local formatters_by_ft = {
    sh = { "shfmt" },
    fish = { "fish_indent" },
    javascript = { "biome", "prettierd", stop_after_first = true },
    javascriptreact = { "biome", "prettierd", stop_after_first = true },
    typescript = { "biome", "prettierd", stop_after_first = true },
    typescriptreact = { "biome", "prettierd", stop_after_first = true },
    json = { "biome", "prettierd", stop_after_first = true },
    jsonc = { "biome", "prettierd", stop_after_first = true },
    css = { "biome", "prettierd", stop_after_first = true },
    ["markdown"] = { "prettierd", "markdownlint-cli2" },
    ["markdown.mdx"] = { "prettierd", "markdownlint-cli2" },
    go = { "goimports", "gofumpt" },
    just = { "just" },
    lua = { "stylua" },
    nix = { "nixfmt" },
  }

  ---@type conform.setupOpts
  local plugin_opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true }
      local lsp_format_opt
      if disable_filetypes[vim.bo[bufnr].filetype] then
        lsp_format_opt = "never"
      else
        lsp_format_opt = "fallback"
      end
      return {
        timeout_ms = 1000,
        lsp_format = lsp_format_opt,
      }
    end,
    formatters = formatters,
    formatters_by_ft = formatters_by_ft,
  }

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>cf", function()
    plugin.format({
      async = true,
      lsp_format = "fallback",
    })
  end, { desc = "Format buffer" })

  vim.keymap.set("n", "<leader>ic", "<cmd>ConformInfo<cr>", { desc = "Show conform info" })
end

return M
