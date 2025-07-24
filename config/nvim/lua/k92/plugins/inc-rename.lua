---@type LazySpec
return {
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    ---@module "inc_rename"
    ---@type inc_rename.UserConfig
    opts = {},
    keys = {
      {
        "grn",
        function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end,
        mode = "n",
        desc = "Rename word",
        expr = true,
      },
    },
  },
}
