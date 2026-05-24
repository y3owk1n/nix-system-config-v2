-- =========================================================
--  Experimental UI
-- =========================================================

local ok, ui2 = pcall(require, "vim._core.ui2")

if ok and ui2.enable then
  vim.o.cmdheight = 0

  ui2.enable({
    enable = true,
    msg = {
      targets = "msg",
      msg = {
        height = 0.0001,
        timeout = 2000,
      },
    },
  })
end
