-- Buffer/window setup for the builtin "dir" listing (:h dir-config).
-- Options belong here, not in the DirReadPost render hook.

-- "wipe", not "delete": a wiped buffer's jumplist entries go with it, so CTRL-O
-- leaves the listing in one press instead of walking back through stale ones.
-- The plugin uses :keepalt, so CTRL-^ works the same either way.
vim.bo.bufhidden = "wipe"

-- vim.wo[0][0] is :setlocal semantics: does not leak into the next buffer
-- opened in this window.
local wo = vim.wo[0][0]
wo.foldcolumn = "0"
wo.number = false
wo.relativenumber = false
wo.signcolumn = "yes:1" -- keep 1 for git signs
wo.statuscolumn = ""
