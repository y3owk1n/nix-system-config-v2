-- require("launcher")
require("window")

local menubarSpace = require("menubar-space") -- show the current active space in number
local vimium = require("vimium") -- best effort to have vimium system wide

vimium:start()
menubarSpace:start()
