---@diagnostic disable: undefined-global

local _utils = require("utils")

local M = {}
M.__index = M

-- Cache frequently used functions
local floor = math.floor
local insert = table.insert
local format = string.format
local sub = string.sub
local pcall = pcall
local timer = hs.timer
local mouse = hs.mouse
local eventtap = hs.eventtap
local axuielement = hs.axuielement

--------------------------------------------------------------------------------
-- Constants and Configuration
--------------------------------------------------------------------------------

local MODES = {
  DISABLED = 1,
  NORMAL = 2,
  INSERT = 3,
  MULTI = 4,
  LINKS = 5,
}

local DEFAULT_MAPPING = {
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

local DEFAULT_CONFIG = {
  doublePressDelay = 0.3,
  showLogs = false,
  mapping = DEFAULT_MAPPING,
  scrollStep = 50,
  scrollStepHalfPage = 500,
  smoothScroll = true,
  smoothScrollFrameRate = 120,
  depth = 100,
  maxElements = 676, -- 26*26 combinations
  chunkSize = 10, -- Process elements in chunks for better performance
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
    "AXMenuBarItem",
    "AXMenuItem",
    "AXRow",
  },
  axScrollableRoles = { "AXScrollArea", "AXGroup" },
  excludedApps = { "Terminal" },
  browsers = { "Safari", "Google Chrome", "Firefox", "Microsoft Edge", "Brave Browser" },
  launchers = { "Spotlight" },
}

local Utils = {}

local Elements = {}

local MenuBar = {}

local ModeManager = {}

local Actions = {}

local ElementFinder = {}

local Marks = {}

local Commands = {}

--------------------------------------------------------------------------------
-- State Management with Better Structure
--------------------------------------------------------------------------------

local State = {
  mode = MODES.DISABLED,
  multi = nil,
  elements = {},
  marks = {},
  linkCapture = "",
  lastEscape = timer.absoluteTime(),
  mappingPrefixes = {},
  allCombinations = {},
  windowFilter = nil,
  eventLoop = nil,
  canvas = nil,
  onClickCallback = nil,
}

-- Element cache with weak references for garbage collection
local ElementCache = setmetatable({}, { __mode = "k" })

--------------------------------------------------------------------------------
-- Utility Functions (Improved)
--------------------------------------------------------------------------------

function Utils.yield()
  timer.usleep(1)
end

function Utils.log(message)
  if not M.config.showLogs then
    return
  end

  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local ms = floor(timer.absoluteTime() / 1e6) % 1000
  hs.printf("[%s.%03d] %s", timestamp, ms, message)
end

function Utils.tblContains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

function Utils.tblFilter(tbl, predicate)
  local result = {}
  for _, v in ipairs(tbl) do
    if predicate(v) then
      insert(result, v)
    end
  end
  return result
end

-- Improved caching with validation
function Utils.getCachedElement(key, factory)
  if
    ElementCache[key]
    and pcall(function()
      return ElementCache[key]:isValid()
    end)
    and ElementCache[key]:isValid()
  then
    return ElementCache[key]
  end

  local element = factory()
  if element then
    ElementCache[key] = element
  end
  return element
end

function Utils.clearCache()
  ElementCache = setmetatable({}, { __mode = "k" })
end

function Utils.getAttribute(element, attributeName)
  if not element then
    return nil
  end

  local success, result = pcall(function()
    return element:attributeValue(attributeName)
  end)

  return success and result or nil
end

function Utils.isElementValid(element)
  if not element then
    return false
  end

  local success = pcall(function()
    return element:isValid()
  end)

  return success
end

function Utils.generateCombinations()
  if #State.allCombinations > 0 then
    return
  end -- Already generated

  local chars = "abcdefghijklmnopqrstuvwxyz"
  for i = 1, #chars do
    for j = 1, #chars do
      insert(State.allCombinations, chars:sub(i, i) .. chars:sub(j, j))
      if #State.allCombinations >= M.config.maxElements then
        return
      end
    end
  end
end

function Utils.fetchMappingPrefixes()
  State.mappingPrefixes = {}
  for k, _ in pairs(M.config.mapping) do
    if #k == 2 then
      State.mappingPrefixes[sub(k, 1, 1)] = true
    end
  end
end

function Utils.isExcludedApp()
  local app = hs.application.frontmostApplication()
  return app and Utils.tblContains(M.config.excludedApps, app:name())
end

function Utils.isLauncherActive()
  for _, launcher in ipairs(M.config.launchers) do
    local app = hs.application.get(launcher)
    if app then
      local appElement = axuielement.applicationElement(app)
      if appElement then
        local windows = Utils.getAttribute(appElement, "AXWindows") or {}
        if #windows > 0 then
          return true, launcher
        end
      end
    end
  end
  return false
end

function Utils.isInBrowser()
  local app = hs.application.frontmostApplication()
  return app and Utils.tblContains(M.config.browsers, app:name())
end

--------------------------------------------------------------------------------
-- Element Access (Refactored)
--------------------------------------------------------------------------------

function Elements.getApp()
  return Utils.getCachedElement("app", function()
    return hs.application.frontmostApplication()
  end)
end

function Elements.getAxApp()
  return Utils.getCachedElement("axApp", function()
    local app = Elements.getApp()
    return app and axuielement.applicationElement(app)
  end)
end

function Elements.getWindow()
  return Utils.getCachedElement("window", function()
    local app = Elements.getApp()
    return app and app:focusedWindow()
  end)
end

function Elements.getAxWindow()
  return Utils.getCachedElement("axWindow", function()
    local window = Elements.getWindow()
    return window and axuielement.windowElement(window)
  end)
end

function Elements.getAxFocusedElement()
  return Utils.getCachedElement("axFocusedElement", function()
    local axApp = Elements.getAxApp()
    return axApp and Utils.getAttribute(axApp, "AXFocusedUIElement")
  end)
end

function Elements.getAxWebArea()
  return Utils.getCachedElement("axWebArea", function()
    local axWindow = Elements.getAxWindow()
    return axWindow and Elements.findAXRole(axWindow, "AXWebArea")
  end)
end

function Elements.getAxMenuBar()
  return Utils.getCachedElement("axMenuBar", function()
    local axApp = Elements.getAxApp()
    return axApp and Utils.getAttribute(axApp, "AXMenuBar")
  end)
end

function Elements.getFullArea()
  return Utils.getCachedElement("fullArea", function()
    local winFrame = Utils.getAttribute(Elements.getAxWindow(), "AXFrame") or {}
    local menuBarFrame = Utils.getAttribute(Elements.getAxMenuBar(), "AXFrame") or {}

    return {
      x = 0,
      y = 0,
      w = menuBarFrame.w,
      h = winFrame.h + winFrame.y + menuBarFrame.h,
    }
  end)
end

function Elements.findAXRole(rootElement, role)
  if not rootElement then
    return nil
  end

  local axRole = Utils.getAttribute(rootElement, "AXRole")
  if axRole == role then
    return rootElement
  end

  local axChildren = Utils.getAttribute(rootElement, "AXChildren") or {}
  for _, child in ipairs(axChildren) do
    local result = Elements.findAXRole(child, role)
    if result then
      return result
    end
  end

  return nil
end

function Elements.isEditableControlInFocus()
  local focusedElement = Elements.getAxFocusedElement()
  if not focusedElement then
    return false
  end

  local role = Utils.getAttribute(focusedElement, "AXRole")
  return role and Utils.tblContains(M.config.axEditableRoles, role)
end

--------------------------------------------------------------------------------
-- Menu Bar (Moved up for proper scoping)
--------------------------------------------------------------------------------

function MenuBar.create()
  if MenuBar.item then
    MenuBar.destroy()
  end
  MenuBar.item = hs.menubar.new()
  MenuBar.item:setTitle("N")
end

function MenuBar.destroy()
  if MenuBar.item then
    MenuBar.item:delete()
    MenuBar.item = nil
  end
end

--------------------------------------------------------------------------------
-- Mode Management
--------------------------------------------------------------------------------

function ModeManager.setMode(mode, char)
  local defaultModeChars = {
    [MODES.DISABLED] = "X",
    [MODES.INSERT] = "I",
    [MODES.LINKS] = "L",
    [MODES.MULTI] = "M",
    [MODES.NORMAL] = "N",
  }

  local previousMode = State.mode
  State.mode = mode

  if mode == MODES.LINKS and previousMode ~= MODES.LINKS then
    State.linkCapture = ""
    Marks.clear()
  elseif previousMode == MODES.LINKS and mode ~= MODES.LINKS then
    timer.doAfter(0, Marks.clear)
  end

  if mode == MODES.MULTI then
    State.multi = char
  else
    State.multi = nil
  end

  if MenuBar.item then
    MenuBar.item:setTitle(char or defaultModeChars[mode] or "?")
  end
end

--------------------------------------------------------------------------------
-- Actions (Improved with Error Handling)
--------------------------------------------------------------------------------

function Actions.smoothScroll(x, y, smooth)
  if not smooth then
    eventtap.event.newScrollEvent({ x or 0, y or 0 }, {}, "pixel"):post()
    return
  end

  local steps = 5
  local dx = x and (x / steps) or 0
  local dy = y and (y / steps) or 0
  local frame = 0
  local interval = 1 / M.config.smoothScrollFrameRate

  local function animate()
    frame = frame + 1
    if frame > steps then
      return
    end

    local factor = frame <= steps / 2 and 2 or 0.5
    eventtap.event.newScrollEvent({ dx * factor, dy * factor }, {}, "pixel"):post()
    timer.doAfter(interval, animate)
  end

  animate()
end

function Actions.openUrlInNewTab(url)
  if not url then
    return
  end

  local browserScripts = {
    Safari = 'tell application "Safari" to tell window 1 to set current tab to (make new tab with properties {URL:"%s"})',
    ["Google Chrome"] = 'tell application "Google Chrome" to tell window 1 to make new tab with properties {URL:"%s"}',
    Firefox = 'tell application "Firefox" to tell window 1 to open location "%s"',
    ["Microsoft Edge"] = 'tell application "Microsoft Edge" to tell window 1 to make new tab with properties {URL:"%s"}',
    ["Brave Browser"] = 'tell application "Brave Browser" to tell window 1 to make new tab with properties {URL:"%s"}',
  }

  local currentApp = Elements.getApp()
  if not currentApp then
    return
  end

  local appName = currentApp:name()
  local script = browserScripts[appName] or browserScripts["Safari"]

  hs.osascript.applescript(format(script, url))
end

function Actions.setClipboardContents(contents)
  if not contents then
    hs.alert.show("Nothing to copy", nil, nil, 2)
    return
  end

  if hs.pasteboard.setContents(contents) then
    hs.alert.show("Copied: " .. contents:sub(1, 50) .. (contents:len() > 50 and "..." or ""), nil, nil, 2)
  else
    hs.alert.show("Failed to copy to clipboard", nil, nil, 2)
  end
end

--------------------------------------------------------------------------------
-- Element Finding (Optimized)
--------------------------------------------------------------------------------

function ElementFinder.isElementVisible(element)
  if not element then
    return false
  end

  local hidden = Utils.getAttribute(element, "AXHidden")
  local frame = Utils.getAttribute(element, "AXFrame")

  if hidden or not frame or frame.w <= 0 or frame.h <= 0 then
    return false
  end

  -- Simplified visibility check
  return frame.x >= 0 and frame.y >= 0 and frame.x < 3000 and frame.y < 3000
end

function ElementFinder.isElementActionable(element)
  if not element then
    return false
  end

  local role = Utils.getAttribute(element, "AXRole")
  return role and Utils.tblContains(M.config.axJumpableRoles, role)
end

function ElementFinder.processChildren(element, callback, depth)
  if not element or depth > M.config.depth then
    return
  end

  local children = Utils.getAttribute(element, "AXChildren") or {}
  local chunkSize = M.config.chunkSize

  -- Process in chunks to prevent blocking
  for i = 1, #children, chunkSize do
    local endIdx = math.min(i + chunkSize - 1, #children)

    for j = i, endIdx do
      if Utils.isElementValid(children[j]) then
        callback(children[j], depth + 1)
      end
    end

    -- Yield control briefly for large element trees
    if i > chunkSize then
      Utils.yield()
    end
  end
end

function ElementFinder.findElements(rootElement, predicate, callback)
  if not rootElement then
    return
  end

  local function processElement(element, depth)
    if depth > M.config.depth then
      return
    end

    local role = Utils.getAttribute(element, "AXRole")
    if role ~= "AXApplication" and ElementFinder.isElementVisible(element) then
      if predicate(element) then
        callback(element)
      end
    end

    ElementFinder.processChildren(element, processElement, depth)
  end

  processElement(rootElement, 0)
end

--------------------------------------------------------------------------------
-- Marks System (Improved)
--------------------------------------------------------------------------------

function Marks.clear()
  if State.canvas then
    State.canvas:delete()
    State.canvas = nil
  end
  State.marks = {}
  State.linkCapture = ""
end

function Marks.add(element)
  if #State.marks >= M.config.maxElements then
    return
  end
  insert(State.marks, { element = element })
end

function Marks.show(withUrls, elementType)
  local axApp = Elements.getAxApp()
  if not axApp then
    return
  end

  Marks.clear()

  local predicates = {
    link = function(el)
      return ElementFinder.isElementActionable(el) and (not withUrls or Utils.getAttribute(el, "AXURL"))
    end,
    input = function(el)
      return Utils.tblContains(M.config.axEditableRoles, Utils.getAttribute(el, "AXRole") or "")
    end,
    image = function(el)
      return Utils.getAttribute(el, "AXRole") == "AXImage" and Utils.getAttribute(el, "AXURL")
    end,
  }

  local predicate = predicates[elementType]
  if not predicate then
    return
  end

  ElementFinder.findElements(axApp, predicate, Marks.add)

  if #State.marks == 0 then
    hs.alert.show("No " .. elementType .. "s found", nil, nil, 2)
    ModeManager.setMode(MODES.NORMAL)
    return
  end

  -- Auto-click if only one input element
  if elementType == "input" and #State.marks == 1 then
    State.onClickCallback(State.marks[1])
    ModeManager.setMode(MODES.NORMAL)
    return
  end

  Marks.draw()
end

function Marks.draw()
  if not State.canvas then
    local frame = Elements.getFullArea()
    if not frame then
      return
    end

    State.canvas = hs.canvas.new(frame)
  end

  local elementsToDraw = {}

  for i, mark in ipairs(State.marks) do
    if i > #State.allCombinations then
      break
    end

    local markText = State.allCombinations[i]:upper()

    if #State.linkCapture == 0 or markText:sub(1, #State.linkCapture) == State.linkCapture then
      local element = Marks.createMarkElement(mark.element, markText)
      if element then
        for _, e in ipairs(element) do
          insert(elementsToDraw, e)
        end
      end
    end
  end

  if #elementsToDraw > 0 then
    State.canvas:replaceElements(elementsToDraw)
    State.canvas:show()
  else
    State.canvas:hide()
  end
end

function Marks.createMarkElement(element, text)
  local frame = Utils.getAttribute(element, "AXFrame")
  if not frame then
    return nil
  end

  local padding = 2
  local fontSize = 10
  local textWidth = #text * (fontSize * 1.1)
  local textHeight = fontSize * 1.1
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
    frame.x + (frame.w / 2) - (containerWidth / 2),
    frame.y + (frame.h / 3 * 2) + arrowHeight,
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

function Marks.click(combination)
  for i, c in ipairs(State.allCombinations) do
    if c == combination and State.marks[i] and State.onClickCallback then
      local success, err = pcall(State.onClickCallback, State.marks[i])
      if not success then
        Utils.log("Error clicking element: " .. tostring(err))
      end
      break
    end
  end
end

--------------------------------------------------------------------------------
-- Commands (Streamlined)
--------------------------------------------------------------------------------

-- Scrolling commands
function Commands.cmdScrollLeft()
  Actions.smoothScroll(M.config.scrollStep, 0, M.config.smoothScroll)
end
function Commands.cmdScrollRight()
  Actions.smoothScroll(-M.config.scrollStep, 0, M.config.smoothScroll)
end
function Commands.cmdScrollUp()
  Actions.smoothScroll(0, M.config.scrollStep, M.config.smoothScroll)
end
function Commands.cmdScrollDown()
  Actions.smoothScroll(0, -M.config.scrollStep, M.config.smoothScroll)
end
function Commands.cmdScrollHalfPageDown()
  Actions.smoothScroll(0, -M.config.scrollStepHalfPage, M.config.smoothScroll)
end
function Commands.cmdScrollHalfPageUp()
  Actions.smoothScroll(0, M.config.scrollStepHalfPage, M.config.smoothScroll)
end
function Commands.cmdScrollToTop()
  eventtap.keyStroke({ "command" }, "up", 0)
end
function Commands.cmdScrollToBottom()
  eventtap.keyStroke({ "command" }, "down", 0)
end

-- Mode commands
function Commands.cmdInsertMode()
  ModeManager.setMode(MODES.INSERT)
end

-- Link commands
function Commands.cmdGotoLink()
  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local element = mark.element
    local actions = element and element:actionNames() or {}

    if Utils.tblContains(actions, "AXPress") then
      element:performAction("AXPress")
    else
      -- Fallback to mouse click
      local frame = Utils.getAttribute(element, "AXFrame")
      if frame then
        local clickX, clickY = frame.x + frame.w / 2, frame.y + frame.h / 2
        local originalPos = mouse.absolutePosition()
        mouse.absolutePosition({ x = clickX, y = clickY })
        eventtap.leftClick({ x = clickX, y = clickY })
        timer.doAfter(0.1, function()
          mouse.absolutePosition(originalPos)
        end)
      end
    end
  end
  timer.doAfter(0, function()
    Marks.show(false, "link")
  end)
end

function Commands.cmdGotoInput()
  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = Commands.cmdGotoLink().onClickCallback
  timer.doAfter(0, function()
    Marks.show(false, "input")
  end)
end

function Commands.cmdRightClick()
  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local element = mark.element
    local actions = element and element:actionNames() or {}

    if Utils.tblContains(actions, "AXShowMenu") then
      element:performAction("AXShowMenu")
    else
      local frame = Utils.getAttribute(element, "AXFrame")
      if frame then
        local clickX, clickY = frame.x + frame.w / 2, frame.y + frame.h / 2
        local originalPos = mouse.absolutePosition()
        mouse.absolutePosition({ x = clickX, y = clickY })
        eventtap.rightClick({ x = clickX, y = clickY })
        timer.doAfter(0.05, function()
          mouse.absolutePosition(originalPos)
        end)
      end
    end
  end
  timer.doAfter(0, function()
    Marks.show(false, "link")
  end)
end

function Commands.cmdGotoLinkNewTab()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local url = Utils.getAttribute(mark.element, "AXURL")
    if url then
      Actions.openUrlInNewTab(url.url)
    end
  end
  timer.doAfter(0, function()
    Marks.show(true, "link")
  end)
end

function Commands.cmdDownloadImage()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local element = mark.element
    local role = Utils.getAttribute(element, "AXRole")

    if role == "AXImage" then
      local description = Utils.getAttribute(element, "AXDescription") or "image"

      local downloadUrlAttr = Utils.getAttribute(element, "AXURL")

      if downloadUrlAttr then
        local url = downloadUrlAttr.url

        if url and url:match("^data:image/") then
          -- Handle base64 images
          local base64Data = url:match("^data:image/[^;]+;base64,(.+)$")
          if base64Data then
            local decodedData = hs.base64.decode(base64Data)
            local fileName = description:gsub("%W+", "_") .. ".jpg"
            local filePath = os.getenv("HOME") .. "/Downloads/" .. fileName

            local file = io.open(filePath, "wb")
            if file then
              file:write(decodedData)
              file:close()
              hs.alert.show("Image saved: " .. fileName, nil, nil, 2)
            end
          end
        else
          -- Handle regular URLs
          hs.http.asyncGet(url, nil, function(status, body, headers)
            if status == 200 then
              local contentType = headers["Content-Type"] or ""
              if contentType:match("^image/") then
                local fileName = url:match("^.+/(.+)$") or "image.jpg"
                if not fileName:match("%.%w+$") then
                  fileName = fileName .. ".jpg"
                end

                local filePath = os.getenv("HOME") .. "/Downloads/" .. fileName
                local file = io.open(filePath, "wb")
                if file then
                  file:write(body)
                  file:close()
                  hs.alert.show("Image downloaded: " .. fileName, nil, nil, 2)
                end
              end
            end
          end)
        end
      end
    end
  end
  timer.doAfter(0, function()
    Marks.show(false, "image")
  end)
end

function Commands.cmdMoveMouseToLink()
  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local frame = Utils.getAttribute(mark.element, "AXFrame")
    if frame then
      mouse.absolutePosition({
        x = frame.x + frame.w / 2,
        y = frame.y + frame.h / 2,
      })
    end
  end
  timer.doAfter(0, function()
    Marks.show(false, "link")
  end)
end

function Commands.cmdCopyLinkUrlToClipboard()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local url = Utils.getAttribute(mark.element, "AXURL")
    if url then
      Actions.setClipboardContents(url.url)
    else
      hs.alert.show("No URL found", nil, nil, 2)
    end
  end
  timer.doAfter(0, function()
    Marks.show(true, "link")
  end)
end

function Commands.cmdNextPage()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local function findNextButton(element, depth)
    if not element or depth > M.config.depth then
      return false
    end

    local role = Utils.getAttribute(element, "AXRole")
    local title = Utils.getAttribute(element, "AXTitle")

    if (role == "AXLink" or role == "AXButton") and title then
      if title:lower():find("next") then
        element:performAction("AXPress")
        return true
      end
    end

    local children = Utils.getAttribute(element, "AXChildren") or {}
    for _, child in ipairs(children) do
      if findNextButton(child, depth + 1) then
        return true
      end
    end

    return false
  end

  local axWindow = Elements.getAxWindow()
  if axWindow then
    if not findNextButton(axWindow, 0) then
      hs.alert.show("No Next button found", nil, nil, 2)
    end
  end
end

function Commands.cmdPrevPage()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local function findPrevButton(element, depth)
    if not element or depth > M.config.depth then
      return false
    end

    local role = Utils.getAttribute(element, "AXRole")
    local title = Utils.getAttribute(element, "AXTitle")

    if (role == "AXLink" or role == "AXButton") and title then
      if title:lower():find("prev") or title:lower():find("previous") then
        element:performAction("AXPress")
        return true
      end
    end

    local children = Utils.getAttribute(element, "AXChildren") or {}
    for _, child in ipairs(children) do
      if findPrevButton(child, depth + 1) then
        return true
      end
    end

    return false
  end

  local axWindow = Elements.getAxWindow()
  if axWindow then
    if not findPrevButton(axWindow, 0) then
      hs.alert.show("No Previous button found", nil, nil, 2)
    end
  end
end

-- Utility commands
function Commands.cmdCopyPageUrlToClipboard()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local webArea = Elements.getAxWebArea()
  local url = webArea and Utils.getAttribute(webArea, "AXURL")
  if url then
    Actions.setClipboardContents(url.url)
  end
end

function Commands.cmdMoveMouseToCenter()
  local window = Elements.getWindow()
  if not window then
    return
  end

  local frame = window:frame()
  mouse.absolutePosition({
    x = frame.x + frame.w / 2,
    y = frame.y + frame.h / 2,
  })
end

--------------------------------------------------------------------------------
-- Event Handling (Improved)
--------------------------------------------------------------------------------

local function handleVimInput(char, modifiers)
  Utils.log("handleVimInput: " .. char .. " modifiers: " .. hs.inspect(modifiers))

  if State.mode == MODES.LINKS then
    if char == "backspace" then
      if #State.linkCapture > 0 then
        State.linkCapture = State.linkCapture:sub(1, -2)
        Marks.draw()
      end
      return
    end

    State.linkCapture = State.linkCapture .. char:upper()
    Marks.draw()

    -- Check for exact match
    for i, _ in ipairs(State.marks) do
      if i > #State.allCombinations then
        break
      end

      local markText = State.allCombinations[i]:upper()
      if markText == State.linkCapture then
        Marks.click(markText:lower())
        ModeManager.setMode(MODES.NORMAL)
        return
      end
    end

    -- Check for partial matches
    local hasPartialMatches = false
    for i, _ in ipairs(State.marks) do
      if i > #State.allCombinations then
        break
      end

      local markText = State.allCombinations[i]:upper()
      if markText:sub(1, #State.linkCapture) == State.linkCapture then
        hasPartialMatches = true
        break
      end
    end

    if not hasPartialMatches then
      State.linkCapture = ""
      Marks.draw()
    end
    return
  end

  -- Build key combination
  local keyCombo = ""
  if modifiers and modifiers.ctrl then
    keyCombo = "C-"
  end
  keyCombo = keyCombo .. char

  if State.mode == MODES.MULTI then
    keyCombo = State.multi .. keyCombo
  end

  -- Execute mapping
  local mapping = M.config.mapping[keyCombo]
  if mapping then
    ModeManager.setMode(MODES.NORMAL)

    if type(mapping) == "string" then
      local cmd = Commands[mapping]
      if cmd then
        cmd()
      else
        Utils.log("Unknown command: " .. mapping)
      end
    elseif type(mapping) == "table" then
      eventtap.keyStroke(mapping[1], mapping[2], 0)
    end
  elseif State.mappingPrefixes[keyCombo] then
    ModeManager.setMode(MODES.MULTI, keyCombo)
  end
end

local function eventHandler(event)
  Utils.clearCache()

  if Utils.isExcludedApp() or Utils.isLauncherActive() then
    return false
  end

  local flags = event:getFlags()
  local keyCode = event:getKeyCode()

  -- Handle escape key
  if keyCode == hs.keycodes.map["escape"] then
    local delaySinceLastEscape = (timer.absoluteTime() - State.lastEscape) / 1e9
    State.lastEscape = timer.absoluteTime()

    if Utils.isInBrowser() and delaySinceLastEscape < M.config.doublePressDelay then
      ModeManager.setMode(MODES.NORMAL)
      return true
    end

    if State.mode ~= MODES.NORMAL then
      ModeManager.setMode(MODES.NORMAL)
      return true
    end

    return false
  end

  -- Skip if in insert mode or editable control has focus
  if State.mode == MODES.INSERT or Elements.isEditableControlInFocus() then
    return false
  end

  -- Handle backspace in LINKS mode
  if State.mode == MODES.LINKS and keyCode == hs.keycodes.map["delete"] then
    timer.doAfter(0, function()
      handleVimInput("backspace", { ctrl = flags.ctrl })
    end)
    return true
  end

  local char = hs.keycodes.map[keyCode]
  if not char then
    return false
  end

  -- Check for invalid modifiers (except shift and ctrl)
  for key, modifier in pairs(flags) do
    if modifier and key ~= "shift" and key ~= "ctrl" then
      return false
    end

    local filteredMappings = {}

    for _key, _ in pairs(M.config.mapping) do
      if _key:sub(1, 2) == "C-" then
        table.insert(filteredMappings, _key:sub(3))
      end
    end

    if Utils.tblContains(filteredMappings, char) == false then
      return false
    end
  end

  if flags.shift then
    char = event:getCharacters()
  end

  -- Only handle single alphanumeric characters and some symbols
  if not char:match("[%a%d%[%]%$]") or #char ~= 1 then
    return false
  end

  timer.doAfter(0, function()
    handleVimInput(char, { ctrl = flags.ctrl })
  end)

  return true
end

--------------------------------------------------------------------------------
-- Window Management
--------------------------------------------------------------------------------

local function onWindowFocused(window, appName)
  Utils.log("Window focused: " .. (appName or "unknown"))

  if not State.eventLoop then
    State.eventLoop = eventtap.new({ eventtap.event.types.keyDown }, eventHandler):start()
  end

  if Utils.tblContains(M.config.excludedApps, appName) then
    ModeManager.setMode(MODES.DISABLED)
  else
    ModeManager.setMode(MODES.NORMAL)
  end
end

--------------------------------------------------------------------------------
-- Module Interface
--------------------------------------------------------------------------------

M.config = {}

function M.setup(userConfig)
  M.config = _utils.tbl_deep_extend("force", DEFAULT_CONFIG, userConfig or {})
  M:start()
end

function M:start()
  State.windowFilter = hs.window.filter.new()
  State.windowFilter:subscribe(hs.window.filter.windowOnScreen, onWindowFocused)

  MenuBar.create()
  Utils.fetchMappingPrefixes()
  Utils.generateCombinations()

  ModeManager.setMode(MODES.NORMAL)

  Utils.log("Vim navigation started")
end

function M:stop()
  if State.windowFilter then
    State.windowFilter:unsubscribeAll()
    State.windowFilter = nil
  end

  if State.eventLoop then
    State.eventLoop:stop()
    State.eventLoop = nil
  end

  MenuBar.destroy()
  Marks.clear()

  Utils.log("Vim navigation stopped")
end

-- Expose useful functions for debugging
M.debug = {
  getState = function()
    return State
  end,
  getElements = function()
    return Elements
  end,
  clearCache = Utils.clearCache,
  log = Utils.log,
}

return M
