--------------------------------------------------------------------------------
-- Imports and Initialization
--------------------------------------------------------------------------------

local floor = math.floor
local insert = table.insert
local format = string.format
local sub = string.sub
local pcall = pcall
local timer = hs.timer
local mouse = hs.mouse
local eventtap = hs.eventtap

local M = {}

--------------------------------------------------------------------------------
-- Constants and Configuration
--------------------------------------------------------------------------------

M.modes = { DISABLED = 1, NORMAL = 2, INSERT = 3, MULTI = 4, LINKS = 5 }

M.mapping = {
	["i"] = "cmdInsertMode",
	-- movements
	["h"] = "cmdScrollLeft",
	["j"] = "cmdScrollDown",
	["k"] = "cmdScrollUp",
	["l"] = "cmdScrollRight",
	["d"] = "cmdScrollHalfPageDown",
	["u"] = "cmdScrollHalfPageUp",
	["gg"] = "cmdScrollToBottom",
	["G"] = "cmdScrollToTop",
	["H"] = { "cmd", "[" }, -- history back
	["L"] = { "cmd", "]" }, -- history forward
	["f"] = "cmdGotoLink",
	["r"] = "cmdRightClick",
	["F"] = "cmdGotoLinkNewTab",
	["gf"] = "cmdMoveMouseToLink",
	["gi"] = "cmdGotoInput",
	["zz"] = "cmdMoveMouseToCenter",
	["yy"] = "cmdCopyPageUrlToClipboard",
	["yf"] = "cmdCopyLinkUrlToClipboard",
}

M.config = {
	doublePressDelay = 0.3, -- seconds
	showLogs = false,
	mapping = M.mapping,
	scrollStep = 100,
	scrollStepHalfPage = 500,
	scrollStepFullPage = 100000, -- make it a super big number and not worry
	smoothScroll = true,
	smoothScrollFrameRate = 120,
	depth = 20, -- depth for traversing children when creating marks
	axEditableRoles = { "AXTextField", "AXComboBox", "AXTextArea", "AXSearchField" },
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
		"AXToolbar",
		"AXToolbarButton",
		"AXTabGroup",
		"AXTab",
		"AXSlider",
		"AXIncrementor",
		"AXDecrementor",
		"AXDisclosureTriangle",
		"AXGroup",
	},
	axScrollableRoles = {
		"AXScrollArea",
		"AXScrollView",
		"AXOverflow",
		"AXGroup",
		"AXScrollable",
		"AXHorizontalScroll",
		"AXVerticalScroll",
		"AXWebArea",
	},
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
	-- Browser names to be considered
	browsers = {
		"Safari",
		"Google Chrome",
		"Firefox",
		"Microsoft Edge",
		"Brave Browser",
	},
}

--------------------------------------------------------------------------------
-- State Management
--------------------------------------------------------------------------------

M.cached = setmetatable({}, { __mode = "k" })
M.current = {}
M.marks = { data = {} }
M.menuBar = {}
M.commands = {}
M.windowFilter = nil
M.eventLoop = nil
M.linkCapture = nil
M.lastEscape = timer.absoluteTime()
M.mappingPrefixes = {}
M.allCombinations = {}

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

--- @param message string # The message to log.
M.logWithTimestamp = function(message)
	if not M.config.showLogs then
		return
	end

	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local ms = floor(timer.absoluteTime() / 1e6) % 1000
	hs.printf("[%s.%03d] %s", timestamp, ms, message)
end

--- @generic T
--- @param tbl T[] # The table to search.
--- @param val T # The value to search for.
--- @return boolean # Returns `true` if the value is found, otherwise `false`.
M.tblContains = function(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

--- @generic T
--- @param tbl T[] # The table to filter.
--- @param predicate fun(item: T): boolean # The function that determines if an item should be included.
--- @return T[] # A new table containing only the items for which the predicate returned true.
M.filter = function(tbl, predicate)
	local result = {}
	for _, v in ipairs(tbl) do
		if predicate(v) then
			table.insert(result, v)
		end
	end
	return result
end

--------------------------------------------------------------------------------
-- Element State & Access Functions
--------------------------------------------------------------------------------

M.current.app = function()
	M.cached.app = M.cached.app or hs.application.frontmostApplication()
	return M.cached.app
end

M.current.axApp = function()
	M.cached.axApp = M.cached.axApp or hs.axuielement.applicationElement(M.current.app())
	return M.cached.axApp
end

M.current.window = function()
	M.cached.window = M.cached.window or M.current.app():focusedWindow()
	return M.cached.window
end

M.current.axWindow = function()
	M.cached.axWindow = M.cached.axWindow or hs.axuielement.windowElement(M.current.window())
	return M.cached.axWindow
end

M.current.axFocusedElement = function()
	M.cached.axFocusedElement = M.cached.axFocusedElement or M.current.axApp():attributeValue("AXFocusedUIElement")
	return M.cached.axFocusedElement
end

M.current.axScrollArea = function()
	if not M.cached.axScrollArea then
		for _, role in ipairs(M.config.axScrollableRoles) do
			M.cached.axScrollArea = M.findAXRole(M.current.axWindow(), role)
			if M.cached.axScrollArea then
				break
			end
		end
	end
	return M.cached.axScrollArea
end

M.current.axWebArea = function()
	M.cached.axWebArea = M.cached.axWebArea or M.findAXRole(M.current.axScrollArea(), "AXWebArea")
	return M.cached.axWebArea
end

M.current.axContentArea = function()
	if M.cached.axContentArea then
		return M.cached.axContentArea
	end

	for _, role in ipairs(M.config.axContentRoles) do
		M.cached.axContentArea = M.findAXRole(M.current.axWindow(), role)
		if M.cached.axContentArea then
			break
		end
	end

	return M.cached.axContentArea
end

M.current.visibleArea = function()
	if M.cached.visibleArea then
		return M.cached.visibleArea
	end

	local winFrame = M.current.axWindow():attributeValue("AXFrame")
	local contentArea = M.current.axContentArea()

	if not contentArea then
		return winFrame
	end

	local contentFrame = contentArea:attributeValue("AXFrame")

	local scrollFrame = M.current.axScrollArea() and M.current.axScrollArea():attributeValue("AXFrame") or contentFrame

	local visibleX = math.max(winFrame.x, contentFrame.x)
	local visibleY = math.max(winFrame.y, scrollFrame.y)

	local visibleWidth = math.min(winFrame.x + winFrame.w, contentFrame.x + contentFrame.w) - visibleX
	local visibleHeight = math.min(winFrame.y + winFrame.h, contentFrame.y + contentFrame.h) - visibleY

	M.cached.visibleArea = {
		x = visibleX,
		y = visibleY,
		w = visibleWidth,
		h = visibleHeight,
	}

	M.logWithTimestamp("visibleArea: " .. hs.inspect(M.cached.visibleArea))

	return M.cached.visibleArea
end

M.getFocusedElement = function(element, depth)
	if not element or (depth and depth > M.config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not M.marks.isElementPartiallyVisible(element) then
		return
	end

	if element:attributeValue("AXFocused") then
		M.logWithTimestamp("Focused element found: " .. hs.inspect(element))
		element:setAttributeValue("AXFocused", false)
		M.logWithTimestamp("Focused element unfocused.")
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				M.getFocusedElement(children[j], (depth or 0) + 1)
			end
		end
	end
end

M.getElementPositionAndSize = function(element)
	local frame = element:attributeValue("AXFrame")
	if frame then
		return { x = frame.x, y = frame.y }, { w = frame.w, h = frame.h }
	end

	local successPos, position = pcall(function()
		return element:attributeValue("AXPosition")
	end)
	local successSize, size = pcall(function()
		return element:attributeValue("AXSize")
	end)

	if successPos and successSize and position and size then
		return position, size
	end

	return nil, nil
end

--------------------------------------------------------------------------------
-- Helper & Action Functions
--------------------------------------------------------------------------------

M.fetchMappingPrefixes = function()
	for k, _ in pairs(M.config.mapping) do
		if #k == 2 then
			M.mappingPrefixes[sub(k, 1, 1)] = true
		end
	end
	M.logWithTimestamp("mappingPrefixes: " .. hs.inspect(M.mappingPrefixes))
end

M.findAXRole = function(rootElement, role)
	if rootElement:attributeValue("AXRole") == role then
		return rootElement
	end

	for _, child in ipairs(rootElement:attributeValue("AXChildren") or {}) do
		local result = M.findAXRole(child, role)
		if result then
			return result
		end
	end
end

M.isEditableControlInFocus = function()
	if M.current.axFocusedElement() then
		return M.tblContains(M.config.axEditableRoles, M.current.axFocusedElement():attributeValue("AXRole"))
	else
		return false
	end
end

M.isExcludedApp = function()
	local appName = M.current.app():name()
	return M.tblContains(M.config.excludedApps, appName)
end

M.isSpotlightActive = function()
	local app = hs.application.get("Spotlight")
	local appElement = hs.axuielement.applicationElement(app)
	local windows = appElement:attributeValue("AXWindows")
	return #windows > 0
end

M.generateCombinations = function()
	local chars = "abcdefghijklmnopqrstuvwxyz"
	for i = 1, #chars do
		for j = 1, #chars do
			insert(M.allCombinations, chars:sub(i, i) .. chars:sub(j, j))
		end
	end
end

--- @param x number|nil # The horizontal scroll amount in pixels (can be `nil` for vertical-only scrolling).
--- @param y number|nil # The vertical scroll amount in pixels (can be `nil` for horizontal-only scrolling).
--- @param smooth boolean # Whether to perform smooth scrolling.
M.smoothScroll = function(x, y, smooth)
	if not smooth then
		eventtap.event.newScrollEvent({ x, y }, {}, "pixel"):post()
		return
	end

	local steps = 5
	local dx = 0
	local dy = 0

	if x then
		dx = x / steps
	end
	if y then
		dy = y / steps
	end
	local frame = 0

	local interval = 1 / M.config.smoothScrollFrameRate

	local function animate()
		frame = frame + 1
		if frame > steps then
			return
		end

		local factor = frame <= steps / 2 and 2 or 0.5
		eventtap.event.newScrollEvent({ dx * factor, dy * factor }, {}, "pixel"):post()

		timer.doAfter(interval, animate) -- ~60fps
	end

	animate()
end

--- @param url string # The URL to open in a new browser tab.
M.openUrlInNewTab = function(url)
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

	local currentApp = M.current.app():name()
	local script

	if browserScripts[currentApp] then
		script = format(browserScripts[currentApp], url)
	else
		-- Fallback to Safari if not a known browser
		script = format(browserScripts["Safari"], url)
	end

	hs.osascript.applescript(script)
end

--- @param contents string|nil # The text to copy to the clipboard. If `nil`, the operation will fail.
M.setClipboardContents = function(contents)
	if contents and hs.pasteboard.setContents(contents) then
		hs.alert.show("Copied to clipboard: " .. contents, nil, nil, 4)
	else
		hs.alert.show("Failed to copy to clipboard", nil, nil, 4)
	end
end

M.forceUnfocus = function()
	M.logWithTimestamp("forced unfocus on escape")

	local startElement = M.current.axWindow()
	if not startElement then
		return
	end

	M.getFocusedElement(startElement, 0)
	hs.alert.show("Force unfocused!")
end

M.restoreMousePosition = function(originalPosition)
	timer.doAfter(0.05, function()
		mouse.absolutePosition(originalPosition)
	end)
end

M.isInBrowser = function()
	local currentAppName = M.current.app():name()

	return M.tblContains(M.config.browsers, currentAppName)
end

--------------------------------------------------------------------------------
-- Menubar
--------------------------------------------------------------------------------

function M.menuBar.new()
	if M.menuBar.item then
		M.menuBar.delete()
	end
	M.menuBar.item = hs.menubar.new()
end

function M.menuBar.delete()
	if M.menuBar.item then
		M.menuBar.item:delete()
	end
	M.menuBar.item = nil
end

--- @param mode integer # The mode to set. Expected values are in `M.modes`.
--- @param char string|nil # An optional character representing the mode in the menu bar.
M.setMode = function(mode, char)
	local defaultModeChars = {
		[M.modes.DISABLED] = "X",
		[M.modes.NORMAL] = "V",
	}

	local previousMode = M.current.mode
	M.current.mode = mode

	if M.current.mode == M.modes.LINKS and previousMode ~= M.modes.LINKS then
		M.linkCapture = ""
		M.marks.clear()
	end
	if previousMode == M.modes.LINKS and M.current.mode ~= M.modes.LINKS then
		M.linkCapture = nil
		timer.doAfter(0, M.marks.clear)
	end

	if M.current.mode == M.modes.MULTI then
		M.current.multi = char
	end
	if M.current.mode ~= M.modes.MULTI then
		M.current.multi = nil
	end

	M.menuBar.item:setTitle(char or defaultModeChars[mode] or "?")
end

--------------------------------------------------------------------------------
-- Marks
--------------------------------------------------------------------------------

M.marks.clear = function()
	if M.marks.canvas then
		M.marks.canvas:delete()
	end
	M.marks.canvas = nil
	M.marks.data = {}
end

M.marks.draw = function()
	if not M.marks.canvas then
		M.marks.canvas = hs.canvas.new(M.current.visibleArea())
	end

	local elementsToDraw = {}
	for i, _ in ipairs(M.marks.data) do
		local element = M.marks.prepareElementForDrawing(i)
		if element then
			table.move(element, 1, #element, #elementsToDraw + 1, elementsToDraw)
		end
	end

	if #elementsToDraw > 0 then
		M.marks.canvas:replaceElements(elementsToDraw)
		M.marks.canvas:show()
	else
		M.marks.canvas:hide()
	end
end

--- @param markIndex number # The index of the mark in `M.marks.data`.
--- @return table|nil # A table representing the graphical elements to draw or `nil` if the mark is invalid.
M.marks.prepareElementForDrawing = function(markIndex)
	local mark = M.marks.data[markIndex]
	if not mark then
		return nil
	end

	local position = mark.element:attributeValue("AXFrame")
	if not position then
		return nil
	end

	local padding = 2
	local fontSize = 14
	local bgRect = hs.geometry.rect(position.x, position.y, fontSize * 1.5 + 2 * padding, fontSize + 2 * padding)
	local visibleArea = M.current.visibleArea()

	return {
		{
			type = "rectangle",
			fillColor = { red = 0.5, green = 1, blue = 0, alpha = 0.9 },
			strokeColor = { ["red"] = 0, ["green"] = 0, ["blue"] = 0, ["alpha"] = 1 },
			strokeWidth = 1,
			roundedRectRadii = { xRadius = 3, yRadius = 3 },
			frame = {
				x = bgRect.x - visibleArea.x,
				y = bgRect.y - visibleArea.y,
				w = bgRect.w,
				h = bgRect.h,
			},
		},
		{
			type = "text",
			text = string.upper(M.allCombinations[markIndex]),
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
		},
	}
end

M.marks.add = function(element)
	insert(M.marks.data, { element = element })
end

M.marks.isElementPartiallyVisible = function(element)
	local frame = element and not element:attributeValue("AXHidden") and element:attributeValue("AXFrame")
	if not frame or frame.w <= 0 or frame.h <= 0 then
		return false
	end

	local visibleArea = M.current.visibleArea()
	local vx, vy, vw, vh = visibleArea.x, visibleArea.y, visibleArea.w, visibleArea.h
	local fx, fy, fw, fh = frame.x, frame.y, frame.w, frame.h

	return fx < vx + vw and fx + fw > vx and fy < vy + vh and fy + fh > vy
end

M.marks.isElementActionable = function(element)
	if not element then
		return false
	end

	local role = element:attributeValue("AXRole")
	if not role then
		return false
	end

	return M.tblContains(M.config.axJumpableRoles, role)
end

M.marks.isElementScrollable = function(element)
	if not element then
		return false
	end

	local role = element:attributeValue("AXRole")
	if not role then
		return false
	end

	local axScrollableRoles = M.config.axScrollableRoles

	return M.tblContains(axScrollableRoles, role)
end

M.marks.isElementInput = function(element)
	if not element then
		return false
	end

	local role = element:attributeValue("AXRole")
	if not role then
		return false
	end

	local axEditableRoles = M.config.axEditableRoles

	return M.tblContains(axEditableRoles, role)
end

M.marks.getAllDescendants = function(element)
	if not element then
		return {}
	end

	local toProcess, results = { element }, {}
	local index = 1

	while index <= #toProcess do
		local currentIndex = toProcess[index]
		local children = currentIndex:attributeValue("AXChildren")

		if children then
			for _, child in ipairs(children) do
				table.insert(toProcess, child)
			end
		else
			table.insert(results, currentIndex)
		end

		index = index + 1
	end

	return results
end

M.marks.findClickableElements = function(element, withUrls, depth)
	if not element or (depth and depth > M.config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not M.marks.isElementPartiallyVisible(element) then
		return
	end

	if M.marks.isElementActionable(element) and (not withUrls or element:attributeValue("AXURL")) then
		M.marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				M.marks.findClickableElements(children[j], withUrls, (depth or 0) + 1)
			end
		end
	end
end

M.marks.findScrollableElements = function(element, depth)
	if not element or (depth and depth > M.config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not M.marks.isElementPartiallyVisible(element) then
		return
	end

	if M.marks.isElementScrollable(element) then
		M.marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				M.marks.findScrollableElements(children[j], (depth or 0) + 1)
			end
		end
	end
end

M.marks.findUrlElements = function(element, depth)
	if not element or (depth and depth > M.config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not M.marks.isElementPartiallyVisible(element) then
		return
	end

	if element:attributeValue("AXURL") then
		M.marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				M.marks.findUrlElements(children[j], (depth or 0) + 1)
			end
		end
	end
end

M.marks.findInputElements = function(element, depth)
	if not element or (depth and depth > M.config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not M.marks.isElementPartiallyVisible(element) then
		return
	end

	if M.marks.isElementInput(element) then
		M.marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				M.marks.findInputElements(children[j], (depth or 0) + 1)
			end
		end
	end
end

--- @param withUrls boolean # If true, includes URLs when finding clickable elements.
--- @param type "link"|"scroll"|"url"|"input" # The type of elements to find ("link", "scroll", "url", "input").
M.marks.show = function(withUrls, type)
	local startElement = M.current.axWindow()
	if not startElement then
		return
	end

	M.logWithTimestamp("startElement: " .. hs.inspect(startElement))

	M.marks.clear()

	if type == "link" then
		M.marks.findClickableElements(startElement, withUrls, 0)
	end

	if type == "scroll" then
		M.marks.findScrollableElements(startElement, 0)
	end

	if type == "url" then
		M.marks.findUrlElements(startElement, 0)
	end

	if type == "input" then
		M.marks.findInputElements(startElement, 0)
		if #M.marks.data == 1 then
			M.marks.onClickCallback(M.marks.data[1])
			M.setMode(M.modes.NORMAL)
			return
		end
	end

	if #M.marks.data > 0 then
		M.marks.draw()
	else
		hs.alert.show("No elements found")
		M.setMode(M.modes.NORMAL)
	end
end

--- @param combination string # The combination that matches the element to be clicked.
M.marks.click = function(combination)
	M.logWithTimestamp("M.marks.click")
	for i, c in ipairs(M.allCombinations) do
		if c == combination and M.marks.data[i] and M.marks.onClickCallback then
			local mark = M.marks.data[i]
			if mark then
				local success, err = pcall(M.marks.onClickCallback, mark)
				if not success then
					M.logWithTimestamp("Error clicking element: " .. tostring(err))
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

M.commands.cmdScrollLeft = function()
	M.smoothScroll(M.config.scrollStep, 0, M.config.smoothScroll)
end

M.commands.cmdScrollRight = function()
	M.smoothScroll(-M.config.scrollStep, 0, M.config.smoothScroll)
end

M.commands.cmdScrollUp = function()
	M.smoothScroll(0, M.config.scrollStep, M.config.smoothScroll)
end

M.commands.cmdScrollDown = function()
	M.smoothScroll(0, -M.config.scrollStep, M.config.smoothScroll)
end

M.commands.cmdScrollHalfPageDown = function()
	M.smoothScroll(0, -M.config.scrollStepHalfPage, M.config.smoothScroll)
end

M.commands.cmdScrollHalfPageUp = function()
	M.smoothScroll(0, M.config.scrollStepHalfPage, M.config.smoothScroll)
end

M.commands.cmdScrollToTop = function()
	M.smoothScroll(0, -M.config.scrollStepFullPage, M.config.smoothScroll)
end

M.commands.cmdScrollToBottom = function()
	M.smoothScroll(0, M.config.scrollStepFullPage, M.config.smoothScroll)
end

M.commands.cmdCopyPageUrlToClipboard = function()
	if M.isInBrowser() then
		local element = M.current.axWebArea()
		local url = element and element:attributeValue("AXURL")
		if url then
			M.setClipboardContents(url.url)
		end
	else
		hs.alert.show("Copy page url is only available for browser")
	end
end

--- @param char string|nil # Optional character to display for the INSERT mode in the menu bar.
M.commands.cmdInsertMode = function(char)
	M.setMode(M.modes.INSERT, char)
end

M.commands.cmdGotoLink = function(char)
	M.setMode(M.modes.LINKS, char)
	M.marks.onClickCallback = function(mark)
		local element = mark.element
		if not element then
			M.logWithTimestamp("Error: Invalid element")
			return
		end

		local actions = element:actionNames()

		M.logWithTimestamp("actions available: " .. hs.inspect(actions))

		if M.tblContains(actions, "AXPress") then
			mark.element:performAction("AXPress")
			M.logWithTimestamp("Success AXPress")
		else
			-- Try different methods to get position
			local position, size = M.getElementPositionAndSize(element)

			if position and size then
				local clickX = position.x + (size.w / 2)
				local clickY = position.y + (size.h / 2)
				local originalPosition = mouse.absolutePosition()

				local clickSuccess, clickErr = pcall(function()
					mouse.absolutePosition({ x = clickX, y = clickY })
					eventtap.leftClick({ x = clickX, y = clickY })
					M.restoreMousePosition(originalPosition)
				end)

				if clickSuccess then
					return
				else
					M.logWithTimestamp("Click failed: " .. tostring(clickErr))
				end
			end

			-- Fallback: Click using mark coordinates
			if mark.x and mark.y then
				local clickSuccess, clickErr = pcall(function()
					local originalPosition = mouse.absolutePosition()
					mouse.absolutePosition({ x = mark.x, y = mark.y })
					eventtap.leftClick({ x = mark.x, y = mark.y })
					M.restoreMousePosition(originalPosition)
				end)

				if clickSuccess then
					return
				else
					M.logWithTimestamp("Mark click failed: " .. tostring(clickErr))
				end
			end

			-- Final fallback: focus + return key
			M.logWithTimestamp("Falling back to focus + return method")
			local focusSuccess, focusErr = pcall(function()
				element:setAttributeValue("AXFocused", true)
				timer.doAfter(0.1, function()
					eventtap.keyStroke({}, "return", 0)
				end)
			end)

			if not focusSuccess then
				M.logWithTimestamp("Focus fallback failed: " .. tostring(focusErr))
			end
		end
	end
	timer.doAfter(0, function()
		M.marks.show(false, "link")
	end)
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
M.commands.cmdRightClick = function(char)
	M.setMode(M.modes.LINKS, char)

	M.marks.onClickCallback = function(mark)
		local element = mark.element
		if not element then
			M.logWithTimestamp("Error: Invalid element")
			return
		end

		local actions = element:actionNames()

		M.logWithTimestamp(hs.inspect(actions))

		if M.tblContains(actions, "AXShowMenu") then
			mark.element:performAction("AXShowMenu")
			M.logWithTimestamp("Success AXShowMenu")
		else
			local position, size = M.getElementPositionAndSize(element)

			if position and size then
				local clickX = position.x + (size.w / 2)
				local clickY = position.y + (size.h / 2)
				local originalPosition = mouse.absolutePosition()

				local clickSuccess, clickErr = pcall(function()
					mouse.absolutePosition({ x = clickX, y = clickY })
					eventtap.rightClick({ x = clickX, y = clickY })
					M.restoreMousePosition(originalPosition)
				end)

				if clickSuccess then
					return
				else
					M.logWithTimestamp("Right-click failed: " .. tostring(clickErr))
				end
			end
		end
	end

	timer.doAfter(0, function()
		M.marks.show(false, "link")
	end)
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
M.commands.cmdGotoLinkNewTab = function(char)
	if M.isInBrowser() then
		M.setMode(M.modes.LINKS, char)
		M.marks.onClickCallback = function(mark)
			local axURL = mark.element:attributeValue("AXURL")
			if axURL then
				M.openUrlInNewTab(axURL.url)
			end
		end
		timer.doAfter(0, function()
			M.marks.show(true, "link")
		end)
	else
		hs.alert.show("Go to Link New Tab is only available for browser")
	end
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
M.commands.cmdGotoInput = function(char)
	if M.isInBrowser() then
		M.setMode(M.modes.LINKS, char)
		M.marks.onClickCallback = function(mark)
			local element = mark.element
			if not element then
				M.logWithTimestamp("Error: Invalid element")
				return
			end

			local actions = element:actionNames()

			M.logWithTimestamp("actions available: " .. hs.inspect(actions))

			if M.tblContains(actions, "AXPress") then
				mark.element:performAction("AXPress")
				M.logWithTimestamp("Success AXPress")
			else
				-- Try different methods to get position
				local position, size = M.getElementPositionAndSize(element)

				if position and size then
					local clickX = position.x + (size.w / 2)
					local clickY = position.y + (size.h / 2)
					local originalPosition = mouse.absolutePosition()

					local clickSuccess, clickErr = pcall(function()
						mouse.absolutePosition({ x = clickX, y = clickY })
						eventtap.leftClick({ x = clickX, y = clickY })
						M.restoreMousePosition(originalPosition)
					end)

					if clickSuccess then
						return
					else
						M.logWithTimestamp("Click failed: " .. tostring(clickErr))
					end
				end

				-- Fallback: Click using mark coordinates
				if mark.x and mark.y then
					local clickSuccess, clickErr = pcall(function()
						local originalPosition = mouse.absolutePosition()
						mouse.absolutePosition({ x = mark.x, y = mark.y })
						eventtap.leftClick({ x = mark.x, y = mark.y })
						M.restoreMousePosition(originalPosition)
					end)

					if clickSuccess then
						return
					else
						M.logWithTimestamp("Mark click failed: " .. tostring(clickErr))
					end
				end

				-- Final fallback: focus + return key
				M.logWithTimestamp("Falling back to focus + return method")
				local focusSuccess, focusErr = pcall(function()
					element:setAttributeValue("AXFocused", true)
					timer.doAfter(0.1, function()
						eventtap.keyStroke({}, "return", 0)
					end)
				end)

				if not focusSuccess then
					M.logWithTimestamp("Focus fallback failed: " .. tostring(focusErr))
				end
			end
		end
		timer.doAfter(0, function()
			M.marks.show(true, "input")
		end)
	else
		hs.alert.show("Go to input is only available for browser")
	end
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
M.commands.cmdMoveMouseToLink = function(char)
	M.setMode(M.modes.LINKS, char)
	M.marks.onClickCallback = function(mark)
		local frame = mark.element:attributeValue("AXFrame")
		mouse.absolutePosition({ x = frame.x + frame.w / 2, y = frame.y + frame.h / 2 })
	end
	timer.doAfter(0, function()
		M.marks.show(true, "scroll")
	end)
end

M.commands.cmdMoveMouseToCenter = function()
	mouse.absolutePosition({
		x = M.current.visibleArea().x + M.current.visibleArea().w / 2,
		y = M.current.visibleArea().y + M.current.visibleArea().h / 2,
	})
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
M.commands.cmdCopyLinkUrlToClipboard = function(char)
	if M.isInBrowser() then
		M.setMode(M.modes.LINKS, char)
		M.marks.onClickCallback = function(mark)
			local axURL = mark.element:attributeValue("AXURL")
			M.setClipboardContents(axURL.url)
		end
		timer.doAfter(0, function()
			M.marks.show(true, "url")
		end)
	else
		hs.alert.show("Copy link url is only available for browser")
	end
end

--------------------------------------------------------------------------------
--- Event Handling and Input Processing
--------------------------------------------------------------------------------

--- @param char string # The character input that triggers specific actions or commands.
M.vimLoop = function(char)
	M.logWithTimestamp("vimLoop " .. char)

	if M.current.mode == M.modes.LINKS then
		M.linkCapture = M.linkCapture .. char:lower()
		if #M.linkCapture == 2 then
			M.marks.click(M.linkCapture)
			M.setMode(M.modes.NORMAL)
		end
		return
	end

	if M.current.mode == M.modes.MULTI then
		char = M.current.multi .. char
	end
	local foundMapping = M.config.mapping[char]

	if foundMapping then
		M.setMode(M.modes.NORMAL)

		if type(foundMapping) == "string" then
			M.commands[foundMapping](char)
		elseif type(foundMapping) == "table" then
			eventtap.keyStroke(foundMapping[1], foundMapping[2], 0)
		else
			M.logWithTimestamp("Unknown mapping for " .. char .. " " .. hs.inspect(foundMapping))
		end
	elseif M.mappingPrefixes[char] then
		M.setMode(M.modes.MULTI, char)
	else
		M.logWithTimestamp("Unknown char " .. char)
	end
end

M.eventHandler = function(event)
	M.cached = setmetatable({}, { __mode = "k" })

	if M.isExcludedApp() then
		return false
	end

	for key, modifier in pairs(event:getFlags()) do
		if modifier and key ~= "shift" then
			return false
		end
	end

	if M.isSpotlightActive() then
		return false
	end

	if event:getKeyCode() == hs.keycodes.map["escape"] then
		local delaySinceLastEscape = (timer.absoluteTime() - M.lastEscape) / 1e9 -- nanoseconds in seconds
		M.lastEscape = timer.absoluteTime()

		if M.isInBrowser() and delaySinceLastEscape < M.config.doublePressDelay then
			M.setMode(M.modes.NORMAL)
			M.forceUnfocus()
			return true
		end

		if M.current.mode ~= M.modes.NORMAL then
			M.setMode(M.modes.NORMAL)
			return true
		end

		return false
	end

	if M.current.mode == M.modes.INSERT or M.isEditableControlInFocus() then
		return false
	end

	local char = event:getCharacters()
	if not char:match("[%a%d%[%]%$]") then
		return false
	end

	timer.doAfter(0, function()
		M.vimLoop(char)
	end)
	return true
end

local function onWindowFocused()
	M.logWithTimestamp("onWindowFocused")
	if not M.eventLoop then
		M.eventLoop = eventtap.new({ hs.eventtap.event.types.keyDown }, M.eventHandler):start()
	end
	if not M.isExcludedApp() then
		M.setMode(M.modes.NORMAL)
	else
		M.setMode(M.modes.DISABLED)
	end
end

local function onWindowUnfocused()
	M.logWithTimestamp("onWindowUnfocused")
	if M.eventLoop then
		M.eventLoop:stop()
		M.eventLoop = nil
	end
	M.setMode(M.modes.DISABLED)
end

--------------------------------------------------------------------------------
-- Module Initialization and Cleanup
--------------------------------------------------------------------------------

function M:start()
	M.windowFilter = hs.window.filter.new()
	M.windowFilter:subscribe(hs.window.filter.windowFocused, onWindowFocused)
	M.windowFilter:subscribe(hs.window.filter.windowUnfocused, onWindowUnfocused)
	M.menuBar.new()
	M.fetchMappingPrefixes()
	M.generateCombinations()
end

function M:stop()
	if M.windowFilter then
		M.windowFilter:unsubscribe(onWindowFocused)
		M.windowFilter:unsubscribe(onWindowUnfocused)
		M.windowFilter = nil
	end
	M.menuBar.delete()
end

return M
