-- =========================================================
--  Experimental UI
-- =========================================================

local ok, ui2 = pcall(require, "vim._core.ui2")

if ok and ui2.enable then
  -- vim.o.cmdheight = 0

  ui2.enable({
    enable = true,
    msg = {
      targets = { default = "cmd", progress = "msg" },
      msg = {
        height = 1,
        timeout = 2000,
      },
    },
  })
end
