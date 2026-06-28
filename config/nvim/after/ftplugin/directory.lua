vim.opt_local.statuscolumn = ""
vim.opt_local.foldcolumn = "0"
vim.opt_local.signcolumn = "yes:1" -- keep 1 for git signs
vim.opt_local.number = false
vim.opt_local.relativenumber = false

-- store cwd so render() knows where to run git
vim.b.directory_cwd = vim.uv.cwd()

require("directory").render(0)

vim.api.nvim_buf_attach(0, false, {
  on_lines = function(_, buf)
    require("directory").render(buf)
  end,
})
