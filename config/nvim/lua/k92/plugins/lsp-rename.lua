local custom_name = "lsp-rename"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  name = custom_name,
  keys = {
    {
      "<leader>cr",
      function()
        require(custom_name).rename_file({
          on_rename = function(to, from)
            require("warp").on_file_update(from, to)
          end,
        })
      end,
      desc = "Rename File",
    },
  },
  ---@type LspRename.Config
  opts = {},
}
