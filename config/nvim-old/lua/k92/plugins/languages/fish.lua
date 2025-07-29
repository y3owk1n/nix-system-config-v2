if not vim.g.has_fish then
  return {}
end

---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "fish" } },
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      if vim.fn.executable("fish_indent") == 1 then
        opts.formatters_by_ft.fish = opts.formatters_by_ft.fish or {}
        opts.formatters_by_ft.fish = { "fish_indent" }
      end
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        fish = { "fish" },
      },
    },
  },
}
