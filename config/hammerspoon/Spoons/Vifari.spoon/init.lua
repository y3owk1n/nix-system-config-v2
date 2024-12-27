local obj = {}
obj.__index = obj

--------------------------------------------------------------------------------
--- metadata
--------------------------------------------------------------------------------

obj.name = "vifari"
obj.version = "0.0.2"
obj.author = "Sergey Tarasov <dzirtusss@gmail.com>"
obj.homepage = "https://github.com/dzirtusss/vifari"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--------------------------------------------------------------------------------
--- config
--------------------------------------------------------------------------------

local mapping = {
	["i"] = "cmdInsertMode",
	-- movements
	["h"] = "cmdScrollLeft",
	["j"] = "cmdScrollDown",
	["k"] = "cmdScrollUp",
	["l"] = "cmdScrollRight",
	["d"] = "cmdScrollHalfPageDown",
	["u"] = "cmdScrollHalfPageUp",
	["gg"] = { "cmd", "up" },
	["G"] = { "cmd", "down" },
	-- tabs
	-- ["q"] = { { "cmd", "shift" }, "[" }, -- tab left
	-- ["w"] = { { "cmd", "shift" }, "]" }, -- tab right
	-- ["r"] = { "cmd", "r" },              -- reload tab
	-- ["x"] = { "cmd", "w" },              -- close tab
	-- ["t"] = { "cmd", "t" },              -- new tab
	-- ["o"] = { "cmd", "l" },              -- open
	["H"] = { "cmd", "[" }, -- history back
	["L"] = { "cmd", "]" }, -- history forward
	-- ["g1"] = { "cmd", "1" },
	-- ["g2"] = { "cmd", "2" },
	-- ["g3"] = { "cmd", "3" },
	-- ["g4"] = { "cmd", "4" },
	-- ["g5"] = { "cmd", "5" },
	-- ["g6"] = { "cmd", "6" },
	-- ["g7"] = { "cmd", "7" },
	-- ["g8"] = { "cmd", "8" },
	-- ["g9"] = { "cmd", "9" }, -- last tab
	-- ["g$"] = { "cmd", "9" }, -- last tab
	-- links
	["f"] = "cmdGotoLink",
	["r"] = "cmdRightClick",
	["F"] = "cmdGotoLinkNewTab",
	["gf"] = "cmdMoveMouseToLink",
	-- mouse
	["zz"] = "cmdMoveMouseToCenter",
	-- clipboard
	["yy"] = "cmdCopyPageUrlToClipboard",
	["yf"] = "cmdCopyLinkUrlToClipboard",
}

local config = {
	doublePressDelay = 0.3, -- seconds
	showLogs = false,
	mapping = mapping,
	scrollStep = 100,
	scrollStepHalfPage = 500,
	smoothScroll = false,
	smoothScrollHalfPage = true,
	axEditableRoles = { "AXTextField", "AXComboBox", "AXTextArea" },
	axJumpableRoles = {
		"AXLink",
		"AXButton",
		"AXPopUpButton",
		"AXComboBox",
		"AXTextField",
		"AXTextArea",
		"AXMenuItem",
		"AXMenu",
		"AXMenuButton",
		"AXRadioButton",
		"AXCheckBox",
		"AXStaticText", -- Sometimes clickable text
		-- "AXCell", -- Table cells
		-- "AXRow", -- Table rows
		"AXList",
		"AXListItem",
		"AXToolbar",
		"AXToolbarButton",
		"AXTabGroup",
		"AXTab",
		"AXSlider",
		"AXIncrementor",
		"AXDecrementor",
		"AXDisclosureTriangle",
	},
	axScrollableRoles = { "AXScrollArea", "AXScrollView", "AXGroup" },
	axContentRoles = {
		"AXWindow",
		"AXSplitGroup",
		"AXTabGroup",
		"AXWebArea",
		"AXScrollArea",
		"AXGroup",
		"AXDocument",
		"AXTextArea",
	},
	axBackgroundRoles = {
		"AXScrollArea",
		"AXGroup",
		"AXList",
		"AXOutline",
		"AXTable",
		"AXSplitGroup",
		"AXDrawer",
	},
	-- Apps where we want to disable vim navigation
	excludedApps = {
		"Terminal",
		"Alacritty",
		"Ghostty",
		"Screen Sharing",
	},
	browsers = {
		"Safari",
		"Google Chrome",
		"Firefox",
		"Microsoft Edge",
		"Brave Browser",
	},
}

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------

local cached = {}
local current = {}
local marks = { data = {} }
local menuBar = {}
local commands = {}
local windowFilter
local eventLoop
local modes = { DISABLED = 1, NORMAL = 2, INSERT = 3, MULTI = 4, LINKS = 5 }
local linkCapture
local lastEscape = hs.timer.absoluteTime()
local mappingPrefixes
local allCombinations

local function logWithTimestamp(message)
	if not config.showLogs then
		return
	end

	local timestamp = os.date("%Y-%m-%d %H:%M:%S") -- Get current date and time
	local ms = math.floor(hs.timer.absoluteTime() / 1e6) % 1000
	hs.printf("[%s.%03d] %s", timestamp, ms, message) -- Print the message with the timestamp
end

local function tblContains(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

function current.app()
	cached.app = cached.app or hs.application.frontmostApplication()
	return cached.app
end

function current.axApp()
	cached.axApp = cached.axApp or hs.axuielement.applicationElement(current.app())
	return cached.axApp
end

function current.window()
	cached.window = cached.window or current.app():focusedWindow()
	return cached.window
end

function current.axWindow()
	cached.axWindow = cached.axWindow or hs.axuielement.windowElement(current.window())
	return cached.axWindow
end

function current.axFocusedElement()
	cached.axFocusedElement = cached.axFocusedElement or current.axApp():attributeValue("AXFocusedUIElement")
	return cached.axFocusedElement
end

local function findAXRole(rootElement, role)
	if rootElement:attributeValue("AXRole") == role then
		return rootElement
	end

	for _, child in ipairs(rootElement:attributeValue("AXChildren") or {}) do
		local result = findAXRole(child, role)
		if result then
			return result
		end
	end
end

function current.axScrollArea()
	if not cached.axScrollArea then
		for _, role in ipairs(config.axScrollableRoles) do
			cached.axScrollArea = findAXRole(current.axWindow(), role)
			if cached.axScrollArea then
				break
			end
		end
	end
	return cached.axScrollArea
end

-- webarea path from window: AXWindow>AXSplitGroup>AXTabGroup>AXGroup>AXGroup>AXScrollArea>AXWebArea
function current.axWebArea()
	cached.axWebArea = cached.axWebArea or findAXRole(current.axScrollArea(), "AXWebArea")
	return cached.axWebArea
end

-- Modified to handle different types of content areas
function current.axContentArea()
	if cached.axContentArea then
		return cached.axContentArea
	end

	for _, role in ipairs(config.axContentRoles) do
		cached.axContentArea = findAXRole(current.axWindow(), role)
		if cached.axContentArea then
			break
		end
	end

	return cached.axContentArea
end

function current.visibleArea()
	if cached.visibleArea then
		return cached.visibleArea
	end

	local winFrame = current.axWindow():attributeValue("AXFrame")
	local contentArea = current.axContentArea()

	if not contentArea then
		return winFrame
	end

	local contentFrame = contentArea:attributeValue("AXFrame")

	local scrollFrame = current.axScrollArea() and current.axScrollArea():attributeValue("AXFrame") or contentFrame

	local visibleX = math.max(winFrame.x, contentFrame.x)
	local visibleY = math.max(winFrame.y, scrollFrame.y)

	local visibleWidth = math.min(winFrame.x + winFrame.w, contentFrame.x + contentFrame.w) - visibleX
	local visibleHeight = math.min(winFrame.y + winFrame.h, contentFrame.y + contentFrame.h) - visibleY

	cached.visibleArea = {
		x = visibleX,
		y = visibleY,
		w = visibleWidth,
		h = visibleHeight,
	}

	return cached.visibleArea
end

local function isEditableControlInFocus()
	if current.axFocusedElement() then
		return tblContains(config.axEditableRoles, current.axFocusedElement():attributeValue("AXRole"))
	else
		return false
	end
end

local function isExcludedApp()
	local appName = current.app():name()
	return tblContains(config.excludedApps, appName)
end

local function isSpotlightActive()
	local app = hs.application.get("Spotlight")
	local appElement = hs.axuielement.applicationElement(app)
	local windows = appElement:attributeValue("AXWindows")
	return #windows > 0
end

-- TODO: do some better logic here
local function generateCombinations()
	local chars = "abcdefghijklmnopqrstuvwxyz"
	allCombinations = {}
	for i = 1, #chars do
		for j = 1, #chars do
			table.insert(allCombinations, chars:sub(i, i) .. chars:sub(j, j))
		end
	end
end

local function smoothScroll(x, y, smooth)
	if smooth then
		local xstep = x / 5
		local ystep = y / 5
		hs.eventtap.event.newScrollEvent({ xstep, ystep }, {}, "pixel"):post()
		hs.timer.doAfter(0.01, function()
			hs.eventtap.event.newScrollEvent({ xstep * 3, ystep * 3 }, {}, "pixel"):post()
		end)
		hs.timer.doAfter(0.01, function()
			hs.eventtap.event.newScrollEvent({ xstep, ystep }, {}, "pixel"):post()
		end)
	else
		hs.eventtap.event.newScrollEvent({ x, y }, {}, "pixel"):post()
	end
end

local function openUrlInNewTab(url)
	local browserScripts = {
		Safari = [[
            tell application "Safari"
                activate
                tell window 1
                    set current tab to (make new tab with properties {URL:"%s"})
                end tell
            end tell
        ]],
		["Google Chrome"] = [[
            tell application "Google Chrome"
                activate
                tell window 1
                    make new tab with properties {URL:"%s"}
                end tell
            end tell
        ]],
		Firefox = [[
            tell application "Firefox"
                activate
                tell window 1
                    open location "%s"
                end tell
            end tell
        ]],
		["Microsoft Edge"] = [[
            tell application "Microsoft Edge"
                activate
                tell window 1
                    make new tab with properties {URL:"%s"}
                end tell
            end tell
        ]],
		["Brave Browser"] = [[
            tell application "Brave Browser"
                activate
                tell window 1
                    make new tab with properties {URL:"%s"}
                end tell
            end tell
        ]],
	}

	local currentApp = current.app():name()
	local script

	-- Select script based on current browser
	if browserScripts[currentApp] then
		script = string.format(browserScripts[currentApp], url)
	else
		-- Fallback to Safari if not a known browser
		script = string.format(browserScripts["Safari"], url)
	end

	-- script = string.format(script, url)
	hs.osascript.applescript(script)
end

local function setClipboardContents(contents)
	if contents and hs.pasteboard.setContents(contents) then
		hs.alert.show("Copied to clipboard: " .. contents, nil, nil, 4)
	else
		hs.alert.show("Failed to copy to clipboard", nil, nil, 4)
	end
end

local function forceUnfocus()
	logWithTimestamp("forced unfocus on escape")
	if current.axContentArea() then
		current.axContentArea():setAttributeValue("AXFocused", true)
	end
end

local function deepCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepCopy(orig_key)] = deepCopy(orig_value)
		end
		setmetatable(copy, deepCopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

--------------------------------------------------------------------------------
-- menubar
--------------------------------------------------------------------------------

function menuBar.new()
	if menuBar.item then
		menuBar.delete()
	end
	menuBar.item = hs.menubar.new()
end

function menuBar.delete()
	if menuBar.item then
		menuBar.item:delete()
	end
	menuBar.item = nil
end

local function setMode(mode, char)
	local defaultModeChars = {
		[modes.DISABLED] = "X",
		[modes.NORMAL] = "V",
	}

	local previousMode = current.mode
	current.mode = mode

	if current.mode == modes.LINKS and previousMode ~= modes.LINKS then
		linkCapture = ""
		marks.clear()
	end
	if previousMode == modes.LINKS and current.mode ~= modes.LINKS then
		linkCapture = nil
		hs.timer.doAfter(0, marks.clear)
	end

	if current.mode == modes.MULTI then
		current.multi = char
	end
	if current.mode ~= modes.MULTI then
		current.multi = nil
	end

	menuBar.item:setTitle(char or defaultModeChars[mode] or "?")
end

--------------------------------------------------------------------------------
-- marks
--------------------------------------------------------------------------------

function marks.clear()
	if marks.canvas then
		marks.canvas:delete()
	end
	marks.canvas = nil
	marks.data = {}
end

function marks.drawOne(markIndex)
	local mark = marks.data[markIndex]
	local visibleArea = current.visibleArea()
	local canvas = marks.canvas

	if not mark then
		return
	end
	if not marks.canvas then
		return
	end

	local position = mark.element:attributeValue("AXFrame") or mark.element:attributeValue("AXPosition")
	if not position then
		return
	end

	local padding = 2
	local fontSize = 14
	local bgRect = hs.geometry.rect(position.x, position.y, fontSize * 1.5 + 2 * padding, fontSize + 2 * padding)

	-- Different colors for different types of elements
	local fillColor
	local role = mark.element:attributeValue("AXRole")
	if role == "AXLink" then
		fillColor = { ["red"] = 1, ["green"] = 1, ["blue"] = 0, ["alpha"] = 0.9 }
	elseif role == "AXButton" then
		fillColor = { ["red"] = 0.3, ["green"] = 0.8, ["blue"] = 1, ["alpha"] = 0.9 }
	elseif tblContains(config.axEditableRoles, role) then
		fillColor = { ["red"] = 0.8, ["green"] = 0.5, ["blue"] = 1, ["alpha"] = 0.9 }
	else
		fillColor = { ["red"] = 0.5, ["green"] = 1, ["blue"] = 0, ["alpha"] = 0.9 }
	end

	canvas:appendElements({
		type = "rectangle",
		fillColor = fillColor,
		strokeColor = { ["red"] = 0, ["green"] = 0, ["blue"] = 0, ["alpha"] = 1 },
		strokeWidth = 1,
		roundedRectRadii = { xRadius = 3, yRadius = 3 },
		frame = {
			x = bgRect.x - visibleArea.x,
			y = bgRect.y - visibleArea.y,
			w = bgRect.w,
			h = bgRect.h,
		},
	})

	canvas:appendElements({
		type = "text",
		text = string.upper(allCombinations[markIndex]),
		textAlignment = "center",
		textColor = { ["red"] = 0, ["green"] = 0, ["blue"] = 0, ["alpha"] = 1 },
		textSize = fontSize,
		padding = padding,
		frame = {
			x = bgRect.x - visibleArea.x,
			y = bgRect.y - visibleArea.y,
			w = bgRect.w,
			h = bgRect.h,
		},
	})
end

function marks.draw()
	marks.canvas = hs.canvas.new(current.visibleArea())

	-- area testing
	-- marksCanvas:appendElements({
	--   type = "rectangle",
	--   fillColor = { ["red"] = 0, ["green"] = 1, ["blue"] = 0, ["alpha"] = 0.1 },
	--   strokeColor = { ["red"] = 1, ["green"] = 0, ["blue"] = 0, ["alpha"] = 1 },
	--   strokeWidth = 2,
	--   frame = { x = 0, y = 0, w = visibleArea.w, h = visibleArea.h }
	-- })

	for i, _ in ipairs(marks.data) do
		marks.drawOne(i)
	end

	-- marksCanvas:bringToFront(true)
	marks.canvas:show()
end

function marks.add(element)
	table.insert(marks.data, { element = element })
end

function marks.isElementPartiallyVisible(element)
	-- Check if element exists and is not hidden
	if not element or element:attributeValue("AXHidden") then
		return false
	end

	local frame = element:attributeValue("AXFrame")

	if not frame then
		return false
	end

	-- Check if element has zero size
	if frame.w == 0 or frame.h == 0 then
		return false
	end

	local visibleArea = current.visibleArea()

	local xOverlap = (frame.x < visibleArea.x + visibleArea.w) and (frame.x + frame.w > visibleArea.x)
	local yOverlap = (frame.y < visibleArea.y + visibleArea.h) and (frame.y + frame.h > visibleArea.y)

	return xOverlap and yOverlap
end

-- Helper function to check if an element is actionable
function marks.isElementActionable(element)
	if not element then
		return false
	end

	local role = element:attributeValue("AXRole")
	if not role then
		return false
	end

	local currentAppName = current.app():name()

	local axJumpableRolesCopy = deepCopy(config.axJumpableRoles)

	-- Check if its safari
	for _, browserName in ipairs(config.browsers) do
		if currentAppName == browserName then
			for i, jumpableRole in ipairs(axJumpableRolesCopy) do
				if jumpableRole == "AXStaticText" then
					table.remove(axJumpableRolesCopy, i)
					break -- Exit the loop once the item is found and removed
				end
			end
			break
		else
			for i, jumpableRole in ipairs(axJumpableRolesCopy) do
				if jumpableRole ~= "AXStaticText" then
					table.insert(axJumpableRolesCopy, "AXStaticText")
					break -- Exit the loop once the item is found and removed
				end
			end
		end
	end

	-- Return true if element has a supported role and is actionable
	return (tblContains(axJumpableRolesCopy, role))
end

function marks.findClickableElements(element, withUrls)
	if not element then
		return
	end

	-- Check if the element itself is clickable
	if marks.isElementActionable(element) and marks.isElementPartiallyVisible(element) then
		local shouldAdd = true
		if withUrls then
			shouldAdd = element:attributeValue("AXURL") ~= nil
		end
		if shouldAdd then
			marks.add(element)
		end
	end

	local children = element:attributeValue("AXChildren")
	if children then
		for _, child in ipairs(children) do
			marks.findClickableElements(child, withUrls)
		end
	end
end

function marks.show(withUrls)
	-- Start from the focused window's content
	local startElement = current.axWindow()
	if not startElement then
		return
	end

	-- Find all clickable elements
	marks.findClickableElements(startElement, withUrls)

	-- Only draw if we found any elements
	if #marks.data > 0 then
		marks.draw()
	else
		logWithTimestamp("No clickable elements found")
	end
end

function marks.click(combination)
	logWithTimestamp("marks.click")
	for i, c in ipairs(allCombinations) do
		if c == combination and marks.data[i] and marks.onClickCallback then
			-- Try to perform the action
			local success, err = pcall(function()
				marks.onClickCallback(marks.data[i])
			end)
			if not success then
				logWithTimestamp("Error clicking element: " .. tostring(err))
			end
		end
	end
end

--------------------------------------------------------------------------------
-- commands
--------------------------------------------------------------------------------

function commands.cmdScrollLeft()
	smoothScroll(config.scrollStep, 0, config.smoothScroll)
end

function commands.cmdScrollRight()
	smoothScroll(-config.scrollStep, 0, config.smoothScroll)
end

function commands.cmdScrollUp()
	smoothScroll(0, config.scrollStep, config.smoothScroll)
end

function commands.cmdScrollDown()
	smoothScroll(0, -config.scrollStep, config.smoothScroll)
end

function commands.cmdScrollHalfPageDown()
	smoothScroll(0, -config.scrollStepHalfPage, config.smoothScrollHalfPage)
end

function commands.cmdScrollHalfPageUp()
	smoothScroll(0, config.scrollStepHalfPage, config.smoothScrollHalfPage)
end

function commands.cmdCopyPageUrlToClipboard()
	local element = current.axWebArea()
	local url = element and element:attributeValue("AXURL")
	if url then
		setClipboardContents(url.url)
	end
end

function commands.cmdInsertMode(char)
	setMode(modes.INSERT, char)
end

function commands.cmdGotoLink(char)
	setMode(modes.LINKS, char)
	marks.onClickCallback = function(mark)
		local element = mark.element
		if not element then
			logWithTimestamp("Error: Invalid element")
			return
		end

		-- Try different methods to get position
		local position, size

		-- Method 1: Try direct AXPosition and AXSize
		local success, posResult = pcall(function()
			return element:attributeValue("AXPosition")
		end)
		local successSize, sizeResult = pcall(function()
			return element:attributeValue("AXSize")
		end)

		if success and successSize and posResult and sizeResult then
			position = posResult
			size = sizeResult
		end

		-- Method 2: Try getting frame
		if not position or not size then
			local frame = element:attributeValue("AXFrame")
			if frame then
				position = { x = frame.x, y = frame.y }
				size = { w = frame.w, h = frame.h }
			end
		end

		-- If we have position info, try mouse click
		if position and size then
			-- Calculate center point of the element
			local clickX = position.x + (size.w / 2)
			local clickY = position.y + (size.h / 2)

			-- Save current mouse position
			local originalPosition = hs.mouse.absolutePosition()

			-- Perform click sequence
			local clickSuccess, clickErr = pcall(function()
				-- Move mouse
				hs.mouse.absolutePosition({ x = clickX, y = clickY })
				hs.timer.usleep(50000) -- Wait 50ms

				-- Click
				hs.eventtap.leftClick({ x = clickX, y = clickY })

				-- Restore mouse position
				hs.timer.doAfter(0.1, function()
					hs.mouse.absolutePosition(originalPosition)
				end)
			end)

			if clickSuccess then
				return
			else
				logWithTimestamp("Click failed: " .. tostring(clickErr))
			end
		end

		-- Method 3: Try to get position from the mark itself
		if mark.x and mark.y then
			local clickSuccess, clickErr = pcall(function()
				local originalPosition = hs.mouse.absolutePosition()

				-- Move and click
				hs.mouse.absolutePosition({ x = mark.x, y = mark.y })
				hs.timer.usleep(50000)
				hs.eventtap.leftClick({ x = mark.x, y = mark.y })

				-- Restore position
				hs.timer.doAfter(0.1, function()
					hs.mouse.absolutePosition(originalPosition)
				end)
			end)

			if clickSuccess then
				return
			else
				logWithTimestamp("Mark click failed: " .. tostring(clickErr))
			end
		end

		-- Final fallback: focus + return key
		logWithTimestamp("Falling back to focus + return method")
		local focusSuccess, focusErr = pcall(function()
			element:setAttributeValue("AXFocused", true)
			hs.timer.doAfter(0.1, function()
				hs.eventtap.keyStroke({}, "return", 0)
			end)
		end)

		if not focusSuccess then
			logWithTimestamp("Focus fallback failed: " .. tostring(focusErr))
		end
	end
	hs.timer.doAfter(0, marks.show)
end

function commands.cmdRightClick(char)
	setMode(modes.LINKS, char)
	marks.onClickCallback = function(mark)
		local element = mark.element
		if not element then
			logWithTimestamp("Error: Invalid element")
			return
		end

		local position, size

		local success, posResult = pcall(function()
			return element:attributeValue("AXPosition")
		end)
		local successSize, sizeResult = pcall(function()
			return element:attributeValue("AXSize")
		end)

		if success and successSize and posResult and sizeResult then
			position = posResult
			size = sizeResult
		end

		-- Method 2: Try getting frame
		if not position or not size then
			local frame = element:attributeValue("AXFrame")
			if frame then
				position = { x = frame.x, y = frame.y }
				size = { w = frame.w, h = frame.h }
			end
		end

		if position and size then
			-- Calculate center point of the element
			local clickX = position.x + (size.w / 2)
			local clickY = position.y + (size.h / 2)

			-- Save current mouse position
			local originalPosition = hs.mouse.absolutePosition()

			-- Perform click sequence
			local clickSuccess, clickErr = pcall(function()
				-- Move mouse
				hs.mouse.absolutePosition({ x = clickX, y = clickY })
				hs.timer.usleep(50000) -- Wait 50ms

				-- Click
				hs.eventtap.rightClick({ x = clickX, y = clickY })

				-- Restore mouse position
				hs.timer.doAfter(0.1, function()
					hs.mouse.absolutePosition(originalPosition)
				end)
			end)

			if clickSuccess then
				return
			else
				logWithTimestamp("Click failed: " .. tostring(clickErr))
			end
		end
	end
	hs.timer.doAfter(0, marks.show)
end

function commands.cmdGotoLinkNewTab(char)
	local currentAppName = current.app():name()
	logWithTimestamp("currentAppName: " .. hs.inspect(currentAppName))

	-- Check if the current app is in the list of browsers
	for _, browserName in ipairs(config.browsers) do
		if currentAppName == browserName then
			setMode(modes.LINKS, char)
			marks.onClickCallback = function(mark)
				local axURL = mark.element:attributeValue("AXURL")
				if axURL then
					openUrlInNewTab(axURL.url)
				end
			end
			hs.timer.doAfter(0, function()
				marks.show(true)
			end)
			break
		end
	end
end

function commands.cmdMoveMouseToLink(char)
	setMode(modes.LINKS, char)
	marks.onClickCallback = function(mark)
		local frame = mark.element:attributeValue("AXFrame")
		hs.mouse.absolutePosition({ x = frame.x + frame.w / 2, y = frame.y + frame.h / 2 })
	end
	hs.timer.doAfter(0, marks.show)
end

function commands.cmdMoveMouseToCenter()
	hs.mouse.absolutePosition({
		x = current.visibleArea().x + current.visibleArea().w / 2,
		y = current.visibleArea().y + current.visibleArea().h / 2,
	})
end

function commands.cmdCopyLinkUrlToClipboard(char)
	setMode(modes.LINKS, char)
	marks.onClickCallback = function(mark)
		local axURL = mark.element:attributeValue("AXURL")
		setClipboardContents(axURL.url)
	end
	hs.timer.doAfter(0, function()
		marks.show(true)
	end)
end

--------------------------------------------------------------------------------
--- vifari
--------------------------------------------------------------------------------

local function fetchMappingPrefixes()
	mappingPrefixes = {}
	for k, _ in pairs(config.mapping) do
		if #k == 2 then
			mappingPrefixes[string.sub(k, 1, 1)] = true
		end
	end
	logWithTimestamp("mappingPrefixes: " .. hs.inspect(mappingPrefixes))
end

local function vimLoop(char)
	logWithTimestamp("vimLoop " .. char)

	if current.mode == modes.LINKS then
		linkCapture = linkCapture .. char:lower()
		if #linkCapture == 2 then
			marks.click(linkCapture)
			setMode(modes.NORMAL)
		end
		return
	end

	if current.mode == modes.MULTI then
		char = current.multi .. char
	end
	local foundMapping = config.mapping[char]

	if foundMapping then
		setMode(modes.NORMAL)

		if type(foundMapping) == "string" then
			commands[foundMapping](char)
		elseif type(foundMapping) == "table" then
			hs.eventtap.keyStroke(foundMapping[1], foundMapping[2], 0)
		else
			logWithTimestamp("Unknown mapping for " .. char .. " " .. hs.inspect(foundMapping))
		end
	elseif mappingPrefixes[char] then
		setMode(modes.MULTI, char)
	else
		logWithTimestamp("Unknown char " .. char)
	end
end

local function eventHandler(event)
	cached = {}

	if isExcludedApp() then
		return false
	end

	for key, modifier in pairs(event:getFlags()) do
		if modifier and key ~= "shift" then
			return false
		end
	end

	if isSpotlightActive() then
		return false
	end

	if event:getKeyCode() == hs.keycodes.map["escape"] then
		local delaySinceLastEscape = (hs.timer.absoluteTime() - lastEscape) / 1e9 -- nanoseconds in seconds
		lastEscape = hs.timer.absoluteTime()

		if delaySinceLastEscape < config.doublePressDelay then
			setMode(modes.NORMAL)
			forceUnfocus()
			return true
		end

		if current.mode ~= modes.NORMAL then
			setMode(modes.NORMAL)
			return true
		end

		return false
	end

	if current.mode == modes.INSERT or isEditableControlInFocus() then
		return false
	end

	local char = event:getCharacters()
	if not char:match("[%a%d%[%]%$]") then
		return false
	end

	hs.timer.doAfter(0, function()
		vimLoop(char)
	end)
	return true
end

local function onWindowFocused()
	logWithTimestamp("onWindowFocused")
	if not eventLoop then
		eventLoop = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, eventHandler):start()
	end
	if not isExcludedApp() then
		setMode(modes.NORMAL)
	else
		setMode(modes.DISABLED)
	end
end

local function onWindowUnfocused()
	logWithTimestamp("onWindowUnfocused")
	if eventLoop then
		eventLoop:stop()
		eventLoop = nil
	end
	setMode(modes.DISABLED)
end

function obj:start()
	windowFilter = hs.window.filter.new()
	windowFilter:subscribe(hs.window.filter.windowFocused, onWindowFocused)
	windowFilter:subscribe(hs.window.filter.windowUnfocused, onWindowUnfocused)
	menuBar.new()
	fetchMappingPrefixes()
	generateCombinations()
end

function obj:stop()
	if windowFilter then
		windowFilter:unsubscribe(onWindowFocused)
		windowFilter:unsubscribe(onWindowUnfocused)
		windowFilter = nil
	end
	menuBar.delete()
end

return obj
