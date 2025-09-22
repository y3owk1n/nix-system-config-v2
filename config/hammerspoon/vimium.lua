-- This module is originated and credits to `dzirtuss` at `https://github.com/dzirtusss/vifari`
-- I had made lots of modifications to the original code including performance and supporting for system wide instead
-- of just within Safari. In my opinion, there are too many changes that made it hard to contribute back to the original
-- project.

---@diagnostic disable: undefined-global

local _utils = require("utils")

local M = {}

local Utils = {}
local Elements = {}
local MenuBar = {}
local ModeManager = {}
local Actions = {}
local ElementFinder = {}
local Marks = {}
local Commands = {}
local State = {}

M.__index = M

local floor = math.floor
local insert = table.insert
local format = string.format
local sub = string.sub
local pcall = pcall
local timer = hs.timer
local mouse = hs.mouse
local eventtap = hs.eventtap
local axuielement = hs.axuielement
local watcher = hs.application.watcher

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

---@class Hs.Vimium.Config
---@field double_press_delay number
---@field show_logs boolean
---@field mapping table<string, string|table>
---@field scroll_step number
---@field scroll_step_half_page number
---@field smooth_scroll boolean
---@field smooth_scroll_framerate number
---@field depth number
---@field max_elements number
---@field chunk_size number
---@field ax_editable_roles string[]
---@field ax_jumpable_roles string[]
---@field ax_scrollable_roles string[]
---@field excluded_apps string[]
---@field browsers string[]
---@field launchers string[]

---@class Hs.Vimium.State
---@field mode number
---@field multi string|nil
---@field elements table<string, table>
---@field marks table<number, table<string, table>>
---@field link_capture string
---@field last_escape number
---@field mapping_prefixes table<string, boolean>
---@field all_combinations string[]
---@field event_loop table|nil
---@field canvas table|nil
---@field on_click_callback fun(any)|nil
---@field app_watcher table|nil

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
  ["i"] = "cmd_insert_mode",
  -- movements
  ["h"] = "cmd_scroll_left",
  ["j"] = "cmd_scroll_down",
  ["k"] = "cmd_scroll_up",
  ["l"] = "cmd_scroll_right",
  ["C-d"] = "cmd_scroll_half_page_down",
  ["C-u"] = "cmd_scroll_half_page_up",
  ["G"] = "cmd_scroll_to_bottom",
  ["gg"] = "cmd_scroll_to_top",
  ["H"] = { "cmd", "[" }, -- history back
  ["L"] = { "cmd", "]" }, -- history forward
  ["f"] = "cmd_goto_link",
  ["r"] = "cmd_right_click",
  ["F"] = "cmd_goto_link_new_tab",
  ["di"] = "cmd_download_image",
  ["gf"] = "cmd_move_mouse_to_link",
  ["gi"] = "cmd_goto_input",
  ["zz"] = "cmd_move_mouse_to_center",
  ["yy"] = "cmd_copy_page_url_to_clipboard",
  ["yf"] = "cmd_copy_link_url_to_clipboard",
  ["]]"] = "cmd_next_page",
  ["[["] = "cmd_prev_page",
}

local DEFAULT_CONFIG = {
  double_press_delay = 0.3,
  show_logs = false,
  mapping = DEFAULT_MAPPING,
  scroll_step = 50,
  scroll_step_half_page = 500,
  smooth_scroll = true,
  smooth_scroll_framerate = 120,
  depth = 100,
  max_elements = 676, -- 26*26 combinations
  chunk_size = 10, -- Process elements in chunks for better performance
  ax_editable_roles = { "AXTextField", "AXComboBox", "AXTextArea", "AXSearchField" },
  ax_jumpable_roles = {
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
  ax_scrollable_roles = {
    "AXScrollArea",
    -- "AXScrollView",
    -- "AXOverflow",
    "AXGroup", -- use AXGroup seems to be making the most sense to me
    -- "AXScrollable",
    -- "AXHorizontalScroll",
    -- "AXVerticalScroll",
    -- "AXWebArea",
  },
  excluded_apps = { "Terminal" },
  browsers = { "Safari", "Google Chrome", "Firefox", "Microsoft Edge", "Brave Browser" },
  launchers = { "Spotlight" },
}

--------------------------------------------------------------------------------
-- State Management
--------------------------------------------------------------------------------

---@type Hs.Vimium.State
State = {
  mode = MODES.DISABLED,
  multi = nil,
  elements = {},
  marks = {},
  link_capture = "",
  last_escape = timer.absoluteTime(),
  mapping_prefixes = {},
  all_combinations = {},
  event_loop = nil,
  canvas = nil,
  on_click_callback = nil,
  app_watcher = nil,
}

-- Element cache with weak references for garbage collection
local ElementCache = setmetatable({}, { __mode = "k" })

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

---Yields the current thread for 1µs
---@return nil
function Utils.yield()
  timer.usleep(1)
end

---Logs a message to the console
---@param message string
---@return nil
function Utils.log(message)
  if not M.config.show_logs then
    return
  end

  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local ms = floor(timer.absoluteTime() / 1e6) % 1000
  hs.printf("[%s.%03d] %s", timestamp, ms, message)
end

---Checks if a table contains a value
---@param tbl table
---@param val any
---@return boolean
function Utils.tbl_contains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

---Filters a table using a predicate
---@param tbl table
---@param predicate fun(val: any): boolean
---@return table
function Utils.tbl_filter(tbl, predicate)
  local result = {}
  for _, v in ipairs(tbl) do
    if predicate(v) then
      insert(result, v)
    end
  end
  return result
end

---Improved caching with validation
---@param key string
---@param factory fun(): table|nil
---@return table|nil
function Utils.get_cached_element(key, factory)
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

---Clears the element cache
---@return nil
function Utils.clear_cache()
  ElementCache = setmetatable({}, { __mode = "k" })
end

---Gets an attribute from an element
---@param element table
---@param attributeName string
---@return table|nil
function Utils.get_attribute(element, attributeName)
  if not element then
    return nil
  end

  local success, result = pcall(function()
    return element:attributeValue(attributeName)
  end)

  return success and result or nil
end

function Utils.is_element_valid(element)
  if not element then
    return false
  end

  local success = pcall(function()
    return element:isValid()
  end)

  return success
end

---Generates all combinations of letters
---@return nil
function Utils.generate_combinations()
  if #State.all_combinations > 0 then
    return
  end -- Already generated

  local chars = "abcdefghijklmnopqrstuvwxyz"
  for i = 1, #chars do
    for j = 1, #chars do
      insert(State.all_combinations, chars:sub(i, i) .. chars:sub(j, j))
      if #State.all_combinations >= M.config.max_elements then
        return
      end
    end
  end
end

---Fetches all mapping prefixes
---@return nil
function Utils.fetch_mapping_prefixes()
  State.mapping_prefixes = {}
  for k, _ in pairs(M.config.mapping) do
    if #k == 2 then
      State.mapping_prefixes[sub(k, 1, 1)] = true
    end
  end
end

---Checks if the current application is excluded
---@return boolean
function Utils.is_excluded_app()
  local app = hs.application.frontmostApplication()
  return app and Utils.tbl_contains(M.config.excluded_apps, app:name())
end

---Checks if the launcher is active
---@return boolean
---@return string|nil
function Utils.is_launcher_active()
  for _, launcher in ipairs(M.config.launchers) do
    local app = hs.application.get(launcher)
    if app then
      local appElement = axuielement.applicationElement(app)
      if appElement then
        local windows = Utils.get_attribute(appElement, "AXWindows") or {}
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
function Utils.is_in_browser()
  local app = hs.application.frontmostApplication()
  return app and Utils.tbl_contains(M.config.browsers, app:name())
end

--------------------------------------------------------------------------------
-- Element Access
--------------------------------------------------------------------------------

---Returns the application element
---@return table|nil
function Elements.get_app()
  return Utils.get_cached_element("app", function()
    return hs.application.frontmostApplication()
  end)
end

---Returns the application element for AXUIElement
---@return table|nil
function Elements.get_ax_app()
  return Utils.get_cached_element("axApp", function()
    local app = Elements.get_app()
    return app and axuielement.applicationElement(app)
  end)
end

---Returns the window element
---@return table|nil
function Elements.get_window()
  return Utils.get_cached_element("window", function()
    local app = Elements.get_app()
    return app and app:focusedWindow()
  end)
end

---Returns the window element for AXUIElement
---@return table|nil
function Elements.get_ax_window()
  return Utils.get_cached_element("axWindow", function()
    local window = Elements.get_window()
    return window and axuielement.windowElement(window)
  end)
end

---Returns the focused element for AXUIElement
---@return table|nil
function Elements.get_ax_focused_element()
  return Utils.get_cached_element("axFocusedElement", function()
    local axApp = Elements.get_ax_app()
    return axApp and Utils.get_attribute(axApp, "AXFocusedUIElement")
  end)
end

---Returns the web area element for AXUIElement
---@return table|nil
function Elements.get_ax_web_area()
  return Utils.get_cached_element("axWebArea", function()
    local axWindow = Elements.get_ax_window()
    return axWindow and Elements.find_ax_role(axWindow, "AXWebArea")
  end)
end

---Returns the menu bar element for AXUIElement
---@return table|nil
function Elements.get_ax_menu_bar()
  return Utils.get_cached_element("axMenuBar", function()
    local axApp = Elements.get_ax_app()
    return axApp and Utils.get_attribute(axApp, "AXMenuBar")
  end)
end

---Returns the full area element
---@return table|nil
function Elements.get_full_area()
  return Utils.get_cached_element("fullArea", function()
    local ax_win = Elements.get_ax_window()
    local ax_menu_bar = Elements.get_ax_menu_bar()

    if not ax_win or not ax_menu_bar then
      return nil
    end

    local winFrame = Utils.get_attribute(ax_win, "AXFrame") or {}
    local menuBarFrame = Utils.get_attribute(ax_menu_bar, "AXFrame") or {}

    return {
      x = 0,
      y = 0,
      w = menuBarFrame.w,
      h = winFrame.h + winFrame.y + menuBarFrame.h,
    }
  end)
end

---Finds an element with a specific AXRole
---@param rootElement table
---@param role string
---@return table|nil
function Elements.find_ax_role(rootElement, role)
  if not rootElement then
    return nil
  end

  local axRole = Utils.get_attribute(rootElement, "AXRole")
  if axRole == role then
    return rootElement
  end

  local axChildren = Utils.get_attribute(rootElement, "AXChildren") or {}
  for _, child in ipairs(axChildren) do
    local result = Elements.find_ax_role(child, role)
    if result then
      return result
    end
  end

  return nil
end

---Checks if an editable control is in focus
---@return boolean
function Elements.is_editable_control_in_focus()
  local focusedElement = Elements.get_ax_focused_element()
  if not focusedElement then
    return false
  end

  local role = Utils.get_attribute(focusedElement, "AXRole")
  return (role and Utils.tbl_contains(M.config.ax_editable_roles, role)) or false
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
end

---Destroys the menu bar item
---@return nil
function MenuBar.destroy()
  if MenuBar.item then
    MenuBar.item:delete()
    MenuBar.item = nil
  end
end

--------------------------------------------------------------------------------
-- Mode Management
--------------------------------------------------------------------------------

---Sets the mode
---@param mode number
---@param char string|nil
---@return nil
function ModeManager.set_mode(mode, char)
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
    State.link_capture = ""
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
-- Actions
--------------------------------------------------------------------------------

---Performs a smooth scroll
---@param x number|nil
---@param y number|nil
---@param smooth boolean
---@return nil
function Actions.smooth_scroll(x, y, smooth)
  if not smooth then
    eventtap.event.newScrollEvent({ x or 0, y or 0 }, {}, "pixel"):post()
    return
  end

  local steps = 5
  local dx = x and (x / steps) or 0
  local dy = y and (y / steps) or 0
  local frame = 0
  local interval = 1 / M.config.smooth_scroll_framerate

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

---Opens a URL in a new tab
---@param url string
---@return nil
function Actions.open_url_in_new_tab(url)
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

  local currentApp = Elements.get_app()
  if not currentApp then
    return
  end

  local appName = currentApp:name()
  local script = browserScripts[appName] or browserScripts["Safari"]

  hs.osascript.applescript(format(script, url))
end

---Sets the clipboard contents
---@param contents string
---@return nil
function Actions.set_clipboard_contents(contents)
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
-- Element Finding
--------------------------------------------------------------------------------

---Checks if an element is visible
---@param element table
---@return boolean
function ElementFinder.is_element_visible(element)
  if not element then
    return false
  end

  local hidden = Utils.get_attribute(element, "AXHidden")
  local frame = Utils.get_attribute(element, "AXFrame")

  if hidden or not frame or frame.w <= 0 or frame.h <= 0 then
    return false
  end

  -- Simplified visibility check
  return frame.x >= 0 and frame.y >= 0 and frame.x < 3000 and frame.y < 3000
end

---Checks if an element is actionable
---@param element table
---@return boolean
function ElementFinder.is_element_actionable(element)
  if not element then
    return false
  end

  local role = Utils.get_attribute(element, "AXRole")
  return (role and Utils.tbl_contains(M.config.ax_jumpable_roles, role)) or false
end

---Processes the children of an element
---@param element table
---@param callback fun(element: table, depth: number): boolean
---@param depth number
---@return nil
function ElementFinder.process_children(element, callback, depth)
  if not element or depth > M.config.depth then
    return
  end

  local children = Utils.get_attribute(element, "AXChildren") or {}
  local chunkSize = M.config.chunk_size

  -- Process in chunks to prevent blocking
  for i = 1, #children, chunkSize do
    local endIdx = math.min(i + chunkSize - 1, #children)

    for j = i, endIdx do
      if Utils.is_element_valid(children[j]) then
        callback(children[j], depth + 1)
      end
    end

    -- Yield control briefly for large element trees
    if i > chunkSize then
      Utils.yield()
    end
  end
end

---Finds elements with a predicate
---@param rootElement table
---@param predicate fun(element: table): boolean
---@param callback fun(element: table): nil
---@return nil
function ElementFinder.find_elements(rootElement, predicate, callback)
  if not rootElement then
    return
  end

  local function process_element(element, depth)
    if depth > M.config.depth then
      return
    end

    local role = Utils.get_attribute(element, "AXRole")
    if role ~= "AXApplication" and ElementFinder.is_element_visible(element) then
      if predicate(element) then
        callback(element)
      end
    end

    ElementFinder.process_children(element, process_element, depth)
  end

  process_element(rootElement, 0)
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
  State.link_capture = ""
end

---Adds a mark
---@param element table
---@return nil
function Marks.add(element)
  if #State.marks >= M.config.max_elements then
    return
  end
  insert(State.marks, { element = element })
end

---Shows the marks
---@param withUrls boolean
---@param elementType string
---@return nil
function Marks.show(withUrls, elementType)
  local axApp = Elements.get_ax_app()
  if not axApp then
    return
  end

  Marks.clear()

  local predicates = {
    link = function(el)
      return ElementFinder.is_element_actionable(el) and (not withUrls or Utils.get_attribute(el, "AXURL"))
    end,
    input = function(el)
      return Utils.tbl_contains(M.config.ax_editable_roles, Utils.get_attribute(el, "AXRole") or "")
    end,
    image = function(el)
      return Utils.get_attribute(el, "AXRole") == "AXImage" and Utils.get_attribute(el, "AXURL")
    end,
  }

  local predicate = predicates[elementType]
  if not predicate then
    return
  end

  ElementFinder.find_elements(axApp, predicate, Marks.add)

  if #State.marks == 0 then
    hs.alert.show("No " .. elementType .. "s found", nil, nil, 2)
    ModeManager.set_mode(MODES.NORMAL)
    return
  end

  -- Auto-click if only one input element
  if elementType == "input" and #State.marks == 1 then
    State.on_click_callback(State.marks[1])
    ModeManager.set_mode(MODES.NORMAL)
    return
  end

  Marks.draw()
end

---Draws the marks
---@return nil
function Marks.draw()
  if not State.canvas then
    local frame = Elements.get_full_area()
    if not frame then
      return
    end

    State.canvas = hs.canvas.new(frame)
  end

  local elementsToDraw = {}

  for i, mark in ipairs(State.marks) do
    if i > #State.all_combinations then
      break
    end

    local markText = State.all_combinations[i]:upper()

    if #State.link_capture == 0 or markText:sub(1, #State.link_capture) == State.link_capture then
      local element = Marks.create_mark_element(mark.element, markText)
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

---Creates a mark element
---@param element table
---@param text string
---@return table|nil
function Marks.create_mark_element(element, text)
  local frame = Utils.get_attribute(element, "AXFrame")
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

---Clicks a mark
---@param combination string
---@return nil
function Marks.click(combination)
  for i, c in ipairs(State.all_combinations) do
    if c == combination and State.marks[i] and State.on_click_callback then
      local success, err = pcall(State.on_click_callback, State.marks[i])
      if not success then
        Utils.log("Error clicking element: " .. tostring(err))
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
function Commands.cmd_scroll_left()
  Actions.smooth_scroll(M.config.scroll_step, 0, M.config.smooth_scroll)
end

---Scrolls right
---@return nil
function Commands.cmd_scroll_right()
  Actions.smooth_scroll(-M.config.scroll_step, 0, M.config.smooth_scroll)
end

---Scrolls up
---@return nil
function Commands.cmd_scroll_up()
  Actions.smooth_scroll(0, M.config.scroll_step, M.config.smooth_scroll)
end

---Scrolls down
---@return nil
function Commands.cmd_scroll_down()
  Actions.smooth_scroll(0, -M.config.scroll_step, M.config.smooth_scroll)
end

---Scrolls half page down
---@return nil
function Commands.cmd_scroll_half_page_down()
  Actions.smooth_scroll(0, -M.config.scroll_step_half_page, M.config.smooth_scroll)
end

---Scrolls half page up
---@return nil
function Commands.cmd_scroll_half_page_up()
  Actions.smooth_scroll(0, M.config.scroll_step_half_page, M.config.smooth_scroll)
end

---Scrolls to top
---@return nil
function Commands.cmd_scroll_to_top()
  eventtap.keyStroke({ "command" }, "up", 0)
end

---Scrolls to bottom
---@return nil
function Commands.cmd_scroll_to_bottom()
  eventtap.keyStroke({ "command" }, "down", 0)
end

---Switches to insert mode
---@return nil
function Commands.cmd_insert_mode()
  ModeManager.set_mode(MODES.INSERT)
end

---Switches to links mode
---@return nil
function Commands.cmd_goto_link()
  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local element = mark.element
    local actions = element and element:actionNames() or {}

    if Utils.tbl_contains(actions, "AXPress") then
      element:performAction("AXPress")
    else
      -- Fallback to mouse click
      local frame = Utils.get_attribute(element, "AXFrame")
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

---Go to input mode
---@return nil
function Commands.cmd_goto_input()
  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local element = mark.element
    local actions = element and element:actionNames() or {}

    if Utils.tbl_contains(actions, "AXPress") then
      element:performAction("AXPress")
    else
      -- Fallback to mouse click
      local frame = Utils.get_attribute(element, "AXFrame")
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
    Marks.show(false, "input")
  end)
end

---Right click
---@return nil
function Commands.cmd_right_click()
  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local element = mark.element
    local actions = element and element:actionNames() or {}

    if Utils.tbl_contains(actions, "AXShowMenu") then
      element:performAction("AXShowMenu")
    else
      local frame = Utils.get_attribute(element, "AXFrame")
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

---Go to link in new tab
---@return nil
function Commands.cmd_goto_link_new_tab()
  if not Utils.is_in_browser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local url = Utils.get_attribute(mark.element, "AXURL")
    if url then
      Actions.open_url_in_new_tab(url.url)
    end
  end
  timer.doAfter(0, function()
    Marks.show(true, "link")
  end)
end

---Download image
---@return nil
function Commands.cmd_download_image()
  if not Utils.is_in_browser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local element = mark.element
    local role = Utils.get_attribute(element, "AXRole")

    if role == "AXImage" then
      local description = Utils.get_attribute(element, "AXDescription") or "image"

      local downloadUrlAttr = Utils.get_attribute(element, "AXURL")

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
  timer.doAfter(0, function()
    Marks.show(false, "image")
  end)
end

---Move mouse to link
---@return nil
function Commands.cmd_move_mouse_to_link()
  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local frame = Utils.get_attribute(mark.element, "AXFrame")
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

---Copy link URL to clipboard
---@return nil
function Commands.cmd_copy_link_url_to_clipboard()
  if not Utils.is_in_browser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local url = Utils.get_attribute(mark.element, "AXURL")
    if url then
      Actions.set_clipboard_contents(url.url)
    else
      hs.alert.show("No URL found", nil, nil, 2)
    end
  end
  timer.doAfter(0, function()
    Marks.show(true, "link")
  end)
end

---Next page
---@return nil
function Commands.cmd_next_page()
  if not Utils.is_in_browser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local function findNextButton(element, depth)
    if not element or depth > M.config.depth then
      return false
    end

    local role = Utils.get_attribute(element, "AXRole")
    local title = Utils.get_attribute(element, "AXTitle")

    if (role == "AXLink" or role == "AXButton") and title then
      if title:lower():find("next") then
        element:performAction("AXPress")
        return true
      end
    end

    local children = Utils.get_attribute(element, "AXChildren") or {}
    for _, child in ipairs(children) do
      if findNextButton(child, depth + 1) then
        return true
      end
    end

    return false
  end

  local axWindow = Elements.get_ax_window()
  if axWindow then
    if not findNextButton(axWindow, 0) then
      hs.alert.show("No Next button found", nil, nil, 2)
    end
  end
end

---Prev page
---@return nil
function Commands.cmd_prev_page()
  if not Utils.is_in_browser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local function findPrevButton(element, depth)
    if not element or depth > M.config.depth then
      return false
    end

    local role = Utils.get_attribute(element, "AXRole")
    local title = Utils.get_attribute(element, "AXTitle")

    if (role == "AXLink" or role == "AXButton") and title then
      if title:lower():find("prev") or title:lower():find("previous") then
        element:performAction("AXPress")
        return true
      end
    end

    local children = Utils.get_attribute(element, "AXChildren") or {}
    for _, child in ipairs(children) do
      if findPrevButton(child, depth + 1) then
        return true
      end
    end

    return false
  end

  local axWindow = Elements.get_ax_window()
  if axWindow then
    if not findPrevButton(axWindow, 0) then
      hs.alert.show("No Previous button found", nil, nil, 2)
    end
  end
end

---Copy page URL to clipboard
---@return nil
function Commands.cmd_copy_page_url_to_clipboard()
  if not Utils.is_in_browser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local webArea = Elements.get_ax_web_area()
  local url = webArea and Utils.get_attribute(webArea, "AXURL")
  if url then
    Actions.set_clipboard_contents(url.url)
  end
end

---Move mouse to center
---@return nil
function Commands.cmd_move_mouse_to_center()
  local window = Elements.get_window()
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
-- Event Handling
--------------------------------------------------------------------------------

---Handles Vim input
---@param char string
---@param modifiers table
---@return nil
local function handle_vim_input(char, modifiers)
  Utils.log("handleVimInput: " .. char .. " modifiers: " .. hs.inspect(modifiers))

  if State.mode == MODES.LINKS then
    if char == "backspace" then
      if #State.link_capture > 0 then
        State.link_capture = State.link_capture:sub(1, -2)
        Marks.draw()
      end
      return
    end

    State.link_capture = State.link_capture .. char:upper()
    Marks.draw()

    -- Check for exact match
    for i, _ in ipairs(State.marks) do
      if i > #State.all_combinations then
        break
      end

      local markText = State.all_combinations[i]:upper()
      if markText == State.link_capture then
        Marks.click(markText:lower())
        ModeManager.set_mode(MODES.NORMAL)
        return
      end
    end

    -- Check for partial matches
    local hasPartialMatches = false
    for i, _ in ipairs(State.marks) do
      if i > #State.all_combinations then
        break
      end

      local markText = State.all_combinations[i]:upper()
      if markText:sub(1, #State.link_capture) == State.link_capture then
        hasPartialMatches = true
        break
      end
    end

    if not hasPartialMatches then
      State.link_capture = ""
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
    ModeManager.set_mode(MODES.NORMAL)

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
  elseif State.mapping_prefixes[keyCombo] then
    ModeManager.set_mode(MODES.MULTI, keyCombo)
  end
end

---Handles events
---@param event table
---@return boolean
local function event_handler(event)
  Utils.clear_cache()

  if Utils.is_excluded_app() or Utils.is_launcher_active() then
    return false
  end

  local flags = event:getFlags()
  local keyCode = event:getKeyCode()
  local modifiers = { ctrl = flags.ctrl }

  -- Handle escape key
  if keyCode == hs.keycodes.map["escape"] then
    local delaySinceLastEscape = (timer.absoluteTime() - State.last_escape) / 1e9
    State.last_escape = timer.absoluteTime()

    if Utils.is_in_browser() and delaySinceLastEscape < M.config.double_press_delay then
      ModeManager.set_mode(MODES.NORMAL)
      return true
    end

    if State.mode ~= MODES.NORMAL then
      ModeManager.set_mode(MODES.NORMAL)
      return true
    end

    return false
  end

  -- Skip if in insert mode or editable control has focus
  if State.mode == MODES.INSERT or Elements.is_editable_control_in_focus() then
    return false
  end

  -- Handle backspace in LINKS mode
  if State.mode == MODES.LINKS and keyCode == hs.keycodes.map["delete"] then
    timer.doAfter(0, function()
      handle_vim_input("backspace", { ctrl = flags.ctrl })
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
    local filtered_mappings = {}

    for _key, _ in pairs(M.config.mapping) do
      if _key:sub(1, 2) == "C-" then
        table.insert(filtered_mappings, _key:sub(3))
      end
    end

    if Utils.tbl_contains(filtered_mappings, char) == false then
      return false
    end
  end

  timer.doAfter(0, function()
    handle_vim_input(char, modifiers)
  end)

  return true
end

--------------------------------------------------------------------------------
-- App Watcher
--------------------------------------------------------------------------------

---Starts the app watcher
---@return nil
local function start_watcher()
  if State.app_watcher then
    State.app_watcher:stop()
  end

  State.app_watcher = watcher.new(function(appName, event_type, appObject)
    if event_type == watcher.activated then
      if not State.event_loop then
        State.event_loop = eventtap.new({ eventtap.event.types.keyDown }, event_handler):start()
      end

      if Utils.tbl_contains(M.config.excluded_apps, appName) then
        ModeManager.set_mode(MODES.DISABLED)
      else
        ModeManager.set_mode(MODES.NORMAL)
      end
    end
  end)

  State.app_watcher:start()
  Utils.log("App watcher started")
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@type Hs.Vimium.Config
---@diagnostic disable-next-line: missing-fields
M.config = {}

---Sets up the module
---@param userConfig Hs.Vimium.Config
---@return nil
function M.setup(userConfig)
  M.config = _utils.tbl_deep_extend("force", DEFAULT_CONFIG, userConfig or {})

  Utils.fetch_mapping_prefixes()
  Utils.generate_combinations()

  M:start()
end

---Starts the module
---@return nil
function M:start()
  start_watcher()
  MenuBar.create()
  ModeManager.set_mode(MODES.NORMAL)

  Utils.log("Vim navigation started")
end

---Stops the module
---@return nil
function M:stop()
  if State.app_watcher then
    State.app_watcher:stop()
    State.app_watcher = nil
  end

  if State.event_loop then
    State.event_loop:stop()
    State.event_loop = nil
  end

  MenuBar.destroy()
  Marks.clear()

  Utils.log("Vim navigation stopped")
end

-- Expose useful functions for debugging
M.debug = {
  get_state = function()
    return State
  end,
  get_elements = function()
    return Elements
  end,
  clear_cache = Utils.clear_cache,
  log = Utils.log,
}

return M
