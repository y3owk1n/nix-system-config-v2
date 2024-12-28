-- require("launcher")
require("window")
local menubarSpace = require("menubar-space")

hs.loadSpoon("Vifari")
spoon.Vifari:start() -- this will add hooks. `:stop()` to remove hooks

menubarSpace:start()
