---@type PluginModule
local M = {}

M.name = "lint"

M.lazy = {
  event = { "BufReadPost", "InsertLeave" },
}

M.registry = {
  "https://github.com/mfussenegger/nvim-lint",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "lint")

  if not plugin_ok then
    return
  end

  plugin.linters_by_ft = {
    dockerfile = { "hadolint" },
    fish = { "fish" },
    go = { "golangcilint" },
    markdown = { "markdownlint-cli2" },
    ["markdown.mdx"] = { "markdownlint-cli2" },
  }

  local function try_linting()
    local linters = plugin.linters_by_ft[vim.bo.filetype]

    plugin.try_lint(linters)
  end

  local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = lint_augroup,
    callback = function()
      try_linting()
    end,
  })
end

return M
