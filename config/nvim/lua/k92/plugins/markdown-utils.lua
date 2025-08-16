local custom_name = "markdown-utils"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  name = custom_name,
  ft = "markdown",
  ---@type MarkdownUtils.Config
  opts = {},
  config = function(_, opts)
    local plugin = require(custom_name)
    plugin.setup(opts)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("toggle_markdown_checkbox", { clear = true }),
      pattern = "markdown",
      callback = function()
        vim.keymap.set(
          "n",
          "<leader>cc",
          plugin.toggle_markdown_checkbox,
          { desc = "Toggle Markdown Checkbox", silent = true, buffer = 0 }
        )

        vim.keymap.set(
          "n",
          "<leader>cgc",
          plugin.insert_markdown_checkbox,
          { desc = "Insert Markdown Checkbox", silent = true, buffer = 0 }
        )
      end,
    })
  end,
}
