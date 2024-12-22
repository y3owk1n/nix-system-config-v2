-- Configuration table for all your keybindings
local mapping = {
	{ modifiers = { "cmd", "shift" }, key = "H", cmd = "moveLeft" },
	{ modifiers = { "cmd", "shift" }, key = "J", cmd = "moveDown" },
	{ modifiers = { "cmd", "shift" }, key = "K", cmd = "moveUp" },
	{ modifiers = { "cmd", "shift" }, key = "L", cmd = "moveRight" },
	{ modifiers = { "cmd", "shift" }, key = "M", cmd = "maximise" },
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

-- Function to handle app launch, focus, and window cycling
local function action(cmd)
	commands[cmd]()
end

-- Set up all keybindings from the configuration table
for _, binding in ipairs(config.mapping) do
	hs.hotkey.bind(binding.modifiers, binding.key, function()
		action(binding.cmd)
	end)
end
