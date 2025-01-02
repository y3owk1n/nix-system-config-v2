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

--------------------------------------------------------------------------------
-- Constants and Configuration
--------------------------------------------------------------------------------

local modes = { DISABLED = 1, NORMAL = 2, INSERT = 3, MULTI = 4, LINKS = 5 }

local mapping = {
	["i"] = "cmdInsertMode",
	-- movements
	["h"] = "cmdScrollLeft",
	["j"] = "cmdScrollDown",
	["k"] = "cmdScrollUp",
	["l"] = "cmdScrollRight",
	["C-d"] = "cmdScrollHalfPageDown",
	["C-u"] = "cmdScrollHalfPageUp",
	["gg"] = "cmdScrollToBottom",
	["G"] = "cmdScrollToTop",
	["H"] = { "cmd", "[" }, -- history back
	["L"] = { "cmd", "]" }, -- history forward
	["f"] = "cmdGotoLink",
	["r"] = "cmdRightClick",
	["F"] = "cmdGotoLinkNewTab",
	["di"] = "cmdDownloadImage",
	["gf"] = "cmdMoveMouseToLink",
	["gi"] = "cmdGotoInput",
	["zz"] = "cmdMoveMouseToCenter",
	["yy"] = "cmdCopyPageUrlToClipboard",
	["yf"] = "cmdCopyLinkUrlToClipboard",
}

local config = {
	doublePressDelay = 0.3, -- seconds
	showLogs = false,
	mapping = mapping,
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
		"AXCheckBox",
		"AXRadioButton",
		"AXDisclosureTriangle",
		-- "AXStaticText",
		-- "AXMenuItem",
		-- "AXMenu",
		-- "AXMenuButton",
		-- "AXToolbar",
		-- "AXToolbarButton",
		-- "AXTabGroup",
		-- "AXTab",
		-- "AXSlider",
		-- "AXIncrementor",
		-- "AXDecrementor",
	},
	axScrollableRoles = {
		"AXScrollArea",
		-- "AXScrollView",
		-- "AXOverflow",
		"AXGroup", -- use AXGroup seems to be making the most sense to me
		-- "AXScrollable",
		-- "AXHorizontalScroll",
		-- "AXVerticalScroll",
		-- "AXWebArea",
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
-- State & Cache Management
--------------------------------------------------------------------------------

local state = {
	elements = {},
	marks = {},
	windowFilter = nil,
	eventLoop = nil,
	linkCapture = nil,
	lastEscape = timer.absoluteTime(),
	mappingPrefixes = {},
	allCombinations = {},
}

local marks = {}
local actions = {}
local menuBar = {}
local commands = {}
local utils = {}

local cached = setmetatable({}, { __mode = "k" })

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

--- @param message string # The message to log.
local function log(message)
	if not config.showLogs then
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
local function tblContains(tbl, val)
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
local function tblFilter(tbl, predicate)
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

function state.elements.app()
	cached.app = cached.app or hs.application.frontmostApplication()
	return cached.app
end

function state.elements.axApp()
	cached.axApp = cached.axApp or hs.axuielement.applicationElement(state.elements.app())
	return cached.axApp
end

function state.elements.window()
	cached.window = cached.window or state.elements.app():focusedWindow()
	return cached.window
end

function state.elements.axWindow()
	cached.axWindow = cached.axWindow or hs.axuielement.windowElement(state.elements.window())
	return cached.axWindow
end

function state.elements.axFocusedElement()
	cached.axFocusedElement = cached.axFocusedElement or state.elements.axApp():attributeValue("AXFocusedUIElement")
	return cached.axFocusedElement
end

function state.elements.axScrollArea()
	if not cached.axScrollArea then
		for _, role in ipairs(config.axScrollableRoles) do
			cached.axScrollArea = state.elements.findAXRole(state.elements.axWindow(), role)
			if cached.axScrollArea then
				break
			end
		end
	end
	return cached.axScrollArea
end

function state.elements.axWebArea()
	cached.axWebArea = cached.axWebArea or state.elements.findAXRole(state.elements.axScrollArea(), "AXWebArea")
	return cached.axWebArea
end

function state.elements.visibleArea()
	if cached.visibleArea then
		return cached.visibleArea
	end

	local winFrame = state.elements.axWindow():attributeValue("AXFrame")

	local visibleX = math.max(winFrame.x)
	local visibleY = math.max(winFrame.y)

	local visibleWidth = math.min(winFrame.x + winFrame.w) - visibleX
	local visibleHeight = math.min(winFrame.y + winFrame.h) - visibleY

	cached.visibleArea = {
		x = visibleX,
		y = visibleY,
		w = visibleWidth,
		h = visibleHeight,
	}

	log("visibleArea: " .. hs.inspect(cached.visibleArea))

	return cached.visibleArea
end

function state.elements.getFocusedElement(element, depth)
	if not element or (depth and depth > config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not marks.isElementPartiallyVisible(element) then
		return
	end

	if element:attributeValue("AXFocused") then
		log("Focused element found: " .. hs.inspect(element))
		element:setAttributeValue("AXFocused", false)
		log("Focused element unfocused.")
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				state.elements.getFocusedElement(children[j], (depth or 0) + 1)
			end
		end
	end
end

function state.elements.getElementPositionAndSize(element)
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

function state.elements.findAXRole(rootElement, role)
	if rootElement:attributeValue("AXRole") == role then
		return rootElement
	end

	for _, child in ipairs(rootElement:attributeValue("AXChildren") or {}) do
		local result = state.elements.findAXRole(child, role)
		if result then
			return result
		end
	end
end

function state.elements.isEditableControlInFocus()
	if state.elements.axFocusedElement() then
		return tblContains(config.axEditableRoles, state.elements.axFocusedElement():attributeValue("AXRole"))
	else
		return false
	end
end

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

function utils.fetchMappingPrefixes()
	for k, _ in pairs(config.mapping) do
		if #k == 2 then
			state.mappingPrefixes[sub(k, 1, 1)] = true
		end
	end
	log("mappingPrefixes: " .. hs.inspect(state.mappingPrefixes))
end

function utils.isExcludedApp()
	local appName = state.elements.app():name()
	return tblContains(config.excludedApps, appName)
end

function utils.isSpotlightActive()
	local app = hs.application.get("Spotlight")
	local appElement = hs.axuielement.applicationElement(app)
	local windows = appElement:attributeValue("AXWindows")
	return #windows > 0
end

function utils.generateCombinations()
	local chars = "abcdefghijklmnopqrstuvwxyz"
	for i = 1, #chars do
		for j = 1, #chars do
			insert(state.allCombinations, chars:sub(i, i) .. chars:sub(j, j))
		end
	end
end

function utils.isInBrowser()
	local currentAppName = state.elements.app():name()

	return tblContains(config.browsers, currentAppName)
end

--- @param mode integer # The mode to set. Expected values are in `M.modes`.
--- @param char string|nil # An optional character representing the mode in the menu bar.
function utils.setMode(mode, char)
	local defaultModeChars = {
		[modes.DISABLED] = "X",
		[modes.NORMAL] = "V",
	}

	local previousMode = state.elements.mode
	state.elements.mode = mode

	if state.elements.mode == modes.LINKS and previousMode ~= modes.LINKS then
		state.linkCapture = ""
		marks.clear()
	end
	if previousMode == modes.LINKS and state.elements.mode ~= modes.LINKS then
		state.linkCapture = nil
		timer.doAfter(0, marks.clear)
	end

	if state.elements.mode == modes.MULTI then
		state.elements.multi = char
	end
	if state.elements.mode ~= modes.MULTI then
		state.elements.multi = nil
	end

	menuBar.item:setTitle(char or defaultModeChars[mode] or "?")
end

--------------------------------------------------------------------------------
-- Action Functions
--------------------------------------------------------------------------------

--- @param x number|nil # The horizontal scroll amount in pixels (can be `nil` for vertical-only scrolling).
--- @param y number|nil # The vertical scroll amount in pixels (can be `nil` for horizontal-only scrolling).
--- @param smooth boolean # Whether to perform smooth scrolling.
function actions.smoothScroll(x, y, smooth)
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

	local interval = 1 / config.smoothScrollFrameRate

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
function actions.openUrlInNewTab(url)
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

	local currentApp = state.elements.app():name()
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
function actions.setClipboardContents(contents)
	if contents and hs.pasteboard.setContents(contents) then
		hs.alert.show("Copied to clipboard: " .. contents, nil, nil, 4)
	else
		hs.alert.show("Failed to copy to clipboard", nil, nil, 4)
	end
end

function actions.forceUnfocus()
	log("forced unfocus on escape")

	local startElement = state.elements.axWindow()
	if not startElement then
		return
	end

	state.elements.getFocusedElement(startElement, 0)
	hs.alert.show("Force unfocused!")
end

function actions.restoreMousePosition(originalPosition)
	timer.doAfter(0.05, function()
		mouse.absolutePosition(originalPosition)
	end)
end

--------------------------------------------------------------------------------
-- Menubar
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

--------------------------------------------------------------------------------
-- Marks
--------------------------------------------------------------------------------

function marks.clear()
	if marks.canvas then
		marks.canvas:delete()
	end
	marks.canvas = nil
	state.marks = {}
end

function marks.draw()
	if not marks.canvas then
		marks.canvas = hs.canvas.new(state.elements.visibleArea())
	end

	local elementsToDraw = {}
	for i, _ in ipairs(state.marks) do
		local element = marks.prepareElementForDrawing(i)
		if element then
			table.move(element, 1, #element, #elementsToDraw + 1, elementsToDraw)
		end
	end

	if #elementsToDraw > 0 then
		marks.canvas:replaceElements(elementsToDraw)
		marks.canvas:show()
	else
		marks.canvas:hide()
	end
end

--- @param markIndex number # The index of the mark in `state.marks`.
--- @return table|nil # A table representing the graphical elements to draw or `nil` if the mark is invalid.
function marks.prepareElementForDrawing(markIndex)
	local mark = state.marks[markIndex]
	if not mark then
		return nil
	end

	local position, size = state.elements.getElementPositionAndSize(mark.element)
	if not position or not size then
		return nil
	end

	local padding = 2
	local fontSize = 10
	local text = string.upper(state.allCombinations[markIndex])

	local textWidth = #text * (fontSize * 1.1) -- Approximate adjustment
	local textHeight = fontSize * 1.1 -- Approximate adjustment

	local containerWidth = textWidth + (padding * 2)
	local containerHeight = textHeight + (padding * 2)

	local arrowHeight = 3
	local arrowWidth = 6
	local cornerRadius = 2

	local fillColor = { red = 1, green = 0.96, blue = 0.52, alpha = 1 }
	local borderColor = { red = 0, green = 0, blue = 0, alpha = 1 }
	local gradientColor = {
		red = 1,
		green = 0.77,
		blue = 0.26,
		alpha = 1,
	}

	local bgRect = hs.geometry.rect(
		position.x + (size.w / 2) - (containerWidth / 2),
		position.y + (size.h / 3 * 2) + arrowHeight,
		containerWidth,
		containerHeight
	)
	local visibleArea = state.elements.visibleArea()

	local rx = bgRect.x - visibleArea.x
	local ry = bgRect.y - visibleArea.y
	local rw = bgRect.w
	local rh = bgRect.h

	local arrowLeft = rx + (rw / 2) - (arrowWidth / 2)
	local arrowRight = arrowLeft + arrowWidth
	local arrowTop = ry - arrowHeight
	local arrowBottom = ry
	local arrowMiddle = arrowLeft + (arrowWidth / 2)

	return {
		{
			type = "segments",
			fillGradient = "linear",
			fillGradientColors = { fillColor, gradientColor },
			fillGradientAngle = 135,
			strokeColor = borderColor,
			strokeWidth = 1,
			withShadow = true,
			shadow = { blurRadius = 5.0, color = { alpha = 1 / 3 }, offset = { h = -1.0, w = 1.0 } },
			closed = true,
			coordinates = {
				-- Draw arrow
				{ x = arrowLeft, y = arrowBottom },
				{ x = arrowMiddle, y = arrowTop },
				{ x = arrowRight, y = arrowBottom },
				-- Top right corner
				{
					x = rx + rw - cornerRadius,
					y = ry,
					c1x = rx + rw - cornerRadius,
					c1y = ry,
					c2x = rx + rw,
					c2y = ry,
				},
				{ x = rx + rw, y = ry + cornerRadius, c1x = rx + rw, c1y = ry, c2x = rx + rw, c2y = ry + cornerRadius },
				-- Bottom right corner
				{
					x = rx + rw,
					y = ry + rh - cornerRadius,
					c1x = rx + rw,
					c1y = ry + rh - cornerRadius,
					c2x = rx + rw,
					c2y = ry + rh,
				},
				{
					x = rx + rw - cornerRadius,
					y = ry + rh,
					c1x = rx + rw,
					c1y = ry + rh,
					c2x = rx + rw - cornerRadius,
					c2y = ry + rh,
				},
				-- Bottom left corner
				{
					x = rx + cornerRadius,
					y = ry + rh,
					c1x = rx + cornerRadius,
					c1y = ry + rh,
					c2x = rx,
					c2y = ry + rh,
				},
				{
					x = rx,
					y = ry + rh - cornerRadius,
					c1x = rx,
					c1y = ry + rh,
					c2x = rx,
					c2y = ry + rh - cornerRadius,
				},
				-- Top left corner
				{ x = rx, y = ry + cornerRadius, c1x = rx, c1y = ry + cornerRadius, c2x = rx, c2y = ry },
				{ x = rx + cornerRadius, y = ry, c1x = rx, c1y = ry, c2x = rx + cornerRadius, c2y = ry },
				-- Back to start
				{ x = arrowLeft, y = arrowBottom },
			},
		},
		{
			type = "text",
			text = text,
			textAlignment = "center",
			textColor = { ["red"] = 0, ["green"] = 0, ["blue"] = 0, ["alpha"] = 1 },
			textSize = fontSize,
			textFont = ".AppleSystemUIFontHeavy",
			textLineBreak = "clip",
			frame = {
				x = rx,
				y = ry - (arrowHeight / 2) + ((rh - textHeight) / 2), -- Vertically center
				w = rw,
				h = textHeight,
			},
		},
	}
end

function marks.add(element)
	insert(state.marks, { element = element })
end

function marks.isElementPartiallyVisible(element)
	local frame = element and not element:attributeValue("AXHidden") and element:attributeValue("AXFrame")
	if not frame or frame.w <= 0 or frame.h <= 0 then
		return false
	end

	local visibleArea = state.elements.visibleArea()
	local vx, vy, vw, vh = visibleArea.x, visibleArea.y, visibleArea.w, visibleArea.h
	local fx, fy, fw, fh = frame.x, frame.y, frame.w, frame.h

	return fx < vx + vw and fx + fw > vx and fy < vy + vh and fy + fh > vy
end

function marks.isElementActionable(element)
	if not element then
		return false
	end

	local role = element:attributeValue("AXRole")
	if not role then
		return false
	end

	local axJumpableRoles = config.axJumpableRoles

	if utils.isInBrowser() then
		-- remove "AXStaticText" if present
		axJumpableRoles = tblFilter(axJumpableRoles, function(r)
			return r ~= "AXStaticText"
		end)
	else
		-- ensure "AXStaticText" is included
		if not tblContains(axJumpableRoles, "AXStaticText") then
			table.insert(axJumpableRoles, "AXStaticText")
		end
	end

	return tblContains(axJumpableRoles, role)
end

function marks.isElementScrollable(element)
	if not element then
		return false
	end

	local role = element:attributeValue("AXRole")
	if not role then
		return false
	end

	local axScrollableRoles = config.axScrollableRoles

	return tblContains(axScrollableRoles, role)
end

function marks.isElementInput(element)
	if not element then
		return false
	end

	local role = element:attributeValue("AXRole")
	if not role then
		return false
	end

	local axEditableRoles = config.axEditableRoles

	return tblContains(axEditableRoles, role)
end

function marks.isElementImage(element)
	if not element then
		return false
	end

	local role = element:attributeValue("AXRole")
	local url = element:attributeValue("AXURL")

	if not role then
		return false
	end

	return role == "AXImage" and url ~= nil
end

function marks.getAllDescendants(element)
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

function marks.findClickableElements(element, withUrls, depth)
	if not element or (depth and depth > config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not marks.isElementPartiallyVisible(element) then
		return
	end

	if marks.isElementActionable(element) and (not withUrls or element:attributeValue("AXURL")) then
		marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				marks.findClickableElements(children[j], withUrls, (depth or 0) + 1)
			end
		end
	end
end

function marks.findScrollableElements(element, depth)
	if not element or (depth and depth > config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not marks.isElementPartiallyVisible(element) then
		return
	end

	if marks.isElementScrollable(element) then
		marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				marks.findScrollableElements(children[j], (depth or 0) + 1)
			end
		end
	end
end

function marks.findUrlElements(element, depth)
	if not element or (depth and depth > config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not marks.isElementPartiallyVisible(element) then
		return
	end

	if element:attributeValue("AXURL") then
		marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				marks.findUrlElements(children[j], (depth or 0) + 1)
			end
		end
	end
end

function marks.findInputElements(element, depth)
	if not element or (depth and depth > config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not marks.isElementPartiallyVisible(element) then
		return
	end

	if marks.isElementInput(element) then
		marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				marks.findInputElements(children[j], (depth or 0) + 1)
			end
		end
	end
end

function marks.findImageElements(element, depth)
	if not element or (depth and depth > config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not marks.isElementPartiallyVisible(element) then
		return
	end

	if marks.isElementImage(element) then
		log("found AXImage: " .. hs.inspect(element))
		marks.add(element)
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				marks.findImageElements(children[j], (depth or 0) + 1)
			end
		end
	end
end

--- @param withUrls boolean # If true, includes URLs when finding clickable elements.
--- @param type "link"|"scroll"|"url"|"input"|"image" # The type of elements to find ("link", "scroll", "url", "input").
function marks.show(withUrls, type)
	local startElement = state.elements.axWindow()
	if not startElement then
		return
	end

	log("startElement: " .. hs.inspect(startElement))

	marks.clear()

	if type == "link" then
		marks.findClickableElements(startElement, withUrls, 0)
	end

	if type == "scroll" then
		marks.findScrollableElements(startElement, 0)
	end

	if type == "url" then
		marks.findUrlElements(startElement, 0)
	end

	if type == "input" then
		marks.findInputElements(startElement, 0)
		if #state.marks == 1 then
			marks.onClickCallback(state.marks[1])
			utils.setMode(modes.NORMAL)
			return
		end
	end

	if type == "image" then
		marks.findImageElements(startElement, 0)
	end

	if #state.marks > 0 then
		marks.draw()
	else
		hs.alert.show("No elements found")
		utils.setMode(modes.NORMAL)
	end
end

--- @param combination string # The combination that matches the element to be clicked.
function marks.click(combination)
	log("M.marks.click")
	for i, c in ipairs(state.allCombinations) do
		if c == combination and state.marks[i] and marks.onClickCallback then
			local mark = state.marks[i]
			if mark then
				local success, err = pcall(marks.onClickCallback, mark)
				if not success then
					log("Error clicking element: " .. tostring(err))
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

function commands.cmdScrollLeft()
	actions.smoothScroll(config.scrollStep, 0, config.smoothScroll)
end

function commands.cmdScrollRight()
	actions.smoothScroll(-config.scrollStep, 0, config.smoothScroll)
end

function commands.cmdScrollUp()
	actions.smoothScroll(0, config.scrollStep, config.smoothScroll)
end

function commands.cmdScrollDown()
	actions.smoothScroll(0, -config.scrollStep, config.smoothScroll)
end

function commands.cmdScrollHalfPageDown()
	actions.smoothScroll(0, -config.scrollStepHalfPage, config.smoothScroll)
end

function commands.cmdScrollHalfPageUp()
	actions.smoothScroll(0, config.scrollStepHalfPage, config.smoothScroll)
end

function commands.cmdScrollToTop()
	actions.smoothScroll(0, -config.scrollStepFullPage, config.smoothScroll)
end

function commands.cmdScrollToBottom()
	actions.smoothScroll(0, config.scrollStepFullPage, config.smoothScroll)
end

function commands.cmdCopyPageUrlToClipboard()
	if utils.isInBrowser() then
		local element = state.elements.axWebArea()
		local url = element and element:attributeValue("AXURL")
		if url then
			actions.setClipboardContents(url.url)
		end
	else
		hs.alert.show("Copy page url is only available for browser")
	end
end

--- @param char string|nil # Optional character to display for the INSERT mode in the menu bar.
function commands.cmdInsertMode(char)
	utils.setMode(modes.INSERT, char)
end

function commands.cmdGotoLink(char)
	utils.setMode(modes.LINKS, char)
	marks.onClickCallback = function(mark)
		local element = mark.element
		if not element then
			log("Error: Invalid element")
			return
		end

		local actionsNames = element:actionNames()

		log("actions available: " .. hs.inspect(actionsNames))

		if tblContains(actionsNames, "AXPress") then
			mark.element:performAction("AXPress")
			log("Success AXPress")
		else
			-- Try different methods to get position
			local position, size = state.elements.getElementPositionAndSize(element)

			if position and size then
				local clickX = position.x + (size.w / 2)
				local clickY = position.y + (size.h / 2)
				local originalPosition = mouse.absolutePosition()

				local clickSuccess, clickErr = pcall(function()
					mouse.absolutePosition({ x = clickX, y = clickY })
					eventtap.leftClick({ x = clickX, y = clickY })
					actions.restoreMousePosition(originalPosition)
				end)

				if clickSuccess then
					return
				else
					log("Click failed: " .. tostring(clickErr))
				end
			end

			-- Fallback: Click using mark coordinates
			if mark.x and mark.y then
				local clickSuccess, clickErr = pcall(function()
					local originalPosition = mouse.absolutePosition()
					mouse.absolutePosition({ x = mark.x, y = mark.y })
					eventtap.leftClick({ x = mark.x, y = mark.y })
					actions.restoreMousePosition(originalPosition)
				end)

				if clickSuccess then
					return
				else
					log("Mark click failed: " .. tostring(clickErr))
				end
			end

			-- Final fallback: focus + return key
			log("Falling back to focus + return method")
			local focusSuccess, focusErr = pcall(function()
				element:setAttributeValue("AXFocused", true)
				timer.doAfter(0.1, function()
					eventtap.keyStroke({}, "return", 0)
				end)
			end)

			if not focusSuccess then
				log("Focus fallback failed: " .. tostring(focusErr))
			end
		end
	end
	timer.doAfter(0, function()
		marks.show(false, "link")
	end)
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
function commands.cmdRightClick(char)
	utils.setMode(modes.LINKS, char)

	marks.onClickCallback = function(mark)
		local element = mark.element
		if not element then
			log("Error: Invalid element")
			return
		end

		local actionsNames = element:actionNames()

		log(hs.inspect(actionsNames))

		if tblContains(actionsNames, "AXShowMenu") then
			mark.element:performAction("AXShowMenu")
			log("Success AXShowMenu")
		else
			local position, size = state.elements.getElementPositionAndSize(element)

			if position and size then
				local clickX = position.x + (size.w / 2)
				local clickY = position.y + (size.h / 2)
				local originalPosition = mouse.absolutePosition()

				local clickSuccess, clickErr = pcall(function()
					mouse.absolutePosition({ x = clickX, y = clickY })
					eventtap.rightClick({ x = clickX, y = clickY })
					actions.restoreMousePosition(originalPosition)
				end)

				if clickSuccess then
					return
				else
					log("Right-click failed: " .. tostring(clickErr))
				end
			end
		end
	end

	timer.doAfter(0, function()
		marks.show(false, "link")
	end)
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
function commands.cmdGotoLinkNewTab(char)
	if utils.isInBrowser() then
		utils.setMode(modes.LINKS, char)
		marks.onClickCallback = function(mark)
			local axURL = mark.element:attributeValue("AXURL")
			if axURL then
				actions.openUrlInNewTab(axURL.url)
			end
		end
		timer.doAfter(0, function()
			marks.show(true, "link")
		end)
	else
		hs.alert.show("Go to Link New Tab is only available for browser")
	end
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
function commands.cmdGotoInput(char)
	if utils.isInBrowser() then
		utils.setMode(modes.LINKS, char)
		marks.onClickCallback = function(mark)
			local element = mark.element
			if not element then
				log("Error: Invalid element")
				return
			end

			local actionsNames = element:actionNames()

			log("actions available: " .. hs.inspect(actionsNames))

			if tblContains(actionsNames, "AXPress") then
				mark.element:performAction("AXPress")
				log("Success AXPress")
			else
				-- Try different methods to get position
				local position, size = state.elements.getElementPositionAndSize(element)

				if position and size then
					local clickX = position.x + (size.w / 2)
					local clickY = position.y + (size.h / 2)
					local originalPosition = mouse.absolutePosition()

					local clickSuccess, clickErr = pcall(function()
						mouse.absolutePosition({ x = clickX, y = clickY })
						eventtap.leftClick({ x = clickX, y = clickY })
						actions.restoreMousePosition(originalPosition)
					end)

					if clickSuccess then
						return
					else
						log("Click failed: " .. tostring(clickErr))
					end
				end

				-- Fallback: Click using mark coordinates
				if mark.x and mark.y then
					local clickSuccess, clickErr = pcall(function()
						local originalPosition = mouse.absolutePosition()
						mouse.absolutePosition({ x = mark.x, y = mark.y })
						eventtap.leftClick({ x = mark.x, y = mark.y })
						actions.restoreMousePosition(originalPosition)
					end)

					if clickSuccess then
						return
					else
						log("Mark click failed: " .. tostring(clickErr))
					end
				end

				-- Final fallback: focus + return key
				log("Falling back to focus + return method")
				local focusSuccess, focusErr = pcall(function()
					element:setAttributeValue("AXFocused", true)
					timer.doAfter(0.1, function()
						eventtap.keyStroke({}, "return", 0)
					end)
				end)

				if not focusSuccess then
					log("Focus fallback failed: " .. tostring(focusErr))
				end
			end
		end
		timer.doAfter(0, function()
			marks.show(true, "input")
		end)
	else
		hs.alert.show("Go to input is only available for browser")
	end
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
function commands.cmdDownloadImage(char)
	if utils.isInBrowser() then
		utils.setMode(modes.LINKS, char)

		marks.onClickCallback = function(mark)
			local element = mark.element
			if not element then
				log("Error: Invalid element")
				return
			end

			-- Check if the element is an image
			if element:attributeValue("AXRole") == "AXImage" then
				local imageDescription = element:attributeValue("AXDescription") or "unknown"
				log("Image detected: " .. hs.inspect(imageDescription))

				-- Try downloading the image
				local downloadURLAttr = element:attributeValue("AXURL")

				if downloadURLAttr then
					log("AXURL attribute value: " .. hs.inspect(downloadURLAttr))
					local downloadUrl = downloadURLAttr.url
					log("Downloading image from URL: " .. downloadUrl)
					if downloadUrl:match("^data:image/") then
						log("Detected data:image URL, saving image directly.")

						-- Extract the Base64 encoded data from the URL
						local base64Data = downloadUrl:match("^data:image/[^;]+;base64,(.+)$")
						if base64Data then
							-- Decode the Base64 data
							local decodedData = hs.base64.decode(base64Data)

							-- Extract filename from image description or fallback
							local fileName = imageDescription:gsub("%W+", "_") .. ".jpg"
							local filePath = os.getenv("HOME") .. "/Downloads/" .. fileName
							log("Saving Base64 image to: " .. filePath)

							-- Write the decoded data to a file
							local file, err = io.open(filePath, "wb")
							if file then
								file:write(decodedData)
								file:close()
								log("Image saved successfully to: " .. filePath)
								hs.alert.show("Image downloaded successfully to: " .. filePath)
							else
								log("Failed to save image: " .. tostring(err))
							end
						else
							log("Error: Failed to extract Base64 data from URL.")
						end
					else
						hs.http.asyncGet(downloadUrl, nil, function(status, body, headers)
							if status == 200 then
								local contentType = headers["Content-Type"] or ""
								if contentType:match("^image/") then
									log("Valid image detected. Content-Type: " .. contentType)

									-- Extract filename from headers or URL
									local fileName = headers["Content-Disposition"]
											and headers["Content-Disposition"]:match('filename="?(.-)"?$')
										or downloadUrl:match("^.+/(.+)$")

									if not fileName or fileName == "" then
										fileName = "no-name.jpg" -- Default filename with extension
									elseif not fileName:match("^.+%.%w+$") then
										fileName = fileName .. ".jpg" -- Add default extension
									end

									local filePath = os.getenv("HOME") .. "/Downloads/" .. fileName
									log("Downloading image to: " .. filePath)

									-- Download the image
									hs.http.asyncGet(downloadUrl, nil, function(status2, body2)
										if status2 == 200 then
											local file, err = io.open(filePath, "wb")
											if file then
												file:write(body2)
												file:close()
												log("Image downloaded successfully to: " .. filePath)
												hs.alert.show("Image downloaded successfully to: " .. filePath)
											else
												log("Failed to save image: " .. tostring(err))
											end
										else
											log("Failed to download image. HTTP Status: " .. tostring(status2))
										end
									end)
								else
									log("Error: URL does not point to an image. Content-Type: " .. contentType)
								end
							else
								log("Failed to validate URL. HTTP Status: " .. tostring(status))
							end
						end)
						return
					end
				else
					log("Error: No download URL available for the image.")
				end
			end
		end

		timer.doAfter(0, function()
			marks.show(false, "image")
		end)
	else
		hs.alert.show("Download image is only available for browser")
	end
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
function commands.cmdMoveMouseToLink(char)
	utils.setMode(modes.LINKS, char)
	marks.onClickCallback = function(mark)
		local frame = mark.element:attributeValue("AXFrame")
		mouse.absolutePosition({ x = frame.x + frame.w / 2, y = frame.y + frame.h / 2 })
	end
	timer.doAfter(0, function()
		marks.show(true, "scroll")
	end)
end

function commands.cmdMoveMouseToCenter()
	mouse.absolutePosition({
		x = state.elements.visibleArea().x + state.elements.visibleArea().w / 2,
		y = state.elements.visibleArea().y + state.elements.visibleArea().h / 2,
	})
end

--- @param char string # Character to display for the LINKS mode in the menu bar.
function commands.cmdCopyLinkUrlToClipboard(char)
	if utils.isInBrowser() then
		utils.setMode(modes.LINKS, char)
		marks.onClickCallback = function(mark)
			local axURL = mark.element:attributeValue("AXURL")
			actions.setClipboardContents(axURL.url)
		end
		timer.doAfter(0, function()
			marks.show(true, "url")
		end)
	else
		hs.alert.show("Copy link url is only available for browser")
	end
end

--------------------------------------------------------------------------------
--- Event Handling and Input Processing
--------------------------------------------------------------------------------

--- @param char string # The character input that triggers specific actions or commands.
--- @param modifiers table # Table of modifiers. Only supports ctrl for now
local function vimLoop(char, modifiers)
	log("vimLoop " .. char .. ", modifiers " .. hs.inspect(modifiers))

	if state.elements.mode == modes.LINKS then
		state.linkCapture = state.linkCapture .. char:lower()
		if #state.linkCapture == 2 then
			marks.click(state.linkCapture)
			utils.setMode(modes.NORMAL)
		end
		return
	end

	local keyCombo = ""
	if modifiers and modifiers.ctrl then
		keyCombo = "C-"
	end
	keyCombo = keyCombo .. char

	if state.elements.mode == modes.MULTI then
		keyCombo = state.elements.multi .. keyCombo
	end
	local foundMapping = config.mapping[keyCombo]

	if foundMapping then
		utils.setMode(modes.NORMAL)

		if type(foundMapping) == "string" then
			commands[foundMapping](keyCombo)
		elseif type(foundMapping) == "table" then
			eventtap.keyStroke(foundMapping[1], foundMapping[2], 0)
		else
			log("Unknown mapping for " .. keyCombo .. " " .. hs.inspect(foundMapping))
		end
	elseif state.mappingPrefixes[keyCombo] then
		utils.setMode(modes.MULTI, keyCombo)
	else
		log("Unknown char " .. keyCombo)
	end
end

local function eventHandler(event)
	cached = setmetatable({}, { __mode = "k" })

	if utils.isExcludedApp() then
		return false
	end

	local flags = event:getFlags()
	local keyCode = event:getKeyCode()
	local modifiers = { ctrl = flags.ctrl }

	for key, modifier in pairs(flags) do
		if modifier and key ~= "shift" and key ~= "ctrl" then
			return false
		end
	end

	if utils.isSpotlightActive() then
		return false
	end

	if keyCode == hs.keycodes.map["escape"] then
		local delaySinceLastEscape = (timer.absoluteTime() - state.lastEscape) / 1e9 -- nanoseconds in seconds
		state.lastEscape = timer.absoluteTime()

		if utils.isInBrowser() and delaySinceLastEscape < config.doublePressDelay then
			utils.setMode(modes.NORMAL)
			actions.forceUnfocus()
			return true
		end

		if state.elements.mode ~= modes.NORMAL then
			utils.setMode(modes.NORMAL)
			return true
		end

		return false
	end

	if state.elements.mode == modes.INSERT or state.elements.isEditableControlInFocus() then
		return false
	end

	local char = hs.keycodes.map[keyCode]

	log("char: " .. char)

	if flags.shift then
		char = event:getCharacters()
	end

	if not char:match("[%a%d%[%]%$]") or #char ~= 1 then
		return false
	end

	if modifiers and modifiers.ctrl then
		local filteredMappings = {}

		for key, _ in pairs(config.mapping) do
			if key:sub(1, 2) == "C-" then
				table.insert(filteredMappings, key:sub(3))
			end
		end

		if tblContains(filteredMappings, char) == false then
			return false
		end
	end

	timer.doAfter(0, function()
		vimLoop(char, modifiers)
	end)
	return true
end

local function onWindowFocused()
	log("onWindowFocused")
	if not state.eventLoop then
		state.eventLoop = eventtap.new({ hs.eventtap.event.types.keyDown }, eventHandler):start()
	end
	if not utils.isExcludedApp() then
		utils.setMode(modes.NORMAL)
	else
		utils.setMode(modes.DISABLED)
	end
end

local function onWindowUnfocused()
	log("onWindowUnfocused")
	if state.eventLoop then
		state.eventLoop:stop()
		state.eventLoop = nil
	end
	utils.setMode(modes.DISABLED)
end

--------------------------------------------------------------------------------
-- Module Initialization and Cleanup
--------------------------------------------------------------------------------

local M = {}

function M:start()
	state.windowFilter = hs.window.filter.new()
	state.windowFilter:subscribe(hs.window.filter.windowFocused, onWindowFocused)
	state.windowFilter:subscribe(hs.window.filter.windowUnfocused, onWindowUnfocused)
	menuBar.new()
	utils.fetchMappingPrefixes()
	utils.generateCombinations()
end

function M:stop()
	if state.windowFilter then
		state.windowFilter:unsubscribe(onWindowFocused)
		state.windowFilter:unsubscribe(onWindowUnfocused)
		state.windowFilter = nil
	end
	menuBar.delete()
end

return M
