local HYPER = { "cmd", "ctrl", "alt", "shift" }

-- Define a helper function to run yabai commands
local function runYabai(cmd)
	os.execute("/run/current-system/sw/bin/yabai -m " .. cmd)
end

-- Keybindings for window focus
hs.hotkey.bind(HYPER, "H", function()
	-- runYabai("window --focus stack.prev")
	runYabai("window --focus west")
end)
hs.hotkey.bind(HYPER, "J", function()
	runYabai("window --focus south")
end)
hs.hotkey.bind(HYPER, "K", function()
	runYabai("window --focus north")
end)
hs.hotkey.bind(HYPER, "L", function()
	-- runYabai("window --focus stack.next")
	runYabai("window --focus east")
end)

-- Keybindings for swapping windows
hs.hotkey.bind({ "ctrl", "shift" }, "H", function()
	-- runYabai("window --swap stack.prev")
	runYabai("window --swap west")
end)
hs.hotkey.bind({ "ctrl", "shift" }, "J", function()
	runYabai("window --swap south")
end)
hs.hotkey.bind({ "ctrl", "shift" }, "K", function()
	runYabai("window --swap north")
end)
hs.hotkey.bind({ "ctrl", "shift" }, "L", function()
	-- runYabai("window --swap stack.next")
	runYabai("window --swap east")
end)

-- Toggle fullscreen zoom
hs.hotkey.bind(HYPER, "m", function()
	runYabai("window --toggle zoom-fullscreen")
end)

-- Toggle float and center window
hs.hotkey.bind(HYPER, "t", function()
	runYabai("window --toggle float")
	runYabai("window --grid 4:4:1:1:2:2")
end)

-- Toggle window split type
-- hs.hotkey.bind(HYPER, "e", function()
-- 	runYabai("window --toggle split")
-- end)

-- Balance window sizes
hs.hotkey.bind(HYPER, "0", function()
	runYabai("space --balance")
end)
