vim.opt_local.statuscolumn = ""
vim.opt_local.foldcolumn = "0"
vim.opt_local.signcolumn = "yes:1" -- keep 1 for git signs
vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.bufhidden = "wipe"

require("directory").render(0)

vim.api.nvim_buf_attach(0, false, {
  on_lines = function(_, buf)
    require("directory").render(buf)
  end,
})

vim.keymap.set("n", "q", function()
  local prev = vim.w.dir_prev_buf
  if prev and vim.api.nvim_buf_is_valid(prev) then
    vim.api.nvim_set_current_buf(prev)
  end
end, { buffer = true })
