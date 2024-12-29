local HYPER = { "cmd", "ctrl", "alt", "shift" }

-- Configuration table for all your keybindings
local mapping = {
	-- { modifiers = { "cmd", "shift" }, key = "H", cmd = "moveLeft" },
	-- { modifiers = { "cmd", "shift" }, key = "J", cmd = "moveDown" },
	-- { modifiers = { "cmd", "shift" }, key = "K", cmd = "moveUp" },
	-- { modifiers = { "cmd", "shift" }, key = "L", cmd = "moveRight" },
	-- { modifiers = { "cmd", "shift" }, key = "M", cmd = "maximise" },
	{ modifiers = HYPER, key = "H", cmd = "focusWindowInDirection", arg = "west" },
	{ modifiers = HYPER, key = "L", cmd = "focusWindowInDirection", arg = "east" },
	{ modifiers = HYPER, key = "J", cmd = "focusWindowInDirection", arg = "south" },
	{ modifiers = HYPER, key = "K", cmd = "focusWindowInDirection", arg = "north" },
	{ modifiers = { "ctrl", "shift" }, key = "1", cmd = "moveWindowToSpace", arg = "1" },
	{ modifiers = { "ctrl", "shift" }, key = "2", cmd = "moveWindowToSpace", arg = "2" },
	{ modifiers = { "ctrl", "shift" }, key = "3", cmd = "moveWindowToSpace", arg = "3" },
	{ modifiers = { "ctrl", "shift" }, key = "4", cmd = "moveWindowToSpace", arg = "4" },
	{ modifiers = { "ctrl", "shift" }, key = "5", cmd = "moveWindowToSpace", arg = "5" },
	{ modifiers = { "ctrl", "shift" }, key = "6", cmd = "moveWindowToSpace", arg = "6" },
	{ modifiers = { "ctrl", "shift" }, key = "7", cmd = "moveWindowToSpace", arg = "7" },
	-- Add more bindings here
}

local config = {
	showLogs = true,
	gap = 10,
	mapping = mapping,
}

local function logWithTimestamp(message)
	if not config.showLogs then
		return
	end

	local timestamp = os.date("%Y-%m-%d %H:%M:%S") -- Get current date and time
	local ms = math.floor(hs.timer.absoluteTime() / 1e6) % 1000
	hs.printf("[%s.%03d] %s", timestamp, ms, message) -- Print the message with the timestamp
end

local commands = {}

function commands.moveLeft()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + config.gap
	f.y = max.y + config.gap
	f.w = (max.w / 2) - (config.gap * 1.5)
	f.h = max.h - (config.gap * 2)
	win:setFrame(f)
	logWithTimestamp("Window moved left!")
end

function commands.moveRight()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + (max.w / 2) + (config.gap * 0.5)
	f.y = max.y + config.gap
	f.w = (max.w / 2) - (config.gap * 1.5)
	f.h = max.h - (config.gap * 2)
	win:setFrame(f)
	logWithTimestamp("Window moved right!")
end

function commands.moveUp()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + config.gap
	f.y = max.y + config.gap
	f.w = max.w - (config.gap * 2)
	f.h = (max.h / 2) - (config.gap * 1.5)
	win:setFrame(f)
	logWithTimestamp("Window moved up!")
end

function commands.moveDown()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + config.gap
	f.y = max.y + (max.h / 2) + (config.gap * 0.5)
	f.w = max.w - (config.gap * 2)
	f.h = (max.h / 2) - (config.gap * 1.5)
	win:setFrame(f)

	logWithTimestamp("Window moved down!")
end

function commands.maximise()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + config.gap
	f.y = max.y + config.gap
	f.w = max.w - (config.gap * 2)
	f.h = max.h - (config.gap * 2)
	win:setFrame(f)

	logWithTimestamp("Window maximised!")
end

local function getActualSpaceId(spaceId)
	local virtualSpaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
	local actualVirtualSpaceId

	for i, virtualSpaceId in ipairs(virtualSpaces) do
		if tostring(i) == tostring(spaceId) then
			logWithTimestamp("found virtual space Id" .. virtualSpaceId)
			actualVirtualSpaceId = virtualSpaceId
			break
		end
	end

	return actualVirtualSpaceId
end

-- NOTE: Hack!
local function simulateKeyEvent(modifiers, key)
	if modifiers then
		for _, mod in ipairs(modifiers) do
			hs.eventtap.event.newKeyEvent(mod, true):post()
		end
	end
	hs.eventtap.event.newKeyEvent(key, true):post()
	hs.timer.doAfter(0.1, function()
		hs.eventtap.event.newKeyEvent(key, false):post()
		if modifiers then
			for _, mod in ipairs(modifiers) do
				hs.eventtap.event.newKeyEvent(mod, false):post()
			end
		end
	end)
end

-- NOTE: Hack!
local function dragAndMoveWindowToSpace(win, spaceId)
	local MOUSE_OFFSET_X = 5
	local MOUSE_OFFSET_Y = 12
	local SWITCH_DELAY = 0.2
	local RELEASE_DELAY = 0.5

	-- Get window frame and calculate positions
	local frame = win:frame()
	local clickPos = hs.geometry.point(frame.x + MOUSE_OFFSET_X, frame.y + MOUSE_OFFSET_Y)
	local centerPos = hs.geometry.point(frame.x + frame.w / 2, frame.y + frame.h / 2)

	-- Move mouse to click position
	hs.mouse.absolutePosition(clickPos)

	-- Simulate mouse press and desktop switch
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickPos):post()

	hs.timer.doAfter(SWITCH_DELAY, function()
		simulateKeyEvent(HYPER, spaceId)
	end)
	-- Release mouse and restore position
	hs.timer.doAfter(RELEASE_DELAY, function()
		hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, clickPos):post()
		hs.mouse.absolutePosition(centerPos)
		win:raise()
		win:focus()
	end)
end

function commands.moveWindowToSpace(spaceId)
	local actualSpaceId = getActualSpaceId(spaceId)

	if actualSpaceId then
		local win = hs.window.focusedWindow()
		if win then
			-- NOTE: Not working for now, apple disabled the api
			-- follow it here [https://github.com/Hammerspoon/hammerspoon/issues/3698]
			-- hs.spaces.moveWindowToSpace(win, actualSpaceId, true)

			-- NOTE: Custom hack that simulate drag, switch spaces and put it there
			-- in this case, we dont need to get the actualSpaceId, but let's keep the code here
			-- for future use
			dragAndMoveWindowToSpace(win, spaceId)

			logWithTimestamp("Moved window" .. win:id() .. "to space" .. actualSpaceId)
		else
			logWithTimestamp("No focused window found")
		end
	else
		logWithTimestamp("No actual space id matched for space: " .. spaceId)
	end
end

function commands.focusWindowInDirection(direction)
	local window = hs.window.frontmostWindow() -- Get the currently focused window
	if not window then
		logWithTimestamp("No active window to focus from")
		return false
	end

	local success
	if direction == "east" then
		success = window:focusWindowEast()
	elseif direction == "west" then
		success = window:focusWindowWest()
	elseif direction == "north" then
		success = window:focusWindowNorth()
	elseif direction == "south" then
		success = window:focusWindowSouth()
	else
		logWithTimestamp("Invalid direction: " .. direction)
		return false
	end

	if success == nil then
		logWithTimestamp("Search couldn't take place")
	elseif not success then
		logWithTimestamp("No window found in the " .. direction .. " direction")
	end
end

-- Function to handle app launch, focus, and window cycling
local function action(cmd, arg)
	commands[cmd](arg)
end

-- Set up all keybindings from the configuration table
for _, binding in ipairs(config.mapping) do
	hs.hotkey.bind(binding.modifiers, binding.key, function()
		if binding.arg then
			action(binding.cmd, binding.arg)
		else
			action(binding.cmd)
		end
	end)
end
