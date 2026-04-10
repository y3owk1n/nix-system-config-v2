local M = {}

---@type boolean
local did_setup = false

local function setup_diagnostics()
  vim.diagnostic.config({
    underline = true,
    update_in_insert = false,
    virtual_text = {
      prefix = "",
      suffix = "",
      format = function(diagnostic)
        local icon = vim.diagnostic.config().signs.text[diagnostic.severity]
        if icon then
          return string.format("%s %s ", icon, diagnostic.message)
        else
          return diagnostic.message
        end
      end,
    },
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = " ",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.INFO] = " ",
        [vim.diagnostic.severity.HINT] = " ",
      },
      numhl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
      },
    },
    float = {
      source = true,
      severity_sort = true,
    },
  })
end

function M.setup()
  if did_setup then
    return
  end

  setup_diagnostics()

  did_setup = true
end

return M
