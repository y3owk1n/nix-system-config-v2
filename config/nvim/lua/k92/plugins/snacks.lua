---@type LazySpec
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  keys = {
    -- rename file
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
    -- git setups
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
    lazygit = {
      configure = false,
      config = {
        os = { editPreset = "nvim-remote" },
      },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("snacks_init", { clear = true }),
      pattern = "VeryLazy",
      callback = function()
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
}
