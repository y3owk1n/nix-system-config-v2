local session_file = vim.fn.stdpath("data") .. "/restart-session.vim"

---Save current state & restart
local function save_restart()
  vim.cmd("silent! wall")
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))

  vim.schedule(function()
    vim.cmd("restart")
  end)
end

vim.keymap.set("n", "<leader>R", save_restart, { noremap = true, silent = true })

--Auto-restore on the *next* startup
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  nested = true,
  callback = function()
    if vim.fn.filereadable(session_file) == 1 then
      vim.schedule(function()
        vim.cmd("source " .. vim.fn.fnameescape(session_file))

        vim.fn.delete(session_file)
        local still_exists = vim.fn.filereadable(session_file) == 1

        if still_exists then
          vim.notify("Session file still exists! Something is wrong with the script...", vim.log.levels.WARN)
        end
      end)
    end
  end,
})
