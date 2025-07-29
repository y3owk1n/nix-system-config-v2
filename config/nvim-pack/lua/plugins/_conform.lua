---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "conform")

  if not plugin_ok then
    return
  end

  local formatters = {}

  local formatters_by_ft = {
    sh = { "shfmt" },
    fish = { "fish_indent" },
  }

  plugin.setup({
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
  })

  vim.keymap.set("n", "<leader>cf", function()
    plugin.format({
      async = true,
      lsp_format = "fallback",
    })
  end, { desc = "Format buffer" })

  vim.keymap.set("n", "<leader>ic", "<cmd>ConformInfo<cr>", { desc = "Format buffer" })
end

return M
