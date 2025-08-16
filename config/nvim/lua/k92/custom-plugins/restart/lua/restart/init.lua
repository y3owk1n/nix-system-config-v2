---@class Restart
local M = {}

local session_file = vim.fn.stdpath("data") .. "/restart-session.vim"

-- ------------------------------------------------------------------
-- public
-- ------------------------------------------------------------------

---@type Restart.Config
M.config = {}

---@class Restart.Config
M.defaults = {}

---@param user_config? Restart.Config
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

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
end

---Save current state & restart
function M.save_restart()
  vim.cmd("silent! wall")
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))

  vim.schedule(function()
    vim.cmd("restart")
  end)
end

return M
