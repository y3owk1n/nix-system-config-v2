-- =========================================================
--  Native notifications
-- =========================================================

local ok, ui2 = pcall(require, "vim._core.ui2")

if ok and ui2.enable then
  ui2.enable({
    msg = {
      target = "msg",
      msg = {
        height = 0.0001,
        width = 1,
        timeout = 2000,
      },
    },
  })
end
