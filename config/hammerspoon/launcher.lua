local HYPER = { "cmd", "ctrl", "alt", "shift" }

-- Configuration table for all your keybindings
local mapping = {
	-- Format: { modifiers = {}, key = "", app = "" }
	{ modifiers = HYPER, key = "F", app = "Finder" },
	{ modifiers = HYPER, key = "B", app = "Safari" },
	{ modifiers = HYPER, key = "T", app = "Alacritty" },
	{ modifiers = HYPER, key = "N", app = "Notes" },
	{ modifiers = HYPER, key = "W", app = "WhatsApp" },
	{ modifiers = HYPER, key = "M", app = "Mail" },
	{ modifiers = HYPER, key = "C", app = "Calendar" },
	{ modifiers = HYPER, key = "S", app = "System Settings" },
	-- Add more bindings here
}

local config = {
	showLogs = true,
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

-- Function to handle app launch, focus, and window cycling
local function launchOrFocusOrCycle(appName)
	hs.application.enableSpotlightForNameSearches(true)
	local app = hs.application.find(appName)

	local function hideOtherApps(targetAppName)
		local visibleWindows = hs.window.visibleWindows()
		local otherApps = {}

		logWithTimestamp("Identifying visible apps:")

		-- Collect all apps from visible windows that are not the target app
		for _, window in ipairs(visibleWindows) do
			local windowApp = window:application()
			logWithTimestamp(string.format(" - Found window: '%s' (App: '%s')", window:title(), appName))
			if windowApp and windowApp:name() ~= targetAppName then
				otherApps[windowApp:name()] = windowApp
			else
				logWithTimestamp(" - Found a window without an associated application.")
			end
		end

		logWithTimestamp("Hiding apps that are not the target:")

		-- Hide all collected apps
		for _, otherApp in pairs(otherApps) do
			logWithTimestamp(string.format(" - Hiding app: '%s'", appName))
			otherApp:hide()
		end
	end

	if not app then
		logWithTimestamp(string.format("Application '%s' not found. Launching it.", appName))
		-- App isn't running, so launch it
		hs.application.launchOrFocus(appName)
		hideOtherApps(appName)
		return
	end

	logWithTimestamp(string.format("Application '%s' found.", appName))

	-- Ensure app is running and get all windows
	if not app:isRunning() then
		logWithTimestamp(string.format("Application '%s' is not running. Activating it.", appName))
		hs.application.launchOrFocus(appName)
		hideOtherApps(appName)
		return
	end

	-- Get all windows and filter out any nil or invalid windows
	local allWindows = app:allWindows()
	logWithTimestamp(string.format("Application '%s' has %d total windows.", appName, #allWindows))

	local windows = {}
	for _, window in ipairs(allWindows) do
		if window:isVisible() and window:isStandard() then
			table.insert(windows, window)
		else
			logWithTimestamp("Filtered out an invalid or non-standard window.")
		end
	end

	-- Debug info
	logWithTimestamp(string.format("Found %d windows for %s", #windows, appName))

	if #windows == 0 then
		logWithTimestamp(string.format("No visible standard windows found for '%s'. Activating app.", appName))
		-- No windows, just focus the app
		hs.application.launchOrFocus(appName)
		hideOtherApps(appName)
		return
	end

	-- Get focused window
	local focusedWindow = hs.window.focusedWindow()
	if not focusedWindow then
		logWithTimestamp("No currently focused window. Focusing the first window.")
		windows[1]:focus()
		hideOtherApps(appName)
		return
	end

	logWithTimestamp(string.format("Currently focused window belongs to: %s", focusedWindow:application():name()))

	if focusedWindow:application():name() ~= appName then
		logWithTimestamp("Focused window does not belong to the target app. Focusing the first window.")
		-- App's window not focused, focus first window
		windows[1]:focus()
		hideOtherApps(appName)
		return
	end

	-- Find current window index
	local currentIndex = 1
	for i, window in ipairs(windows) do
		if window:id() == focusedWindow:id() then
			currentIndex = i
			break
		end
	end
	logWithTimestamp(string.format("Current window index: %d", currentIndex))

	-- Calculate next window index with explicit wrap-around
	local nextIndex
	if currentIndex >= #windows then
		nextIndex = 1 -- Wrap back to first window
	else
		nextIndex = currentIndex + 1 -- Go to next window
	end

	-- Show cycling information
	logWithTimestamp(string.format("Cycling %s: Window %d of %d", appName, nextIndex, #windows))

	-- Focus next window
	windows[nextIndex]:focus()
	hideOtherApps(appName)
end

-- Set up all keybindings from the configuration table
for _, binding in ipairs(config.mapping) do
	hs.hotkey.bind(binding.modifiers, binding.key, function()
		launchOrFocusOrCycle(binding.app)
	end)
end

local function listRunningApps()
	local runningApps = hs.application.runningApplications()

	-- Print header
	print("\nRunning Applications:")
	print("Name | Bundle ID")
	print("------------------")

	-- Create a table to store apps for sorting
	local apps = {}
	for _, app in ipairs(runningApps) do
		table.insert(apps, {
			name = app:name(),
			bundleID = app:bundleID() or "N/A",
		})
	end

	-- Sort alphabetically
	table.sort(apps, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	-- Print sorted list
	for _, app in ipairs(apps) do
		if app.name and app.name ~= "" then
			print(string.format("%s | %s", app.name, app.bundleID))
		end
	end
end

hs.hotkey.bind({ "cmd", "shift" }, "`", function()
	listRunningApps()
	hs.alert.show("Installed apps list printed to console")
end)
