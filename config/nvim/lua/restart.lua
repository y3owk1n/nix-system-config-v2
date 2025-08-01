local session_file = vim.fn.stdpath("data") .. "/restart-session.vim"

---Save current state
local function save_restart_session()
  vim.cmd("silent! wall")
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
end

---Wrapper that saves and then restarts
vim.api.nvim_create_user_command("Restart", function(opts)
  save_restart_session()
  ---Forward any argument the user typed, e.g. '+qall!'
  vim.cmd("restart " .. (opts.args or ""))
end, { bang = true, nargs = "?" })

-- 3. Auto-restore on the *next* startup
--    We use a once-only autocmd so it fires after *every* restart.
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
