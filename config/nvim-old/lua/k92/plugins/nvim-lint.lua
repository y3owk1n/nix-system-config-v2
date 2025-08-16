---@type LazySpec
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "InsertLeave" },
  config = function()
    local plugin = require("lint")

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
  end,
}
