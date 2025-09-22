---@diagnostic disable: undefined-global

local _utils = require("utils")

local M = {}

M.__index = M

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
  ["G"] = "cmdScrollToBottom",
  ["gg"] = "cmdScrollToTop",
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
  ["]]"] = "cmdNextPage",
  ["[["] = "cmdPrevPage",
}

local default_config = {
  doublePressDelay = 0.3, -- seconds
  showLogs = false,
  mapping = mapping,
  scrollStep = 50,
  scrollStepHalfPage = 500,
  smoothScroll = true,
  smoothScrollFrameRate = 120,
  depth = 100, -- depth for traversing children when creating marks
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
    "AXMenuButton",
    "AXMenuBarItem", -- To support top menu bar
    "AXMenuItem",
    "AXRow", -- To support Mail.app without using "AXStaticText"
    -- "AXColorWell", -- Macos Color Picker
    -- "AXCell", -- This can help with showing marks on Calendar.app
    -- "AXGroup", -- This can help with lots of MacOS apps, but creates lot of noise!
    -- "AXStaticText",
    -- "AXMenu",
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
  },
  -- Browser names to be considered
  browsers = {
    "Safari",
    "Google Chrome",
    "Firefox",
    "Microsoft Edge",
    "Brave Browser",
  },
  launchers = {
    "Spotlight",
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

function state.elements.axMenuBar()
  cached.axMenuBar = cached.axMenuBar or utils.getAttribute(state.elements.axApp(), "AXMenuBar")
  return cached.axMenuBar
end

function state.elements.axFocusedElement()
  cached.axFocusedElement = cached.axFocusedElement or utils.getAttribute(state.elements.axApp(), "AXFocusedUIElement")
  return cached.axFocusedElement
end

function state.elements.axWebArea()
  cached.axWebArea = cached.axWebArea or utils.findAXRole(state.elements.axWindow(), "AXWebArea")
  return cached.axWebArea
end

function state.elements.fullArea()
  if cached.fullArea then
    return cached.fullArea
  end

  local winFrame = utils.getAttribute(state.elements.axWindow(), "AXFrame") or {}
  local menuBarFrame = utils.getAttribute(state.elements.axMenuBar(), "AXFrame") or {}

  cached.fullArea = {
    x = 0,
    y = 0,
    w = menuBarFrame.w,
    h = winFrame.h + winFrame.y + menuBarFrame.h,
  }

  log("fullArea: " .. hs.inspect(cached.fullArea))

  return cached.fullArea
end

function state.elements.visibleArea()
  if cached.visibleArea then
    return cached.visibleArea
  end

  local winFrame = utils.getAttribute(state.elements.axWindow(), "AXFrame") or {}

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

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

function utils.fetchMappingPrefixes()
  for k, _ in pairs(M.config.mapping) do
    if #k == 2 then
      state.mappingPrefixes[sub(k, 1, 1)] = true
    end
  end
  log("mappingPrefixes: " .. hs.inspect(state.mappingPrefixes))
end

function utils.isExcludedApp()
  local appName = state.elements.app():name()
  return tblContains(M.config.excludedApps, appName)
end

function utils.isLauncherActive()
  for _, launcher in ipairs(M.config.launchers) do
    local app = hs.application.get(launcher)
    if app then
      local appElement = hs.axuielement.applicationElement(app)
      if appElement then
        local windows = utils.getAttribute(appElement, "AXWindows") or {}
        if #windows > 0 then
          return true, launcher
        end
      end
    end
  end
  return false
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

  return tblContains(M.config.browsers, currentAppName)
end

--- @param mode integer # The mode to set. Expected values are in `M.modes`.
--- @param char string|nil # An optional character representing the mode in the menu bar.
function utils.setMode(mode, char)
  local defaultModeChars = {
    [modes.DISABLED] = "X",
    [modes.INSERT] = "I",
    [modes.LINKS] = "L",
    [modes.MULTI] = "M",
    [modes.NORMAL] = "N",
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

function utils.isElementPartiallyVisible(element)
  local axHidden = utils.getAttribute(element, "AXHidden")
  local axFrame = utils.getAttribute(element, "AXFrame")

  local frame = element and not axHidden and axFrame

  if not frame or frame.w <= 0 or frame.h <= 0 then
    return false
  end

  local fullArea = state.elements.fullArea()
  local vx, vy, vw, vh = fullArea.x, fullArea.y, fullArea.w, fullArea.h
  local fx, fy, fw, fh = frame.x, frame.y, frame.w, frame.h

  return fx < vx + vw and fx + fw > vx and fy < vy + vh and fy + fh > vy
end

function utils.getFocusedElement(element, depth)
  if not element or (depth and depth > M.config.depth) then
    return
  end

  local elementApp = utils.getAttribute(element, "AXRole")
  local elementFrame = utils.getAttribute(element, "AXFrame")

  if elementApp ~= "AXApplication" then
    if not elementFrame or not utils.isElementPartiallyVisible(element) then
      return
    end

    local axFocused = utils.getAttribute(element, "AXFocused")

    if axFocused then
      log("Focused element found: " .. hs.inspect(element))
      element:setAttributeValue("AXFocused", false)
      log("Focused element unfocused.")
    end
  end

  utils.getChildrens(element, function(_element)
    utils.getFocusedElement(_element, (depth or 0) + 1)
  end)
end

--- @return boolean, boolean # found status, completed status
function utils.getNextPrevElement(element, depth, direction)
  if not element or (depth and depth > M.config.depth) then
    return false, true
  end

  local elementApp = utils.getAttribute(element, "AXRole")
  local elementFrame = utils.getAttribute(element, "AXFrame")

  if elementApp ~= "AXApplication" then
    if not elementFrame or not utils.isElementPartiallyVisible(element) then
      return false, true
    end

    local role = utils.getAttribute(element, "AXRole")
    local title = utils.getAttribute(element, "AXTitle")

    if role == "AXLink" or role == "AXButton" or role == "AXMenuItem" then
      if title and title:lower():find(direction) then
        element:performAction("AXPress")
        return true, true
      end
    end
  end

  local children = utils.getAttribute(element, "AXChildren")
  if children then
    local chunk_size = 10
    for i = 1, #children, chunk_size do
      local end_idx = math.min(i + chunk_size - 1, #children)
      for j = i, end_idx do
        local found = utils.getNextPrevElement(children[j], (depth or 0) + 1, direction)
        if found then
          return true, true -- Element found in children, traversal complete
        end
      end
    end
  end

  return false, true -- No element found, but traversal completed for this branch
end

function utils.getElementPositionAndSize(element)
  local frame = utils.getAttribute(element, "AXFrame")
  if frame then
    return { x = frame.x, y = frame.y }, { w = frame.w, h = frame.h }
  end

  local successPos, position = pcall(function()
    return utils.getAttribute(element, "AXPosition")
  end)
  local successSize, size = pcall(function()
    return utils.getAttribute(element, "AXSize")
  end)

  if successPos and successSize and position and size then
    return position, size
  end

  return nil, nil
end

function utils.findAXRole(rootElement, role)
  local axRole = utils.getAttribute(rootElement, "AXRole")

  if axRole == role then
    return rootElement
  end

  local axChildren = utils.getAttribute(rootElement, "AXChildren") or {}

  for _, child in ipairs(axChildren) do
    local result = utils.findAXRole(child, role)
    if result then
      return result
    end
  end
end

function utils.isEditableControlInFocus()
  if state.elements.axFocusedElement() then
    return tblContains(M.config.axEditableRoles, utils.getAttribute(state.elements.axFocusedElement(), "AXRole"))
  else
    return false
  end
end

function utils.getAttribute(element, attributeName)
  if not element then
    return nil
  end
  return element:attributeValue(attributeName)
end

function utils.getDescendants(elements, cb)
  local chunk_size = 10
  for i = 1, #elements, chunk_size do
    local end_idx = math.min(i + chunk_size - 1, #elements)
    for j = i, end_idx do
      cb(elements[j])
    end
  end
end

function utils.isElementActionable(element)
  if not element then
    return false
  end

  local role = utils.getAttribute(element, "AXRole")
  if not role then
    return false
  end

  local axJumpableRoles = M.config.axJumpableRoles

  return tblContains(axJumpableRoles, role)
end

function utils.isElementScrollable(element)
  if not element then
    return false
  end

  local role = utils.getAttribute(element, "AXRole")
  if not role then
    return false
  end

  local axScrollableRoles = M.config.axScrollableRoles

  return tblContains(axScrollableRoles, role)
end

function utils.isElementInput(element)
  if not element then
    return false
  end

  local role = utils.getAttribute(element, "AXRole")
  if not role then
    return false
  end

  local axEditableRoles = M.config.axEditableRoles

  return tblContains(axEditableRoles, role)
end

function utils.isElementImage(element)
  if not element then
    return false
  end

  local role = utils.getAttribute(element, "AXRole")
  local url = utils.getAttribute(element, "AXURL")

  if not role then
    return false
  end

  return role == "AXImage" and url ~= nil
end

function utils.getChildrens(mainElement, cb)
  local role = utils.getAttribute(mainElement, "AXRole")
  local main = utils.getAttribute(mainElement, "AXMain")

  if role == "AXWindow" and main == false then
    return
  end

  local sourceTypes = {
    "AXVisibleRows",
    "AXVisibleChildren",
    "AXChildrenInNavigationOrder",
    "AXChildren",
  }

  for _, sourceType in ipairs(sourceTypes) do
    local elements = utils.getAttribute(mainElement, sourceType)
    if elements and #elements > 0 then
      utils.getDescendants(elements, cb)
      return
    end
  end
end

function utils.findClickableElements(element, withUrls, depth, cb)
  if not element or (depth and depth > M.config.depth) then
    return
  end

  local elementApp = utils.getAttribute(element, "AXRole")
  local elementFrame = utils.getAttribute(element, "AXFrame")

  if elementApp ~= "AXApplication" then
    if not elementFrame or not utils.isElementPartiallyVisible(element) then
      return
    end

    local elementUrl = utils.getAttribute(element, "AXURL")

    if utils.isElementActionable(element) and (not withUrls or elementUrl) then
      cb(element)
    end
  end

  utils.getChildrens(element, function(_element)
    utils.findClickableElements(_element, withUrls, (depth or 0) + 1, function(_element2)
      cb(_element2)
    end)
  end)
end

function utils.findScrollableElements(element, depth, cb)
  if not element or (depth and depth > M.config.depth) then
    return
  end

  local elementApp = utils.getAttribute(element, "AXRole")
  local elementFrame = utils.getAttribute(element, "AXFrame")

  if elementApp ~= "AXApplication" then
    if not elementFrame or not utils.isElementPartiallyVisible(element) then
      return
    end

    if utils.isElementScrollable(element) then
      cb(element)
    end
  end

  utils.getChildrens(element, function(_element)
    utils.findScrollableElements(_element, (depth or 0) + 1, function(_element2)
      cb(_element2)
    end)
  end)
end

function utils.findUrlElements(element, depth, cb)
  if not element or (depth and depth > M.config.depth) then
    return
  end

  local elementApp = utils.getAttribute(element, "AXRole")
  local elementFrame = utils.getAttribute(element, "AXFrame")

  if elementApp ~= "AXApplication" then
    if not elementFrame or not utils.isElementPartiallyVisible(element) then
      return
    end

    local elementUrl = utils.getAttribute(element, "AXURL")

    if elementUrl then
      cb(element)
    end
  end

  utils.getChildrens(element, function(_element)
    utils.findUrlElements(_element, (depth or 0) + 1, function(_element2)
      cb(_element2)
    end)
  end)
end

function utils.findInputElements(element, depth, cb)
  if not element or (depth and depth > M.config.depth) then
    return
  end

  local elementApp = utils.getAttribute(element, "AXRole")
  local elementFrame = utils.getAttribute(element, "AXFrame")

  if elementApp ~= "AXApplication" then
    if not elementFrame or not utils.isElementPartiallyVisible(element) then
      return
    end
    if utils.isElementInput(element) then
      cb(element)
    end
  end

  utils.getChildrens(element, function(_element)
    utils.findInputElements(_element, (depth or 0) + 1, function(_element2)
      cb(_element2)
    end)
  end)
end

function utils.findImageElements(element, depth, cb)
  if not element or (depth and depth > M.config.depth) then
    return
  end

  local elementApp = utils.getAttribute(element, "AXRole")
  local elementFrame = utils.getAttribute(element, "AXFrame")

  if elementApp ~= "AXApplication" then
    if not elementFrame or not utils.isElementPartiallyVisible(element) then
      return
    end
    if utils.isElementImage(element) then
      log("found AXImage: " .. hs.inspect(element))
      cb(element)
    end
  end

  utils.getChildrens(element, function(_element)
    utils.findImageElements(_element, (depth or 0) + 1, function(_element2)
      cb(_element2)
    end)
  end)
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

  utils.getFocusedElement(startElement, 0)

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
    marks.canvas = hs.canvas.new(state.elements.fullArea())
  end

  local elementsToDraw = {}
  for i, _ in ipairs(state.marks) do
    local markText = string.upper(state.allCombinations[i])

    if #state.linkCapture == 0 or markText:sub(1, #state.linkCapture) == state.linkCapture then
      local element = marks.prepareElementForDrawing(i)
      if element then
        table.move(element, 1, #element, #elementsToDraw + 1, elementsToDraw)
      end
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

  local position, size = utils.getElementPositionAndSize(mark.element)
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

  local rx = bgRect.x
  local ry = bgRect.y
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

--- @param withUrls boolean # If true, includes URLs when finding clickable elements.
--- @param type "link"|"scroll"|"url"|"input"|"image" # The type of elements to find ("link", "scroll", "url", "input").
function marks.show(withUrls, type)
  local startElement = state.elements.axApp()
  if not startElement then
    return
  end

  log("startElement: " .. hs.inspect(startElement))

  marks.clear()

  if type == "link" then
    utils.findClickableElements(startElement, withUrls, 0, function(element)
      marks.add(element)
    end)
  end

  if type == "scroll" then
    utils.findScrollableElements(startElement, 0, function(element)
      marks.add(element)
    end)
  end

  if type == "url" then
    utils.findUrlElements(startElement, 0, function(element)
      marks.add(element)
    end)
  end

  if type == "input" then
    utils.findInputElements(startElement, 0, function(element)
      marks.add(element)
    end)

    if #state.marks == 1 then
      marks.onClickCallback(state.marks[1])
      utils.setMode(modes.NORMAL)
      return
    end
  end

  if type == "image" then
    utils.findImageElements(startElement, 0, function(element)
      marks.add(element)
    end)
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
  actions.smoothScroll(M.config.scrollStep, 0, M.config.smoothScroll)
end

function commands.cmdScrollRight()
  actions.smoothScroll(-M.config.scrollStep, 0, M.config.smoothScroll)
end

function commands.cmdScrollUp()
  actions.smoothScroll(0, M.config.scrollStep, M.config.smoothScroll)
end

function commands.cmdScrollDown()
  actions.smoothScroll(0, -M.config.scrollStep, M.config.smoothScroll)
end

function commands.cmdScrollHalfPageDown()
  actions.smoothScroll(0, -M.config.scrollStepHalfPage, M.config.smoothScroll)
end

function commands.cmdScrollHalfPageUp()
  actions.smoothScroll(0, M.config.scrollStepHalfPage, M.config.smoothScroll)
end

function commands.cmdScrollToTop()
  eventtap.keyStroke({ "command" }, "up", 0)
end

function commands.cmdScrollToBottom()
  eventtap.keyStroke({ "command" }, "down", 0)
end

function commands.cmdCopyPageUrlToClipboard()
  if utils.isInBrowser() then
    local element = state.elements.axWebArea()
    local url = element and utils.getAttribute(element, "AXURL")
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
      local position, size = utils.getElementPositionAndSize(element)

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
      local position, size = utils.getElementPositionAndSize(element)

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
      local axURL = utils.getAttribute(mark.element, "AXURL")
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
      local position, size = utils.getElementPositionAndSize(element)

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
      if utils.getAttribute(element, "AXRole") == "AXImage" then
        local imageDescription = utils.getAttribute(element, "AXDescription") or "unknown"
        log("Image detected: " .. hs.inspect(imageDescription))

        -- Try downloading the image
        local downloadURLAttr = utils.getAttribute(element, "AXURL")

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
    local frame = utils.getAttribute(mark.element, "AXFrame") or {}
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
      local axURL = utils.getAttribute(mark.element, "AXURL") or {}
      actions.setClipboardContents(axURL.url)
    end
    timer.doAfter(0, function()
      marks.show(true, "url")
    end)
  else
    hs.alert.show("Copy link url is only available for browser")
  end
end

function commands.cmdNextPage()
  if utils.isInBrowser() then
    local navigateAction = function()
      local startElement = state.elements.axWindow()
      if not startElement then
        return
      end

      local success, status = utils.getNextPrevElement(startElement, 0, "next")

      if not success and status then
        hs.alert.show("No Next button found")
      end
    end

    -- Perform the navigation
    timer.doAfter(0, navigateAction)
  else
    hs.alert.show("Next Page is only available for browser")
  end
end

function commands.cmdPrevPage()
  if utils.isInBrowser() then
    local navigateAction = function()
      local startElement = state.elements.axWindow()
      if not startElement then
        return
      end

      local success, status = utils.getNextPrevElement(startElement, 0, "prev")

      if not success and status then
        hs.alert.show("No Previous button found")
      end
    end

    -- Perform the navigation
    timer.doAfter(0, navigateAction)
  else
    hs.alert.show("Prev Page is only available for browser")
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
    if char == "backspace" then
      -- Remove the last character from the filter
      if #state.linkCapture > 0 then
        state.linkCapture = state.linkCapture:sub(1, -2)
        marks.draw()
      end
      return
    end

    state.linkCapture = state.linkCapture .. char:upper()
    marks.draw()

    local matchFound = false
    for i, _ in ipairs(state.marks) do
      local markText = string.upper(state.allCombinations[i])
      if markText == state.linkCapture then
        marks.click(markText:lower())
        utils.setMode(modes.NORMAL)
        matchFound = true
        break
      end
    end

    if state.linkCapture and #state.linkCapture > 0 and not matchFound then
      local hasPartialMatches = false
      for i, _ in ipairs(state.marks) do
        local markText = string.upper(state.allCombinations[i])
        if markText:sub(1, #state.linkCapture) == state.linkCapture then
          hasPartialMatches = true
          break
        end
      end

      if not hasPartialMatches then
        state.linkCapture = ""
        marks.draw()
      end
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

  local foundMapping = M.config.mapping[keyCombo]

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

  if utils.isLauncherActive() then
    return false
  end

  local flags = event:getFlags()
  local keyCode = event:getKeyCode()
  local modifiers = { ctrl = flags.ctrl }

  -- Handle backspace in LINKS mode
  if state.elements.mode == modes.LINKS and keyCode == hs.keycodes.map["delete"] then
    timer.doAfter(0, function()
      vimLoop("backspace", modifiers)
    end)
    return true
  end

  for key, modifier in pairs(flags) do
    if modifier and key ~= "shift" and key ~= "ctrl" then
      return false
    end
  end

  if keyCode == hs.keycodes.map["escape"] then
    local delaySinceLastEscape = (timer.absoluteTime() - state.lastEscape) / 1e9 -- nanoseconds in seconds
    state.lastEscape = timer.absoluteTime()

    if utils.isInBrowser() and delaySinceLastEscape < M.config.doublePressDelay then
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

  if state.elements.mode == modes.INSERT or utils.isEditableControlInFocus() then
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

    for key, _ in pairs(M.config.mapping) do
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

local function onWindowFocused(window, name, object)
  log("onWindowFocused")
  if not state.eventLoop then
    state.eventLoop = eventtap.new({ hs.eventtap.event.types.keyDown }, eventHandler):start()
  end
  if not tblContains(M.config.excludedApps, name) then
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

local focusedEvents = {
  -- hs.window.filter.windowFocused,
  -- hs.window.filter.windowUnhidden,
  hs.window.filter.windowOnScreen,
}

local unfocusedEvents = {
  -- hs.window.filter.windowUnfocused,
  -- hs.window.filter.windowHidden,
  hs.window.filter.windowNotOnScreen,
}

M.config = {}

function M.setup(user_config)
  M.config = _utils.tbl_deep_extend("force", default_config, user_config or {})

  M:start()
end

function M:start()
  state.windowFilter = hs.window.filter.new()
  state.windowFilter:subscribe(focusedEvents, onWindowFocused)
  -- state.windowFilter:subscribe(unfocusedEvents, onWindowUnfocused)
  menuBar.new()
  utils.fetchMappingPrefixes()
  utils.generateCombinations()
end

function M:stop()
  if state.windowFilter then
    state.windowFilter:unsubscribe(onWindowFocused)
    -- state.windowFilter:unsubscribe(onWindowUnfocused)
    state.windowFilter = nil
  end
  menuBar.delete()
end

return M
