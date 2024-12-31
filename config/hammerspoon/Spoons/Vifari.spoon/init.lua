local floor = math.floor
local insert = table.insert
local format = string.format
local sub = string.sub
local pcall = pcall
local timer = hs.timer
local mouse = hs.mouse
local eventtap = hs.eventtap

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
obj.modifiedBy = "Kyle Wong <wongyeowkin@gmail.com>"

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
	-- ["gg"] = { "cmd", "up" },
	-- ["G"] = { "cmd", "down" },
	["gg"] = "cmdScrollToBottom",
	["G"] = "cmdScrollToTop",
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
	["gi"] = "cmdGotoInput",
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
	scrollStepFullPage = 100000, -- make it a super big number and not worry
	smoothScroll = true,
	smoothScrollFrameRate = 120,
	depth = 20, -- depth for traversing children when creating marks
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
		"AXStaticText",
		"AXToolbar",
		"AXToolbarButton",
		"AXTabGroup",
		"AXTab",
		"AXSlider",
		"AXIncrementor",
		"AXDecrementor",
		"AXDisclosureTriangle",
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
	axInputRoles = {
		"AXTextField",
		"AXTextArea",
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
-- helpers
--------------------------------------------------------------------------------

local cached = setmetatable({}, { __mode = "k" })
local current = {}
local marks = { data = {} }
local menuBar = {}
local commands = {}
local windowFilter
local eventLoop
local modes = { DISABLED = 1, NORMAL = 2, INSERT = 3, MULTI = 4, LINKS = 5 }
local linkCapture
local lastEscape = timer.absoluteTime()
local mappingPrefixes
local allCombinations

local function logWithTimestamp(message)
	if not config.showLogs then
		return
	end

	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local ms = floor(timer.absoluteTime() / 1e6) % 1000
	hs.printf("[%s.%03d] %s", timestamp, ms, message)
end

local function tblContains(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

local function filter(tbl, predicate)
	local result = {}
	for _, v in ipairs(tbl) do
		if predicate(v) then
			table.insert(result, v)
		end
	end
	return result
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

function current.axWebArea()
	cached.axWebArea = cached.axWebArea or findAXRole(current.axScrollArea(), "AXWebArea")
	return cached.axWebArea
end

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

	logWithTimestamp("visibleArea: " .. hs.inspect(cached.visibleArea))

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

local function generateCombinations()
	local chars = "abcdefghijklmnopqrstuvwxyz"
	allCombinations = {}
	for i = 1, #chars do
		for j = 1, #chars do
			insert(allCombinations, chars:sub(i, i) .. chars:sub(j, j))
		end
	end
end

local function smoothScroll(x, y, smooth)
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

	if browserScripts[currentApp] then
		script = format(browserScripts[currentApp], url)
	else
		-- Fallback to Safari if not a known browser
		script = format(browserScripts["Safari"], url)
	end

	hs.osascript.applescript(script)
end

local function setClipboardContents(contents)
	if contents and hs.pasteboard.setContents(contents) then
		hs.alert.show("Copied to clipboard: " .. contents, nil, nil, 4)
	else
		hs.alert.show("Failed to copy to clipboard", nil, nil, 4)
	end
end

local function getFocusedElement(element, depth)
	if not element or (depth and depth > config.depth) then
		return
	end

	local elementFrame = element:attributeValue("AXFrame")
	if not elementFrame or not marks.isElementPartiallyVisible(element) then
		return
	end

	if element:attributeValue("AXFocused") then
		logWithTimestamp("Focused element found: " .. hs.inspect(element))
		element:setAttributeValue("AXFocused", false)
		logWithTimestamp("Focused element unfocused.")
	end

	local children = element:attributeValue("AXChildren")
	if children then
		local chunk_size = 10
		for i = 1, #children, chunk_size do
			local end_idx = math.min(i + chunk_size - 1, #children)
			for j = i, end_idx do
				getFocusedElement(children[j], (depth or 0) + 1)
			end
		end
	end
end

local function forceUnfocus()
	logWithTimestamp("forced unfocus on escape")

	local startElement = current.axWindow()
	if not startElement then
		return
	end

	getFocusedElement(startElement, 0)
	hs.alert.show("Force unfocused!")
end

local function getElementPositionAndSize(element)
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

local function restoreMousePosition(originalPosition)
	timer.doAfter(0.05, function()
		mouse.absolutePosition(originalPosition)
	end)
end

local function isInBrowser()
	local currentAppName = current.app():name()

	return tblContains(config.browsers, currentAppName)
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
		timer.doAfter(0, marks.clear)
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

function marks.draw()
	if not marks.canvas then
		marks.canvas = hs.canvas.new(current.visibleArea())
	end

	local elementsToDraw = {}
	for i, _ in ipairs(marks.data) do
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

function marks.prepareElementForDrawing(markIndex)
	local mark = marks.data[markIndex]
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
	local visibleArea = current.visibleArea()

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
		},
	}
end

function marks.add(element)
	insert(marks.data, { element = element })
end

function marks.isElementPartiallyVisible(element)
	local frame = element and not element:attributeValue("AXHidden") and element:attributeValue("AXFrame")
	if not frame or frame.w <= 0 or frame.h <= 0 then
		return false
	end

	local visibleArea = current.visibleArea()
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

	if isInBrowser() then
		-- remove "AXStaticText" if present
		axJumpableRoles = filter(axJumpableRoles, function(r)
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

	local axInputRoles = config.axInputRoles

	return tblContains(axInputRoles, role)
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

---@param withUrls boolean
---@param type? string
function marks.show(withUrls, type)
	local startElement = current.axWindow()
	if not startElement then
		return
	end

	logWithTimestamp("startElement: " .. hs.inspect(startElement))

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
		if #marks.data == 1 then
			marks.onClickCallback(marks.data[1])
			return
		end
	end

	if #marks.data > 0 then
		marks.draw()
	else
		hs.alert.show("No elements found")
	end
end

function marks.click(combination)
	logWithTimestamp("marks.click")
	for i, c in ipairs(allCombinations) do
		if c == combination and marks.data[i] and marks.onClickCallback then
			local mark = marks.data[i]
			if mark then
				local success, err = pcall(marks.onClickCallback, mark)
				if not success then
					logWithTimestamp("Error clicking element: " .. tostring(err))
				end
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
	smoothScroll(0, -config.scrollStepHalfPage, config.smoothScroll)
end

function commands.cmdScrollHalfPageUp()
	smoothScroll(0, config.scrollStepHalfPage, config.smoothScroll)
end

function commands.cmdScrollToTop()
	smoothScroll(0, -config.scrollStepFullPage, config.smoothScroll)
end

function commands.cmdScrollToBottom()
	smoothScroll(0, config.scrollStepFullPage, config.smoothScroll)
end

function commands.cmdCopyPageUrlToClipboard()
	if isInBrowser() then
		local element = current.axWebArea()
		local url = element and element:attributeValue("AXURL")
		if url then
			setClipboardContents(url.url)
		end
	else
		hs.alert.show("Copy page url is only available for browser")
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

		local actions = element:actionNames()

		logWithTimestamp("actions available: " .. hs.inspect(actions))

		if tblContains(actions, "AXPress") then
			mark.element:performAction("AXPress")
			logWithTimestamp("Success AXPress")
		else
			-- Try different methods to get position
			local position, size = getElementPositionAndSize(element)

			if position and size then
				local clickX = position.x + (size.w / 2)
				local clickY = position.y + (size.h / 2)
				local originalPosition = mouse.absolutePosition()

				local clickSuccess, clickErr = pcall(function()
					mouse.absolutePosition({ x = clickX, y = clickY })
					eventtap.leftClick({ x = clickX, y = clickY })
					restoreMousePosition(originalPosition)
				end)

				if clickSuccess then
					return
				else
					logWithTimestamp("Click failed: " .. tostring(clickErr))
				end
			end

			-- Fallback: Click using mark coordinates
			if mark.x and mark.y then
				local clickSuccess, clickErr = pcall(function()
					local originalPosition = mouse.absolutePosition()
					mouse.absolutePosition({ x = mark.x, y = mark.y })
					eventtap.leftClick({ x = mark.x, y = mark.y })
					restoreMousePosition(originalPosition)
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
				timer.doAfter(0.1, function()
					eventtap.keyStroke({}, "return", 0)
				end)
			end)

			if not focusSuccess then
				logWithTimestamp("Focus fallback failed: " .. tostring(focusErr))
			end
		end
	end
	timer.doAfter(0, function()
		marks.show(false, "link")
	end)
end

function commands.cmdRightClick(char)
	setMode(modes.LINKS, char)

	marks.onClickCallback = function(mark)
		local element = mark.element
		if not element then
			logWithTimestamp("Error: Invalid element")
			return
		end

		local actions = element:actionNames()

		logWithTimestamp(hs.inspect(actions))

		if tblContains(actions, "AXShowMenu") then
			mark.element:performAction("AXShowMenu")
			logWithTimestamp("Success AXShowMenu")
		else
			local position, size = getElementPositionAndSize(element)

			if position and size then
				local clickX = position.x + (size.w / 2)
				local clickY = position.y + (size.h / 2)
				local originalPosition = mouse.absolutePosition()

				local clickSuccess, clickErr = pcall(function()
					mouse.absolutePosition({ x = clickX, y = clickY })
					eventtap.rightClick({ x = clickX, y = clickY })
					restoreMousePosition(originalPosition)
				end)

				if clickSuccess then
					return
				else
					logWithTimestamp("Right-click failed: " .. tostring(clickErr))
				end
			end
		end
	end

	timer.doAfter(0, function()
		marks.show(false, "link")
	end)
end

function commands.cmdGotoLinkNewTab(char)
	if isInBrowser() then
		setMode(modes.LINKS, char)
		marks.onClickCallback = function(mark)
			local axURL = mark.element:attributeValue("AXURL")
			if axURL then
				openUrlInNewTab(axURL.url)
			end
		end
		timer.doAfter(0, function()
			marks.show(true, "link")
		end)
	else
		hs.alert.show("Go to Link New Tab is only available for browser")
	end
end

function commands.cmdGotoInput(char)
	if isInBrowser() then
		setMode(modes.LINKS, char)
		marks.onClickCallback = function(mark)
			local element = mark.element
			if not element then
				logWithTimestamp("Error: Invalid element")
				return
			end

			local actions = element:actionNames()

			logWithTimestamp("actions available: " .. hs.inspect(actions))

			if tblContains(actions, "AXPress") then
				mark.element:performAction("AXPress")
				logWithTimestamp("Success AXPress")
			else
				-- Try different methods to get position
				local position, size = getElementPositionAndSize(element)

				if position and size then
					local clickX = position.x + (size.w / 2)
					local clickY = position.y + (size.h / 2)
					local originalPosition = mouse.absolutePosition()

					local clickSuccess, clickErr = pcall(function()
						mouse.absolutePosition({ x = clickX, y = clickY })
						eventtap.leftClick({ x = clickX, y = clickY })
						restoreMousePosition(originalPosition)
					end)

					if clickSuccess then
						return
					else
						logWithTimestamp("Click failed: " .. tostring(clickErr))
					end
				end

				-- Fallback: Click using mark coordinates
				if mark.x and mark.y then
					local clickSuccess, clickErr = pcall(function()
						local originalPosition = mouse.absolutePosition()
						mouse.absolutePosition({ x = mark.x, y = mark.y })
						eventtap.leftClick({ x = mark.x, y = mark.y })
						restoreMousePosition(originalPosition)
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
					timer.doAfter(0.1, function()
						eventtap.keyStroke({}, "return", 0)
					end)
				end)

				if not focusSuccess then
					logWithTimestamp("Focus fallback failed: " .. tostring(focusErr))
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

function commands.cmdMoveMouseToLink(char)
	setMode(modes.LINKS, char)
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
		x = current.visibleArea().x + current.visibleArea().w / 2,
		y = current.visibleArea().y + current.visibleArea().h / 2,
	})
end

function commands.cmdCopyLinkUrlToClipboard(char)
	if isInBrowser() then
		setMode(modes.LINKS, char)
		marks.onClickCallback = function(mark)
			local axURL = mark.element:attributeValue("AXURL")
			setClipboardContents(axURL.url)
		end
		timer.doAfter(0, function()
			marks.show(true, "url")
		end)
	else
		hs.alert.show("Copy link url is only available for browser")
	end
end

--------------------------------------------------------------------------------
--- vifari
--------------------------------------------------------------------------------

local function fetchMappingPrefixes()
	mappingPrefixes = {}
	for k, _ in pairs(config.mapping) do
		if #k == 2 then
			mappingPrefixes[sub(k, 1, 1)] = true
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
			eventtap.keyStroke(foundMapping[1], foundMapping[2], 0)
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
	cached = setmetatable({}, { __mode = "k" })

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
		local delaySinceLastEscape = (timer.absoluteTime() - lastEscape) / 1e9 -- nanoseconds in seconds
		lastEscape = timer.absoluteTime()

		if isInBrowser() and delaySinceLastEscape < config.doublePressDelay then
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

	timer.doAfter(0, function()
		vimLoop(char)
	end)
	return true
end

local function onWindowFocused()
	logWithTimestamp("onWindowFocused")
	if not eventLoop then
		eventLoop = eventtap.new({ hs.eventtap.event.types.keyDown }, eventHandler):start()
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
