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
      pattern = { "markdown" },
      callback = function()
        vim.keymap.set(
          "n",
          "<leader>cc",
          plugin.toggle_markdown_checkbox,
          { buffer = true, desc = "Toggle markdown checkbox" }
        )
        vim.keymap.set(
          "n",
          "<leader>cgC",
          plugin.insert_markdown_checkbox,
          { buffer = true, desc = "Insert markdown checkbox" }
        )
        vim.keymap.set(
          "n",
          "<leader>cgc",
          plugin.insert_markdown_checkbox_below,
          { buffer = true, desc = "Insert checkbox below" }
        )
      end,
    })
  end,
}
