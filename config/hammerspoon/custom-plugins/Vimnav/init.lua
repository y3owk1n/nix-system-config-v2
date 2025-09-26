-- Vimnav.spoon
--
-- Think of it like vimium, but available for system wide. Probably won't work on electron apps though, I don't use them.
--
-- This module is originated and credits to `dzirtuss` at `https://github.com/dzirtusss/vifari`
-- I had made lots of modifications to the original code including performance and supporting for system wide instead
-- of just within Safari. In my opinion, there are too many changes that made it hard to contribute back to the original
-- project, and Vifari is meant for only for Safari, not system wide.

---@diagnostic disable: undefined-global

---@class Hs.Vimnav
local M = {}

M.__index = M

M.name = "vimnav"

local _utils = require("utils")

local Utils = {}
local Elements = {}
local MenuBar = {}
local ModeManager = {}
local Actions = {}
local ElementFinder = {}
local Marks = {}
local Commands = {}
local State = {}
local SpatialIndex = {}
local AsyncTraversal = {}
local RoleMaps = {}
local MarkPool = {}
local CanvasCache = {}

local log

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

---@class Hs.Vimnav.Config
---@field logLevel string
---@field doublePressDelay number
---@field mapping table<string, string|table>
---@field scrollStep number
---@field scrollStepHalfPage number
---@field scrollStepFullPage number
---@field smoothScroll boolean
---@field smoothScrollFramerate number
---@field depth number
---@field maxElements number
---@field axEditableRoles string[]
---@field axJumpableRoles string[]
---@field excludedApps string[]
---@field browsers string[]
---@field launchers string[]

---@class Hs.Vimnav.State
---@field mode number
---@field multi string|nil
---@field elements table<string, table>
---@field marks table<number, table<string, table|nil>>
---@field linkCapture string
---@field lastEscape number
---@field mappingPrefixes table<string, boolean>
---@field allCombinations string[]
---@field eventLoop table|nil
---@field canvas table|nil
---@field onClickCallback fun(any)|nil
---@field cleanupTimer table|nil

---@alias Hs.Vimnav.Element table|string

---@alias Hs.Vimnav.Modifier "cmd"|"ctrl"|"alt"|"shift"|"fn"

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

---@type Hs.Vimnav.Config
local DEFAULT_CONFIG = {
  logLevel = "warning",
  doublePressDelay = 0.3,
  mapping = DEFAULT_MAPPING,
  scrollStep = 50,
  scrollStepHalfPage = 500,
  scrollStepFullPage = 1e6,
  smoothScroll = true,
  smoothScrollFramerate = 120,
  depth = 20,
  maxElements = 676, -- 26*26 combinations
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
  excludedApps = { "Terminal" },
  browsers = { "Safari", "Google Chrome", "Firefox", "Microsoft Edge", "Brave Browser", "Zen" },
  launchers = { "Spotlight", "Raycast", "Alfred" },
}

--------------------------------------------------------------------------------
-- State Management
--------------------------------------------------------------------------------

---@type Hs.Vimnav.State
State = {
  mode = MODES.DISABLED,
  multi = nil,
  elements = {},
  marks = {},
  linkCapture = "",
  lastEscape = hs.timer.absoluteTime(),
  mappingPrefixes = {},
  allCombinations = {},
  eventLoop = nil,
  canvas = nil,
  onClickCallback = nil,
  cleanupTimer = nil,
}

-- Element cache with weak references for garbage collection
local elementCache = setmetatable({}, { __mode = "k" })

local attributeCache = setmetatable({}, { __mode = "k" })

--------------------------------------------------------------------------------
-- Spatial Indexing
--------------------------------------------------------------------------------

---Quad-tree like spatial indexing for viewport culling
---@return table|nil
function SpatialIndex.createViewportRegions()
  local fullArea = Elements.getFullArea()
  if not fullArea then
    return nil
  end

  return {
    x = fullArea.x,
    y = fullArea.y,
    w = fullArea.w,
    h = fullArea.h,
    centerX = fullArea.x + fullArea.w / 2,
    centerY = fullArea.y + fullArea.h / 2,
  }
end

---Checks if the element is in the viewport
---@param fx number
---@param fy number
---@param fw number
---@param fh number
---@param viewport table
---@return boolean
function SpatialIndex.isInViewport(fx, fy, fw, fh, viewport)
  return fx < viewport.x + viewport.w
    and fx + fw > viewport.x
    and fy < viewport.y + viewport.h
    and fy + fh > viewport.y
    and fw > 2
    and fh > 2 -- Skip tiny elements
end

--------------------------------------------------------------------------------
-- Coroutine-based Async Traversal
--------------------------------------------------------------------------------

---Process elements in background coroutine to avoid UI blocking
---@param element table
---@param matcher fun(element: table): boolean
---@param callback fun(results: table)
---@param maxResults number
---@return nil
function AsyncTraversal.traverseAsync(element, matcher, callback, maxResults)
  local results = {}
  local viewport = SpatialIndex.createViewportRegions()

  if not viewport then
    callback({})
    return
  end

  local traverseCoroutine = coroutine.create(function()
    AsyncTraversal.walkElement(element, 0, matcher, function(el)
      results[#results + 1] = el
      return #results >= maxResults
    end, viewport)
  end)

  -- Resume coroutine in chunks
  local function resumeWork()
    if coroutine.status(traverseCoroutine) == "dead" then
      callback(results)
      return
    end

    local success, shouldStop = coroutine.resume(traverseCoroutine)
    if success and not shouldStop then
      hs.timer.doAfter(0.001, resumeWork) -- 1ms pause
    else
      callback(results)
    end
  end

  resumeWork()
end

---Walks an element with a matcher
---@param element table
---@param depth number
---@param matcher fun(element: table): boolean
---@param callback fun(element: table): boolean
---@param viewport table
---@return boolean|nil
function AsyncTraversal.walkElement(element, depth, matcher, callback, viewport)
  if depth > M.config.depth then
    return
  end -- Hard depth limit

  local batchSize = 0
  local function processElement(el)
    batchSize = batchSize + 1

    -- Batch yield every 30 elements to stay responsive
    if batchSize % 30 == 0 then
      coroutine.yield(false) -- Don't stop, just yield
    end

    -- Get frame once, reuse everywhere
    local frame = Utils.getAttribute(el, "AXFrame")
    if not frame then
      return
    end

    -- Viewport check
    if not SpatialIndex.isInViewport(frame.x, frame.y, frame.w, frame.h, viewport) then
      return
    end

    -- Test element
    if matcher(el) then
      if callback(el) then -- callback returns true to stop
        return true
      end
    end

    -- Process children
    local children = Utils.getAttribute(el, "AXVisibleChildren") or Utils.getAttribute(el, "AXChildren") or {}

    for i = 1, #children do
      if AsyncTraversal.walkElement(children[i], depth + 1, matcher, callback, viewport) then
        return true
      end
    end
  end

  local role = Utils.getAttribute(element, "AXRole")
  if role == "AXApplication" then
    local children = Utils.getAttribute(element, "AXChildren") or {}
    for i = 1, #children do
      if processElement(children[i]) then
        return true
      end
    end
  else
    return processElement(element)
  end
end

--------------------------------------------------------------------------------
-- Pre-computed Role Maps and Lookup Tables
--------------------------------------------------------------------------------

---Pre-compute role sets as hash maps for O(1) lookup
---@return nil
function RoleMaps.init()
  RoleMaps.jumpableSet = {}
  for _, role in ipairs(M.config.axJumpableRoles) do
    RoleMaps.jumpableSet[role] = true
  end

  RoleMaps.editableSet = {}
  for _, role in ipairs(M.config.axEditableRoles) do
    RoleMaps.editableSet[role] = true
  end

  RoleMaps.skipSet = {
    AXGenericElement = true,
    AXUnknown = true,
    AXSeparator = true,
    AXSplitter = true,
    AXProgressIndicator = true,
    AXValueIndicator = true,
    AXLayoutArea = true,
    AXLayoutItem = true,
    AXStaticText = true, -- Usually not interactive
  }
  log.df("Initialized role maps")
end

---Checks if the role is jumpable
---@param role string
---@return boolean
function RoleMaps.isJumpable(role)
  return RoleMaps.jumpableSet and RoleMaps.jumpableSet[role] == true
end

---Checks if the role is editable
---@param role string
---@return boolean
function RoleMaps.isEditable(role)
  return RoleMaps.editableSet and RoleMaps.editableSet[role] == true
end

---Checks if the role should be skipped
---@param role string
---@return boolean
function RoleMaps.shouldSkip(role)
  return RoleMaps.skipSet and RoleMaps.skipSet[role] == true
end

--------------------------------------------------------------------------------
-- Memory Pool for Mark Elements
--------------------------------------------------------------------------------

MarkPool.pool = {}
MarkPool.active = {}

---Reuse mark objects to avoid GC pressure
---@return table
function MarkPool.getMark()
  local mark = table.remove(MarkPool.pool)
  if not mark then
    mark = { element = nil, frame = nil, role = nil }
  end
  MarkPool.active[#MarkPool.active + 1] = mark
  return mark
end

---Release all marks
---@return nil
function MarkPool.releaseAll()
  for i = 1, #MarkPool.active do
    local mark = MarkPool.active[i]
    mark.element = nil
    mark.frame = nil
    mark.role = nil
    MarkPool.pool[#MarkPool.pool + 1] = mark
  end
  MarkPool.active = {}
end

--------------------------------------------------------------------------------
-- Canvas Element Caching
--------------------------------------------------------------------------------

---Returns the mark template
---@return table
function CanvasCache.getMarkTemplate()
  if CanvasCache.template then
    return CanvasCache.template
  end

  CanvasCache.template = {
    background = {
      type = "segments",
      fillGradient = "linear",
      fillGradientColors = {
        { red = 1, green = 0.96, blue = 0.52, alpha = 1 },
        {
          red = 1,
          green = 0.77,
          blue = 0.26,
          alpha = 1,
        },
      },
      strokeColor = { red = 0, green = 0, blue = 0, alpha = 1 },
      strokeWidth = 1,
      closed = true,
    },
    text = {
      type = "text",
      textAlignment = "center",
      textColor = { red = 0, green = 0, blue = 0, alpha = 1 },
      textSize = 10,
      textFont = ".AppleSystemUIFontHeavy",
    },
  }

  return CanvasCache.template
end

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

---imports from utils
---can be implemented in this file if publishing as a module
Utils.tblContains = _utils.tblContains
Utils.tblDeepExtend = _utils.tblDeepExtend
Utils.keyStroke = _utils.keyStroke

---Gets an element from the cache
---@param key string
---@param factory fun(): Hs.Vimnav.Element|nil
---@return Hs.Vimnav.Element|nil
function Utils.getCachedElement(key, factory)
  if
    elementCache[key]
    and pcall(function()
      return elementCache[key]:isValid()
    end)
    and elementCache[key]:isValid()
  then
    return elementCache[key]
  end

  local element = factory()
  if element then
    elementCache[key] = element
  end
  return element
end

---Clears the element cache
---@return nil
function Utils.clearCache()
  elementCache = setmetatable({}, { __mode = "k" })
  attributeCache = setmetatable({}, { __mode = "k" })
end

---Gets an attribute from an element
---@param element Hs.Vimnav.Element
---@param attributeName string
---@return Hs.Vimnav.Element|nil
function Utils.getAttribute(element, attributeName)
  if not element then
    return nil
  end

  local cacheKey = tostring(element) .. ":" .. attributeName
  local cached = attributeCache[cacheKey]

  if cached ~= nil then
    return cached == "NIL_VALUE" and nil or cached
  end

  local success, result = pcall(function()
    return element:attributeValue(attributeName)
  end)

  result = success and result or nil

  -- Store nil as a special marker to distinguish from uncached
  attributeCache[cacheKey] = result == nil and "NIL_VALUE" or result
  return result
end

---Generates all combinations of letters
---@return nil
function Utils.generateCombinations()
  if #State.allCombinations > 0 then
    log.df("Already generated combinations")
    return
  end -- Already generated

  local chars = "abcdefghijklmnopqrstuvwxyz"
  for i = 1, #chars do
    for j = 1, #chars do
      table.insert(State.allCombinations, chars:sub(i, i) .. chars:sub(j, j))
      if #State.allCombinations >= M.config.maxElements then
        return
      end
    end
  end
  log.df("Generated " .. #State.allCombinations .. " combinations")
end

---Fetches all mapping prefixes
---@return nil
function Utils.fetchMappingPrefixes()
  State.mappingPrefixes = {}
  for k, _ in pairs(M.config.mapping) do
    if #k == 2 then
      State.mappingPrefixes[string.sub(k, 1, 1)] = true
    end
  end
  log.df("Fetched mapping prefixes")
end

---Checks if the current application is excluded
---@return boolean
function Utils.isExcludedApp()
  local app = hs.application.frontmostApplication()
  return app and Utils.tblContains(M.config.excludedApps, app:name())
end

---Checks if the launcher is active
---@return boolean
---@return string|nil
function Utils.isLauncherActive()
  for _, launcher in ipairs(M.config.launchers) do
    local app = hs.application.get(launcher)
    if app then
      local appElement = hs.axuielement.applicationElement(app)
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

---Checks if the application is in the browser list
---@return boolean
function Utils.isInBrowser()
  local app = hs.application.frontmostApplication()
  return app and Utils.tblContains(M.config.browsers, app:name())
end

--------------------------------------------------------------------------------
-- Element Access
--------------------------------------------------------------------------------

---Returns the application element
---@return Hs.Vimnav.Element|nil
function Elements.getApp()
  return Utils.getCachedElement("app", function()
    return hs.application.frontmostApplication()
  end)
end

---Returns the application element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxApp()
  return Utils.getCachedElement("axApp", function()
    local app = Elements.getApp()
    return app and hs.axuielement.applicationElement(app)
  end)
end

---Returns the window element
---@return Hs.Vimnav.Element|nil
function Elements.getWindow()
  return Utils.getCachedElement("window", function()
    local app = Elements.getApp()
    return app and app:focusedWindow()
  end)
end

---Returns the window element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxWindow()
  return Utils.getCachedElement("axWindow", function()
    local window = Elements.getWindow()
    return window and hs.axuielement.windowElement(window)
  end)
end

---Returns the focused element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxFocusedElement()
  return Utils.getCachedElement("axFocusedElement", function()
    local axApp = Elements.getAxApp()
    return axApp and Utils.getAttribute(axApp, "AXFocusedUIElement")
  end)
end

---Returns the web area element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxWebArea()
  return Utils.getCachedElement("axWebArea", function()
    local axWindow = Elements.getAxWindow()
    return axWindow and Elements.findAxRole(axWindow, "AXWebArea")
  end)
end

---Returns the menu bar element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxMenuBar()
  return Utils.getCachedElement("axMenuBar", function()
    local axApp = Elements.getAxApp()
    return axApp and Utils.getAttribute(axApp, "AXMenuBar")
  end)
end

---Returns the full area element
---@return Hs.Vimnav.Element|nil
function Elements.getFullArea()
  return Utils.getCachedElement("fullArea", function()
    local axWin = Elements.getAxWindow()
    local axMenuBar = Elements.getAxMenuBar()

    if not axWin or not axMenuBar then
      return nil
    end

    local winFrame = Utils.getAttribute(axWin, "AXFrame") or {}
    local menuBarFrame = Utils.getAttribute(axMenuBar, "AXFrame") or {}

    return {
      x = 0,
      y = 0,
      w = menuBarFrame.w,
      h = winFrame.h + winFrame.y + menuBarFrame.h,
    }
  end)
end

---Finds an element with a specific AXRole
---@param rootElement Hs.Vimnav.Element
---@param role string
---@return Hs.Vimnav.Element|nil
function Elements.findAxRole(rootElement, role)
  if not rootElement then
    return nil
  end

  local axRole = Utils.getAttribute(rootElement, "AXRole")
  if axRole == role then
    return rootElement
  end

  local axChildren = Utils.getAttribute(rootElement, "AXChildren") or {}

  if type(axChildren) == "string" then
    return nil
  end

  for _, child in ipairs(axChildren) do
    local result = Elements.findAxRole(child, role)
    if result then
      return result
    end
  end

  return nil
end

---Checks if an editable control is in focus
---@return boolean
function Elements.isEditableControlInFocus()
  local focusedElement = Elements.getAxFocusedElement()
  if not focusedElement then
    return false
  end

  local role = Utils.getAttribute(focusedElement, "AXRole")
  return (role and Utils.tblContains(M.config.axEditableRoles, role)) or false
end

--------------------------------------------------------------------------------
-- Menu Bar
--------------------------------------------------------------------------------

---Creates the menu bar item
---@return nil
function MenuBar.create()
  if MenuBar.item then
    MenuBar.destroy()
  end
  MenuBar.item = hs.menubar.new()
  MenuBar.item:setTitle("N")
  log.df("Created menu bar item")
end

---Destroys the menu bar item
---@return nil
function MenuBar.destroy()
  if MenuBar.item then
    MenuBar.item:delete()
    MenuBar.item = nil
    log.df("Destroyed menu bar item")
  end
end

--------------------------------------------------------------------------------
-- Mode Management
--------------------------------------------------------------------------------

---Sets the mode
---@param mode number
---@param char string|nil
---@return nil
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
    hs.timer.doAfter(0, Marks.clear)
  end

  if mode == MODES.MULTI then
    State.multi = char
  else
    State.multi = nil
  end

  if MenuBar.item then
    local modeChar = char or defaultModeChars[mode] or "?"
    MenuBar.item:setTitle(modeChar)
  end

  log.df(string.format("Mode changed: %s -> %s", previousMode, mode))
end

--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------

---Performs a smooth scroll
---@param x number|nil
---@param y number|nil
---@param smooth boolean
---@return nil
function Actions.smoothScroll(x, y, smooth)
  if not smooth then
    hs.eventtap.event.newScrollEvent({ x or 0, y or 0 }, {}, "pixel"):post()
    return
  end

  local steps = 5
  local dx = x and (x / steps) or 0
  local dy = y and (y / steps) or 0
  local frame = 0
  local interval = 1 / M.config.smoothScrollFramerate

  local function animate()
    frame = frame + 1
    if frame > steps then
      return
    end

    local factor = frame <= steps / 2 and 2 or 0.5
    hs.eventtap.event.newScrollEvent({ dx * factor, dy * factor }, {}, "pixel"):post()
    hs.timer.doAfter(interval, animate)
  end

  animate()
end

---Opens a URL in a new tab
---@param url string
---@return nil
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
    Zen = 'tell application "Zen" to open location "%s"',
  }

  local currentApp = Elements.getApp()
  if not currentApp then
    return
  end

  local appName = currentApp:name()
  local script = browserScripts[appName] or browserScripts["Safari"]

  hs.osascript.applescript(string.format(script, url))
end

---Sets the clipboard contents
---@param contents string
---@return nil
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

---Force unfocus
---@return nil
function Actions.forceUnfocus()
  local focusedElement = Elements.getAxFocusedElement()
  if not focusedElement then
    return
  end

  focusedElement:setAttributeValue("AXFocused", false)

  hs.alert.show("Force unfocused!")
end

---Tries to click on a frame
---@param frame table
---@param type? string "left"|"right"
---@return nil
function Actions.tryClick(frame, type)
  type = type or "left"

  local clickX, clickY = frame.x + frame.w / 2, frame.y + frame.h / 2
  local originalPos = hs.mouse.absolutePosition()
  hs.mouse.absolutePosition({ x = clickX, y = clickY })
  if type == "left" then
    hs.eventtap.leftClick({ x = clickX, y = clickY })
  elseif type == "right" then
    hs.eventtap.rightClick({ x = clickX, y = clickY })
  end
  hs.timer.doAfter(0.1, function()
    hs.mouse.absolutePosition(originalPos)
  end)
end

--------------------------------------------------------------------------------
-- Element Finders
--------------------------------------------------------------------------------

---Finds clickable elements
---@param axApp Hs.Vimnav.Element
---@param withUrls boolean
---@param callback fun(elements: table)
---@return nil
function ElementFinder.findClickableElements(axApp, withUrls, callback)
  if type(axApp) == "string" then
    return
  end

  if not RoleMaps.jumpableSet then
    RoleMaps.init()
  end

  AsyncTraversal.traverseAsync(axApp, function(element)
    local role = Utils.getAttribute(element, "AXRole")

    if withUrls then
      local url = Utils.getAttribute(element, "AXURL")
      return url ~= nil
    end

    -- Role check
    if not role or type(role) ~= "string" or not RoleMaps.isJumpable(role) then
      return false
    end

    -- Skip obviously non-interactive elements quickly
    if RoleMaps.shouldSkip(role) then
      return false
    end

    return true
  end, callback, M.config.maxElements)
end

---Finds input elements
---@param axApp Hs.Vimnav.Element
---@param callback fun(elements: table)
---@return nil
function ElementFinder.findInputElements(axApp, callback)
  if type(axApp) == "string" then
    return
  end

  if not RoleMaps.editableSet then
    RoleMaps.init()
  end

  AsyncTraversal.traverseAsync(axApp, function(element)
    local role = Utils.getAttribute(element, "AXRole")
    return (role and type(role) == "string" and RoleMaps.isEditable(role)) or false
  end, function(results)
    -- Auto-click if single input found
    if #results == 1 then
      State.onClickCallback({ element = results[1], frame = Utils.getAttribute(results[1], "AXFrame") })
      ModeManager.setMode(MODES.NORMAL)
    else
      callback(results)
    end
  end, 10) -- Limit inputs to 10 max
end

---Finds image elements
---@param axApp Hs.Vimnav.Element
---@param callback fun(elements: table)
---@return nil
function ElementFinder.findImageElements(axApp, callback)
  if type(axApp) == "string" then
    return
  end

  AsyncTraversal.traverseAsync(axApp, function(element)
    local role = Utils.getAttribute(element, "AXRole")
    local url = Utils.getAttribute(element, "AXURL")
    return role == "AXImage" and url ~= nil
  end, callback, 100) -- Limit images
end

---Finds next button elemets
---@param axApp Hs.Vimnav.Element
---@param callback fun(elements: table)
---@return nil
function ElementFinder.findNextButtonElements(axApp, callback)
  if type(axApp) == "string" then
    return
  end

  AsyncTraversal.traverseAsync(axApp, function(element)
    local role = Utils.getAttribute(element, "AXRole")
    local title = Utils.getAttribute(element, "AXTitle")

    if (role == "AXLink" or role == "AXButton") and title and type(title) == "string" then
      return title:lower():find("next") ~= nil
    end
    return false
  end, callback, 5) -- Only need a few next buttons
end

---Finds previous button elemets
---@param axApp Hs.Vimnav.Element
---@param callback fun(elements: table)
---@return nil
function ElementFinder.findPrevButtonElements(axApp, callback)
  if type(axApp) == "string" then
    return
  end

  AsyncTraversal.traverseAsync(axApp, function(element)
    local role = Utils.getAttribute(element, "AXRole")
    local title = Utils.getAttribute(element, "AXTitle")

    if (role == "AXLink" or role == "AXButton") and title and type(title) == "string" then
      return title:lower():find("prev") ~= nil or title:lower():find("previous") ~= nil or false
    end
    return false
  end, callback, 5) -- Only need a few prev buttons
end

--------------------------------------------------------------------------------
-- Marks System
--------------------------------------------------------------------------------

---Clears the marks
---@return nil
function Marks.clear()
  if State.canvas then
    State.canvas:delete()
    State.canvas = nil
  end
  State.marks = {}
  State.linkCapture = ""
  MarkPool.releaseAll()
  log.df("Cleared marks")
end

---Adds a mark to the list
---@param element table
---@return nil
function Marks.add(element)
  if #State.marks >= M.config.maxElements then
    return
  end

  local frame = Utils.getAttribute(element, "AXFrame")
  if not frame or frame.w <= 2 or frame.h <= 2 then
    return
  end

  local mark = MarkPool.getMark()
  mark.element = element
  mark.frame = frame
  mark.role = Utils.getAttribute(element, "AXRole")

  State.marks[#State.marks + 1] = mark
end

---Show marks
---@param withUrls boolean
---@param elementType "link"|"input"|"image"
---@return nil
function Marks.show(withUrls, elementType)
  local axApp = Elements.getAxApp()
  if not axApp then
    return
  end

  Marks.clear()
  State.marks = {}
  MarkPool.releaseAll()

  if elementType == "link" then
    ElementFinder.findClickableElements(axApp, withUrls, function(elements)
      -- Convert to marks
      for i = 1, math.min(#elements, M.config.maxElements) do
        Marks.add(elements[i])
      end

      if #State.marks > 0 then
        Marks.draw()
      else
        hs.alert.show("No links found", nil, nil, 1)
        ModeManager.setMode(MODES.NORMAL)
      end
    end)
  elseif elementType == "input" then
    ElementFinder.findInputElements(axApp, function(elements)
      for i = 1, #elements do
        Marks.add(elements[i])
      end
      if #State.marks > 0 then
        Marks.draw()
      else
        hs.alert.show("No inputs found", nil, nil, 1)
        ModeManager.setMode(MODES.NORMAL)
      end
    end)
  elseif elementType == "image" then
    ElementFinder.findImageElements(axApp, function(elements)
      for i = 1, #elements do
        Marks.add(elements[i])
      end
      if #State.marks > 0 then
        Marks.draw()
      else
        hs.alert.show("No images found", nil, nil, 1)
        ModeManager.setMode(MODES.NORMAL)
      end
    end)
  end
end

---Draws the marks
---@return nil
function Marks.draw()
  if not State.canvas then
    local frame = Elements.getFullArea()
    if not frame then
      return
    end
    State.canvas = hs.canvas.new(frame)
  end

  local captureLen = #State.linkCapture
  local elementsToDraw = {}
  local template = CanvasCache.getMarkTemplate()

  local count = 0
  for i = 1, #State.marks do
    if count >= #State.allCombinations then
      break
    end

    local mark = State.marks[i]
    local markText = State.allCombinations[i]:upper()

    if captureLen == 0 or markText:sub(1, captureLen) == State.linkCapture then
      -- Clone template and update coordinates
      local bg = {}
      local text = {}

      for k, v in pairs(template.background) do
        bg[k] = v
      end
      for k, v in pairs(template.text) do
        text[k] = v
      end

      -- Quick coordinate calculation
      local frame = mark.frame
      if frame then
        local padding = 2
        local fontSize = 10
        local textWidth = #markText * (fontSize * 1.1)
        local textHeight = fontSize * 1.1
        local containerWidth = textWidth + (padding * 2)
        local containerHeight = textHeight + (padding * 2)

        local arrowHeight = 3
        local arrowWidth = 6
        local cornerRadius = 2

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

        bg.coordinates = {
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
        }
        text.text = markText
        text.frame = {
          x = rx,
          y = ry - (arrowHeight / 2) + ((rh - textHeight) / 2), -- Vertically center
          w = rw,
          h = textHeight,
        }

        elementsToDraw[#elementsToDraw + 1] = bg
        elementsToDraw[#elementsToDraw + 1] = text
        count = count + 1
      end
    end
  end

  State.canvas:replaceElements(elementsToDraw)
  State.canvas:show()
end

---Clicks a mark
---@param combination string
---@return nil
function Marks.click(combination)
  for i, c in ipairs(State.allCombinations) do
    if c == combination and State.marks[i] and State.onClickCallback then
      local success, err = pcall(State.onClickCallback, State.marks[i])
      if not success then
        log.ef("Error clicking element: " .. tostring(err))
      end
      break
    end
  end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

---Scrolls left
---@return nil
function Commands.cmdScrollLeft()
  Actions.smoothScroll(M.config.scrollStep, 0, M.config.smoothScroll)
end

---Scrolls right
---@return nil
function Commands.cmdScrollRight()
  Actions.smoothScroll(-M.config.scrollStep, 0, M.config.smoothScroll)
end

---Scrolls up
---@return nil
function Commands.cmdScrollUp()
  Actions.smoothScroll(0, M.config.scrollStep, M.config.smoothScroll)
end

---Scrolls down
---@return nil
function Commands.cmdScrollDown()
  Actions.smoothScroll(0, -M.config.scrollStep, M.config.smoothScroll)
end

---Scrolls half page down
---@return nil
function Commands.cmdScrollHalfPageDown()
  Actions.smoothScroll(0, -M.config.scrollStepHalfPage, M.config.smoothScroll)
end

---Scrolls half page up
---@return nil
function Commands.cmdScrollHalfPageUp()
  Actions.smoothScroll(0, M.config.scrollStepHalfPage, M.config.smoothScroll)
end

---Scrolls to top
---@return nil
function Commands.cmdScrollToTop()
  Actions.smoothScroll(0, M.config.scrollStepFullPage, M.config.smoothScroll)
end

---Scrolls to bottom
---@return nil
function Commands.cmdScrollToBottom()
  Actions.smoothScroll(0, -M.config.scrollStepFullPage, M.config.smoothScroll)
end

---Switches to insert mode
---@return nil
function Commands.cmdInsertMode()
  ModeManager.setMode(MODES.INSERT)
end

---Switches to links mode
---@return nil
function Commands.cmdGotoLink()
  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local element = mark.element

    local pressOk = element:performAction("AXPress")

    if not pressOk then
      local frame = mark.frame
      if frame then
        Actions.tryClick(frame)
      end
    end
  end
  hs.timer.doAfter(0, function()
    Marks.show(false, "link")
  end)
end

---Go to input mode
---@return nil
function Commands.cmdGotoInput()
  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local element = mark.element

    local pressOk = element:performAction("AXPress")

    if pressOk then
      local focused = Utils.getAttribute(element, "AXFocused")
      if not focused then
        Actions.tryClick(mark.frame)
        return
      end
    end

    Actions.tryClick(mark.frame)
  end
  hs.timer.doAfter(0, function()
    Marks.show(false, "input")
  end)
end

---Right click
---@return nil
function Commands.cmdRightClick()
  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local element = mark.element

    local pressOk = element:performAction("AXShowMenu")

    if not pressOk then
      local frame = mark.frame
      if frame then
        Actions.tryClick(frame, "right")
      end
    end
  end
  hs.timer.doAfter(0, function()
    Marks.show(false, "link")
  end)
end

---Go to link in new tab
---@return nil
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
  hs.timer.doAfter(0, function()
    Marks.show(true, "link")
  end)
end

---Download image
---@return nil
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
            ---@diagnostic disable-next-line: param-type-mismatch
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
  hs.timer.doAfter(0, function()
    Marks.show(false, "image")
  end)
end

---Move mouse to link
---@return nil
function Commands.cmdMoveMouseToLink()
  ModeManager.setMode(MODES.LINKS)
  State.onClickCallback = function(mark)
    local frame = mark.frame
    if frame then
      hs.mouse.absolutePosition({
        x = frame.x + frame.w / 2,
        y = frame.y + frame.h / 2,
      })
    end
  end
  hs.timer.doAfter(0, function()
    Marks.show(false, "link")
  end)
end

---Copy link URL to clipboard
---@return nil
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
  hs.timer.doAfter(0, function()
    Marks.show(true, "link")
  end)
end

---Next page
---@return nil
function Commands.cmdNextPage()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local axWindow = Elements.getAxWindow()
  if not axWindow then
    return
  end

  ElementFinder.findNextButtonElements(axWindow, function(elements)
    if #elements > 0 then
      elements[1]:performAction("AXPress")
    else
      hs.alert.show("No next button found", nil, nil, 2)
    end
  end)
end

---Prev page
---@return nil
function Commands.cmdPrevPage()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local axWindow = Elements.getAxWindow()
  if not axWindow then
    return
  end

  ElementFinder.findPrevButtonElements(axWindow, function(elements)
    if #elements > 0 then
      elements[1]:performAction("AXPress")
    else
      hs.alert.show("No previous button found", nil, nil, 2)
    end
  end)
end

---Copy page URL to clipboard
---@return nil
function Commands.cmdCopyPageUrlToClipboard()
  if not Utils.isInBrowser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local axWebArea = Elements.getAxWebArea()
  local url = axWebArea and Utils.getAttribute(axWebArea, "AXURL")
  if url then
    Actions.setClipboardContents(url.url)
  end
end

---Move mouse to center
---@return nil
function Commands.cmdMoveMouseToCenter()
  local window = Elements.getWindow()
  if not window then
    return
  end

  local frame = window:frame()
  hs.mouse.absolutePosition({
    x = frame.x + frame.w / 2,
    y = frame.y + frame.h / 2,
  })
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

---Handles Vim input
---@param char string
---@param modifiers table
---@return nil
local function handleVimInput(char, modifiers)
  log.df("handleVimInput: " .. char .. " modifiers: " .. hs.inspect(modifiers))

  if State.mode == MODES.LINKS then
    if char == "backspace" then
      if #State.linkCapture > 0 then
        State.linkCapture = State.linkCapture:sub(1, -2)
        Marks.draw()
      end
      return
    end

    State.linkCapture = State.linkCapture .. char:upper()

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
    end

    Marks.draw()
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
        log.wf("Unknown command: " .. mapping)
      end
    elseif type(mapping) == "table" then
      Utils.keyStroke(mapping[1], mapping[2])
    end
  elseif State.mappingPrefixes[keyCombo] then
    ModeManager.setMode(MODES.MULTI, keyCombo)
  end
end

---Handles events
---@param event table
---@return boolean
local function eventHandler(event)
  Utils.clearCache()

  if Utils.isExcludedApp() or Utils.isLauncherActive() then
    return false
  end

  local flags = event:getFlags()
  local keyCode = event:getKeyCode()
  local modifiers = { ctrl = flags.ctrl }

  -- Handle escape key
  if keyCode == hs.keycodes.map["escape"] then
    local delaySinceLastEscape = (hs.timer.absoluteTime() - State.lastEscape) / 1e9
    State.lastEscape = hs.timer.absoluteTime()

    if Utils.isInBrowser() and delaySinceLastEscape < M.config.doublePressDelay then
      Actions.forceUnfocus()
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
    hs.timer.doAfter(0, function()
      handleVimInput("backspace", { ctrl = flags.ctrl })
    end)
    return true
  end

  local char = hs.keycodes.map[keyCode]

  for key, modifier in pairs(flags) do
    if modifier and key ~= "shift" and key ~= "ctrl" then
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

  if modifiers and modifiers.ctrl then
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

  hs.timer.doAfter(0, function()
    handleVimInput(char, modifiers)
  end)

  return true
end

--------------------------------------------------------------------------------
-- Watchers
--------------------------------------------------------------------------------

---Clears all caches and state when switching apps
---@return nil
local function cleanupOnAppSwitch()
  -- Clear all element caches
  Utils.clearCache()

  -- Clear any active marks and canvas
  Marks.clear()

  -- Reset link capture state
  State.linkCapture = ""

  -- Force garbage collection to free up memory
  collectgarbage("collect")

  log.df("Cleaned up caches and state for app switch")
end

local appWatcher = nil

---Starts the app watcher
---@return nil
local function startAppWatcher()
  if appWatcher then
    appWatcher:stop()
    appWatcher = nil
  end

  appWatcher = hs.application.watcher.new(function(appName, eventType)
    log.df(string.format("App event: %s - %s", appName, eventType))

    if eventType == hs.application.watcher.activated then
      log.df(string.format("App activated: %s", appName))

      cleanupOnAppSwitch()

      if not State.eventLoop then
        State.eventLoop = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, eventHandler):start()
        log.df("Started event loop")
      end

      if Utils.tblContains(M.config.excludedApps, appName) then
        ModeManager.setMode(MODES.DISABLED)
        log.df("Disabled mode for excluded app: " .. appName)
      else
        ModeManager.setMode(MODES.NORMAL)
      end
    end
  end)

  appWatcher:start()

  log.df("App watcher started")
end

---Periodic cache cleanup to prevent memory leaks
---@return nil
local function setupPeriodicCleanup()
  if State.cleanupTimer then
    State.cleanupTimer:stop()
  end

  State.cleanupTimer = hs.timer
    .new(30, function() -- Every 30 seconds
      -- Only clean up if we're not actively showing marks
      if State.mode ~= MODES.LINKS then
        Utils.clearCache()
        collectgarbage("collect")
        log.df("Periodic cache cleanup completed")
      end
    end)
    :start()
end

---Clean up timers and watchers
---@return nil
local function cleanupWatchers()
  if appWatcher then
    appWatcher:stop()
    appWatcher = nil
    log.df("Stopped app watcher")
  end

  if State.cleanupTimer then
    State.cleanupTimer:stop()
    State.cleanupTimer = nil
    log.df("Stopped cleanup timer")
  end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@type Hs.Vimnav.Config
---@diagnostic disable-next-line: missing-fields
M.config = {}

---Starts the module
---@param userConfig Hs.Vimnav.Config
---@return nil
function M:start(userConfig)
  print("-- Starting Vimnav...")
  M.config = Utils.tblDeepExtend("force", DEFAULT_CONFIG, userConfig or {})

  log = hs.logger.new(M.name, M.config.logLevel)

  Utils.fetchMappingPrefixes()
  Utils.generateCombinations()
  RoleMaps.init() -- Initialize role maps for performance

  cleanupWatchers()
  startAppWatcher()
  setupPeriodicCleanup()
  MenuBar.create()

  local currentApp = Elements.getApp()
  if currentApp and Utils.tblContains(M.config.excludedApps, currentApp:name()) then
    ModeManager.setMode(MODES.DISABLED)
  else
    ModeManager.setMode(MODES.NORMAL)
  end
end

---Stops the module
---@return nil
function M:stop()
  print("-- Stopping Vimnav...")

  cleanupWatchers()

  if State.eventLoop then
    State.eventLoop:stop()
    State.eventLoop = nil
    log.df("Stopped event loop")
  end

  MenuBar.destroy()
  Marks.clear()

  cleanupOnAppSwitch()
end

return M
