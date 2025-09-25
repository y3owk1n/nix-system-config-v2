-- This module is originated and credits to `dzirtuss` at `https://github.com/dzirtusss/vifari`
-- I had made lots of modifications to the original code including performance and supporting for system wide instead
-- of just within Safari. In my opinion, there are too many changes that made it hard to contribute back to the original
-- project.

---@diagnostic disable: undefined-global

local _utils = require("utils")

---@class Hs.Vimium
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
local SpatialIndex = {}
local AsyncTraversal = {}
local RoleMaps = {}
local MarkPool = {}
local CanvasCache = {}

M.__index = M

M.mod_name = "vimium"

local log

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

---@class Hs.Vimium.Config
---@field log_level string
---@field double_press_delay number
---@field mapping table<string, string|table>
---@field scroll_step number
---@field scroll_step_half_page number
---@field scroll_step_full_page number
---@field smooth_scroll boolean
---@field smooth_scroll_framerate number
---@field depth number
---@field max_elements number
---@field ax_editable_roles string[]
---@field ax_jumpable_roles string[]
---@field excluded_apps string[]
---@field browsers string[]
---@field launchers string[]

---@class Hs.Vimium.State
---@field mode number
---@field multi string|nil
---@field elements table<string, table>
---@field marks table<number, table<string, table|nil>>
---@field link_capture string
---@field last_escape number
---@field mapping_prefixes table<string, boolean>
---@field all_combinations string[]
---@field event_loop table|nil
---@field canvas table|nil
---@field on_click_callback fun(any)|nil
---@field cleanup_timer table|nil

---@alias Hs.Vimium.Element table|string

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
  log_level = "warning",
  double_press_delay = 0.3,
  mapping = DEFAULT_MAPPING,
  scroll_step = 50,
  scroll_step_half_page = 500,
  scroll_step_full_page = 1e6,
  smooth_scroll = true,
  smooth_scroll_framerate = 120,
  depth = 20,
  max_elements = 676, -- 26*26 combinations
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
  excluded_apps = { "Terminal" },
  browsers = { "Safari", "Google Chrome", "Firefox", "Microsoft Edge", "Brave Browser", "Zen" },
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
  last_escape = hs.timer.absoluteTime(),
  mapping_prefixes = {},
  all_combinations = {},
  event_loop = nil,
  canvas = nil,
  on_click_callback = nil,
  cleanup_timer = nil,
}

-- Element cache with weak references for garbage collection
local element_cache = setmetatable({}, { __mode = "k" })

local attribute_cache = setmetatable({}, { __mode = "k" })

--------------------------------------------------------------------------------
-- Spatial Indexing
--------------------------------------------------------------------------------

---Quad-tree like spatial indexing for viewport culling
---@return table|nil
function SpatialIndex.create_viewport_regions()
  local fullArea = Elements.get_full_area()
  if not fullArea then
    return nil
  end

  return {
    x = fullArea.x,
    y = fullArea.y,
    w = fullArea.w,
    h = fullArea.h,
    center_x = fullArea.x + fullArea.w / 2,
    center_y = fullArea.y + fullArea.h / 2,
  }
end

---Checks if the element is in the viewport
---@param fx number
---@param fy number
---@param fw number
---@param fh number
---@param viewport table
---@return boolean
function SpatialIndex.is_in_viewport(fx, fy, fw, fh, viewport)
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
---@param max_results number
---@return nil
function AsyncTraversal.traverse_async(element, matcher, callback, max_results)
  local results = {}
  local viewport = SpatialIndex.create_viewport_regions()

  if not viewport then
    callback({})
    return
  end

  local traverse_coroutine = coroutine.create(function()
    AsyncTraversal.walk_element(element, 0, matcher, function(el)
      results[#results + 1] = el
      return #results >= max_results
    end, viewport)
  end)

  -- Resume coroutine in chunks
  local function resume_work()
    if coroutine.status(traverse_coroutine) == "dead" then
      callback(results)
      return
    end

    local success, should_stop = coroutine.resume(traverse_coroutine)
    if success and not should_stop then
      hs.timer.doAfter(0.001, resume_work) -- 1ms pause
    else
      callback(results)
    end
  end

  resume_work()
end

---Walks an element with a matcher
---@param element table
---@param depth number
---@param matcher fun(element: table): boolean
---@param callback fun(element: table): boolean
---@param viewport table
---@return boolean|nil
function AsyncTraversal.walk_element(element, depth, matcher, callback, viewport)
  if depth > M.config.depth then
    return
  end -- Hard depth limit

  local batch_size = 0
  local function process_element(el)
    batch_size = batch_size + 1

    -- Batch yield every 30 elements to stay responsive
    if batch_size % 30 == 0 then
      coroutine.yield(false) -- Don't stop, just yield
    end

    -- Get frame once, reuse everywhere
    local frame = Utils.get_attribute(el, "AXFrame")
    if not frame then
      return
    end

    -- Viewport check
    if not SpatialIndex.is_in_viewport(frame.x, frame.y, frame.w, frame.h, viewport) then
      return
    end

    -- Test element
    if matcher(el) then
      if callback(el) then -- callback returns true to stop
        return true
      end
    end

    -- Process children
    local children = Utils.get_attribute(el, "AXVisibleChildren") or Utils.get_attribute(el, "AXChildren") or {}

    for i = 1, #children do
      if AsyncTraversal.walk_element(children[i], depth + 1, matcher, callback, viewport) then
        return true
      end
    end
  end

  local role = Utils.get_attribute(element, "AXRole")
  if role == "AXApplication" then
    local children = Utils.get_attribute(element, "AXChildren") or {}
    for i = 1, #children do
      if process_element(children[i]) then
        return true
      end
    end
  else
    return process_element(element)
  end
end

--------------------------------------------------------------------------------
-- Pre-computed Role Maps and Lookup Tables
--------------------------------------------------------------------------------

---Pre-compute role sets as hash maps for O(1) lookup
---@return nil
function RoleMaps.init()
  RoleMaps.jumpable_set = {}
  for _, role in ipairs(M.config.ax_jumpable_roles) do
    RoleMaps.jumpable_set[role] = true
  end

  RoleMaps.editable_set = {}
  for _, role in ipairs(M.config.ax_editable_roles) do
    RoleMaps.editable_set[role] = true
  end

  RoleMaps.skip_set = {
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
function RoleMaps.is_jumpable(role)
  return RoleMaps.jumpable_set and RoleMaps.jumpable_set[role] == true
end

---Checks if the role is editable
---@param role string
---@return boolean
function RoleMaps.is_editable(role)
  return RoleMaps.editable_set and RoleMaps.editable_set[role] == true
end

---Checks if the role should be skipped
---@param role string
---@return boolean
function RoleMaps.should_skip(role)
  return RoleMaps.skip_set and RoleMaps.skip_set[role] == true
end

--------------------------------------------------------------------------------
-- Memory Pool for Mark Elements
--------------------------------------------------------------------------------

MarkPool.pool = {}
MarkPool.active = {}

---Reuse mark objects to avoid GC pressure
---@return table
function MarkPool.get_mark()
  local mark = table.remove(MarkPool.pool)
  if not mark then
    mark = { element = nil, frame = nil, role = nil }
  end
  MarkPool.active[#MarkPool.active + 1] = mark
  return mark
end

---Release all marks
---@return nil
function MarkPool.release_all()
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
function CanvasCache.get_mark_template()
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

---Gets an element from the cache
---@param key string
---@param factory fun(): Hs.Vimium.Element|nil
---@return Hs.Vimium.Element|nil
function Utils.get_cached_element(key, factory)
  if
    element_cache[key]
    and pcall(function()
      return element_cache[key]:isValid()
    end)
    and element_cache[key]:isValid()
  then
    return element_cache[key]
  end

  local element = factory()
  if element then
    element_cache[key] = element
  end
  return element
end

---Clears the element cache
---@return nil
function Utils.clear_cache()
  element_cache = setmetatable({}, { __mode = "k" })
  attribute_cache = setmetatable({}, { __mode = "k" })
end

---Gets an attribute from an element
---@param element Hs.Vimium.Element
---@param attribute_name string
---@return Hs.Vimium.Element|nil
function Utils.get_attribute(element, attribute_name)
  if not element then
    return nil
  end

  local cache_key = tostring(element) .. ":" .. attribute_name
  local cached = attribute_cache[cache_key]

  if cached ~= nil then
    return cached == "NIL_VALUE" and nil or cached
  end

  local success, result = pcall(function()
    return element:attributeValue(attribute_name)
  end)

  result = success and result or nil

  -- Store nil as a special marker to distinguish from uncached
  attribute_cache[cache_key] = result == nil and "NIL_VALUE" or result
  return result
end

---Generates all combinations of letters
---@return nil
function Utils.generate_combinations()
  if #State.all_combinations > 0 then
    log.df("Already generated combinations")
    return
  end -- Already generated

  local chars = "abcdefghijklmnopqrstuvwxyz"
  for i = 1, #chars do
    for j = 1, #chars do
      table.insert(State.all_combinations, chars:sub(i, i) .. chars:sub(j, j))
      if #State.all_combinations >= M.config.max_elements then
        return
      end
    end
  end
  log.df("Generated " .. #State.all_combinations .. " combinations")
end

---Fetches all mapping prefixes
---@return nil
function Utils.fetch_mapping_prefixes()
  State.mapping_prefixes = {}
  for k, _ in pairs(M.config.mapping) do
    if #k == 2 then
      State.mapping_prefixes[string.sub(k, 1, 1)] = true
    end
  end
  log.df("Fetched mapping prefixes")
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
      local appElement = hs.axuielement.applicationElement(app)
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
---@return Hs.Vimium.Element|nil
function Elements.get_app()
  return Utils.get_cached_element("app", function()
    return hs.application.frontmostApplication()
  end)
end

---Returns the application element for AXUIElement
---@return Hs.Vimium.Element|nil
function Elements.get_ax_app()
  return Utils.get_cached_element("axApp", function()
    local app = Elements.get_app()
    return app and hs.axuielement.applicationElement(app)
  end)
end

---Returns the window element
---@return Hs.Vimium.Element|nil
function Elements.get_window()
  return Utils.get_cached_element("window", function()
    local app = Elements.get_app()
    return app and app:focusedWindow()
  end)
end

---Returns the window element for AXUIElement
---@return Hs.Vimium.Element|nil
function Elements.get_ax_window()
  return Utils.get_cached_element("axWindow", function()
    local window = Elements.get_window()
    return window and hs.axuielement.windowElement(window)
  end)
end

---Returns the focused element for AXUIElement
---@return Hs.Vimium.Element|nil
function Elements.get_ax_focused_element()
  return Utils.get_cached_element("axFocusedElement", function()
    local ax_app = Elements.get_ax_app()
    return ax_app and Utils.get_attribute(ax_app, "AXFocusedUIElement")
  end)
end

---Returns the web area element for AXUIElement
---@return Hs.Vimium.Element|nil
function Elements.get_ax_web_area()
  return Utils.get_cached_element("axWebArea", function()
    local ax_window = Elements.get_ax_window()
    return ax_window and Elements.find_ax_role(ax_window, "AXWebArea")
  end)
end

---Returns the menu bar element for AXUIElement
---@return Hs.Vimium.Element|nil
function Elements.get_ax_menu_bar()
  return Utils.get_cached_element("axMenuBar", function()
    local ax_app = Elements.get_ax_app()
    return ax_app and Utils.get_attribute(ax_app, "AXMenuBar")
  end)
end

---Returns the full area element
---@return Hs.Vimium.Element|nil
function Elements.get_full_area()
  return Utils.get_cached_element("fullArea", function()
    local ax_win = Elements.get_ax_window()
    local ax_menu_bar = Elements.get_ax_menu_bar()

    if not ax_win or not ax_menu_bar then
      return nil
    end

    local win_frame = Utils.get_attribute(ax_win, "AXFrame") or {}
    local menu_bar_frame = Utils.get_attribute(ax_menu_bar, "AXFrame") or {}

    return {
      x = 0,
      y = 0,
      w = menu_bar_frame.w,
      h = win_frame.h + win_frame.y + menu_bar_frame.h,
    }
  end)
end

---Finds an element with a specific AXRole
---@param root_element Hs.Vimium.Element
---@param role string
---@return Hs.Vimium.Element|nil
function Elements.find_ax_role(root_element, role)
  if not root_element then
    return nil
  end

  local axRole = Utils.get_attribute(root_element, "AXRole")
  if axRole == role then
    return root_element
  end

  local axChildren = Utils.get_attribute(root_element, "AXChildren") or {}

  if type(axChildren) == "string" then
    return nil
  end

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
  local focused_element = Elements.get_ax_focused_element()
  if not focused_element then
    return false
  end

  local role = Utils.get_attribute(focused_element, "AXRole")
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
function ModeManager.set_mode(mode, char)
  local default_mode_chars = {
    [MODES.DISABLED] = "X",
    [MODES.INSERT] = "I",
    [MODES.LINKS] = "L",
    [MODES.MULTI] = "M",
    [MODES.NORMAL] = "N",
  }

  local previous_mode = State.mode
  State.mode = mode

  if mode == MODES.LINKS and previous_mode ~= MODES.LINKS then
    State.link_capture = ""
    Marks.clear()
  elseif previous_mode == MODES.LINKS and mode ~= MODES.LINKS then
    hs.timer.doAfter(0, Marks.clear)
  end

  if mode == MODES.MULTI then
    State.multi = char
  else
    State.multi = nil
  end

  if MenuBar.item then
    local mode_char = char or default_mode_chars[mode] or "?"
    MenuBar.item:setTitle(mode_char)
  end

  log.df(string.format("Mode changed: %s -> %s", previous_mode, mode))
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
    hs.eventtap.event.newScrollEvent({ x or 0, y or 0 }, {}, "pixel"):post()
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
    hs.eventtap.event.newScrollEvent({ dx * factor, dy * factor }, {}, "pixel"):post()
    hs.timer.doAfter(interval, animate)
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

  local browser_scripts = {
    Safari = 'tell application "Safari" to tell window 1 to set current tab to (make new tab with properties {URL:"%s"})',
    ["Google Chrome"] = 'tell application "Google Chrome" to tell window 1 to make new tab with properties {URL:"%s"}',
    Firefox = 'tell application "Firefox" to tell window 1 to open location "%s"',
    ["Microsoft Edge"] = 'tell application "Microsoft Edge" to tell window 1 to make new tab with properties {URL:"%s"}',
    ["Brave Browser"] = 'tell application "Brave Browser" to tell window 1 to make new tab with properties {URL:"%s"}',
    Zen = 'tell application "Zen" to open location "%s"',
  }

  local current_app = Elements.get_app()
  if not current_app then
    return
  end

  local appName = current_app:name()
  local script = browser_scripts[appName] or browser_scripts["Safari"]

  hs.osascript.applescript(string.format(script, url))
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

---Force unfocus
---@return nil
function Actions.force_unfocus()
  local focused_element = Elements.get_ax_focused_element()
  if not focused_element then
    return
  end

  focused_element:setAttributeValue("AXFocused", false)

  hs.alert.show("Force unfocused!")
end

---Tries to click on a frame
---@param frame table
---@param type? string "left"|"right"
---@return nil
function Actions.try_click(frame, type)
  type = type or "left"

  local click_x, click_y = frame.x + frame.w / 2, frame.y + frame.h / 2
  local original_pos = hs.mouse.absolutePosition()
  hs.mouse.absolutePosition({ x = click_x, y = click_y })
  if type == "left" then
    hs.eventtap.leftClick({ x = click_x, y = click_y })
  elseif type == "right" then
    hs.eventtap.rightClick({ x = click_x, y = click_y })
  end
  hs.timer.doAfter(0.1, function()
    hs.mouse.absolutePosition(original_pos)
  end)
end

--------------------------------------------------------------------------------
-- Element Finders
--------------------------------------------------------------------------------

---Finds clickable elements
---@param ax_app Hs.Vimium.Element
---@param with_urls boolean
---@param callback fun(elements: table)
---@return nil
function ElementFinder.find_clickable_elements(ax_app, with_urls, callback)
  if type(ax_app) == "string" then
    return
  end

  if not RoleMaps.jumpable_set then
    RoleMaps.init()
  end

  AsyncTraversal.traverse_async(ax_app, function(element)
    local role = Utils.get_attribute(element, "AXRole")

    if with_urls then
      local url = Utils.get_attribute(element, "AXURL")
      return url ~= nil
    end

    -- Role check
    if not role or type(role) ~= "string" or not RoleMaps.is_jumpable(role) then
      return false
    end

    -- Skip obviously non-interactive elements quickly
    if RoleMaps.should_skip(role) then
      return false
    end

    return true
  end, callback, M.config.max_elements)
end

---Finds input elements
---@param ax_app Hs.Vimium.Element
---@param callback fun(elements: table)
---@return nil
function ElementFinder.find_input_elements(ax_app, callback)
  if type(ax_app) == "string" then
    return
  end

  if not RoleMaps.editable_set then
    RoleMaps.init()
  end

  AsyncTraversal.traverse_async(ax_app, function(element)
    local role = Utils.get_attribute(element, "AXRole")
    return (role and type(role) == "string" and RoleMaps.is_editable(role)) or false
  end, function(results)
    -- Auto-click if single input found
    if #results == 1 then
      State.on_click_callback({ element = results[1], frame = Utils.get_attribute(results[1], "AXFrame") })
      ModeManager.set_mode(MODES.NORMAL)
    else
      callback(results)
    end
  end, 10) -- Limit inputs to 10 max
end

---Finds image elements
---@param ax_app Hs.Vimium.Element
---@param callback fun(elements: table)
---@return nil
function ElementFinder.find_image_elements(ax_app, callback)
  if type(ax_app) == "string" then
    return
  end

  AsyncTraversal.traverse_async(ax_app, function(element)
    local role = Utils.get_attribute(element, "AXRole")
    local url = Utils.get_attribute(element, "AXURL")
    return role == "AXImage" and url ~= nil
  end, callback, 100) -- Limit images
end

---Finds next button elemets
---@param ax_app Hs.Vimium.Element
---@param callback fun(elements: table)
---@return nil
function ElementFinder.find_next_button_elements(ax_app, callback)
  if type(ax_app) == "string" then
    return
  end

  AsyncTraversal.traverse_async(ax_app, function(element)
    local role = Utils.get_attribute(element, "AXRole")
    local title = Utils.get_attribute(element, "AXTitle")

    if (role == "AXLink" or role == "AXButton") and title and type(title) == "string" then
      return title:lower():find("next") ~= nil
    end
    return false
  end, callback, 5) -- Only need a few next buttons
end

---Finds previous button elemets
---@param ax_app Hs.Vimium.Element
---@param callback fun(elements: table)
---@return nil
function ElementFinder.find_prev_button_elements(ax_app, callback)
  if type(ax_app) == "string" then
    return
  end

  AsyncTraversal.traverse_async(ax_app, function(element)
    local role = Utils.get_attribute(element, "AXRole")
    local title = Utils.get_attribute(element, "AXTitle")

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
  State.link_capture = ""
  MarkPool.release_all()
  log.df("Cleared marks")
end

---Adds a mark to the list
---@param element table
---@return nil
function Marks.add(element)
  if #State.marks >= M.config.max_elements then
    return
  end

  local frame = Utils.get_attribute(element, "AXFrame")
  if not frame or frame.w <= 2 or frame.h <= 2 then
    return
  end

  local mark = MarkPool.get_mark()
  mark.element = element
  mark.frame = frame
  mark.role = Utils.get_attribute(element, "AXRole")

  State.marks[#State.marks + 1] = mark
end

---Show marks
---@param with_urls boolean
---@param element_type "link"|"input"|"image"
---@return nil
function Marks.show(with_urls, element_type)
  local ax_app = Elements.get_ax_app()
  if not ax_app then
    return
  end

  Marks.clear()
  State.marks = {}
  MarkPool.release_all()

  if element_type == "link" then
    ElementFinder.find_clickable_elements(ax_app, with_urls, function(elements)
      -- Convert to marks
      for i = 1, math.min(#elements, M.config.max_elements) do
        Marks.add(elements[i])
      end

      if #State.marks > 0 then
        Marks.draw()
      else
        hs.alert.show("No links found", nil, nil, 1)
        ModeManager.set_mode(MODES.NORMAL)
      end
    end)
  elseif element_type == "input" then
    ElementFinder.find_input_elements(ax_app, function(elements)
      for i = 1, #elements do
        Marks.add(elements[i])
      end
      if #State.marks > 0 then
        Marks.draw()
      else
        hs.alert.show("No inputs found", nil, nil, 1)
        ModeManager.set_mode(MODES.NORMAL)
      end
    end)
  elseif element_type == "image" then
    ElementFinder.find_image_elements(ax_app, function(elements)
      for i = 1, #elements do
        Marks.add(elements[i])
      end
      if #State.marks > 0 then
        Marks.draw()
      else
        hs.alert.show("No images found", nil, nil, 1)
        ModeManager.set_mode(MODES.NORMAL)
      end
    end)
  end
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

  local capture_len = #State.link_capture
  local elements_to_draw = {}
  local template = CanvasCache.get_mark_template()

  local count = 0
  for i = 1, #State.marks do
    if count >= #State.all_combinations then
      break
    end

    local mark = State.marks[i]
    local mark_text = State.all_combinations[i]:upper()

    if capture_len == 0 or mark_text:sub(1, capture_len) == State.link_capture then
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
        local font_size = 10
        local text_width = #mark_text * (font_size * 1.1)
        local text_height = font_size * 1.1
        local container_width = text_width + (padding * 2)
        local container_height = text_height + (padding * 2)

        local arrow_height = 3
        local arrow_width = 6
        local corner_radius = 2

        local bg_rect = hs.geometry.rect(
          frame.x + (frame.w / 2) - (container_width / 2),
          frame.y + (frame.h / 3 * 2) + arrow_height,
          container_width,
          container_height
        )

        local rx = bg_rect.x
        local ry = bg_rect.y
        local rw = bg_rect.w
        local rh = bg_rect.h

        local arrow_left = rx + (rw / 2) - (arrow_width / 2)
        local arrow_right = arrow_left + arrow_width
        local arrow_top = ry - arrow_height
        local arrow_bottom = ry
        local arrow_middle = arrow_left + (arrow_width / 2)

        bg.coordinates = {
          -- Draw arrow
          { x = arrow_left, y = arrow_bottom },
          { x = arrow_middle, y = arrow_top },
          { x = arrow_right, y = arrow_bottom },
          -- Top right corner
          {
            x = rx + rw - corner_radius,
            y = ry,
            c1x = rx + rw - corner_radius,
            c1y = ry,
            c2x = rx + rw,
            c2y = ry,
          },
          { x = rx + rw, y = ry + corner_radius, c1x = rx + rw, c1y = ry, c2x = rx + rw, c2y = ry + corner_radius },
          -- Bottom right corner
          {
            x = rx + rw,
            y = ry + rh - corner_radius,
            c1x = rx + rw,
            c1y = ry + rh - corner_radius,
            c2x = rx + rw,
            c2y = ry + rh,
          },
          {
            x = rx + rw - corner_radius,
            y = ry + rh,
            c1x = rx + rw,
            c1y = ry + rh,
            c2x = rx + rw - corner_radius,
            c2y = ry + rh,
          },
          -- Bottom left corner
          {
            x = rx + corner_radius,
            y = ry + rh,
            c1x = rx + corner_radius,
            c1y = ry + rh,
            c2x = rx,
            c2y = ry + rh,
          },
          {
            x = rx,
            y = ry + rh - corner_radius,
            c1x = rx,
            c1y = ry + rh,
            c2x = rx,
            c2y = ry + rh - corner_radius,
          },
          -- Top left corner
          { x = rx, y = ry + corner_radius, c1x = rx, c1y = ry + corner_radius, c2x = rx, c2y = ry },
          { x = rx + corner_radius, y = ry, c1x = rx, c1y = ry, c2x = rx + corner_radius, c2y = ry },
          -- Back to start
          { x = arrow_left, y = arrow_bottom },
        }
        text.text = mark_text
        text.frame = {
          x = rx,
          y = ry - (arrow_height / 2) + ((rh - text_height) / 2), -- Vertically center
          w = rw,
          h = text_height,
        }

        elements_to_draw[#elements_to_draw + 1] = bg
        elements_to_draw[#elements_to_draw + 1] = text
        count = count + 1
      end
    end
  end

  State.canvas:replaceElements(elements_to_draw)
  State.canvas:show()
end

---Clicks a mark
---@param combination string
---@return nil
function Marks.click(combination)
  for i, c in ipairs(State.all_combinations) do
    if c == combination and State.marks[i] and State.on_click_callback then
      local success, err = pcall(State.on_click_callback, State.marks[i])
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
  Actions.smooth_scroll(0, M.config.scroll_step_full_page, M.config.smooth_scroll)
end

---Scrolls to bottom
---@return nil
function Commands.cmd_scroll_to_bottom()
  Actions.smooth_scroll(0, -M.config.scroll_step_full_page, M.config.smooth_scroll)
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

    local press_ok = element:performAction("AXPress")

    if not press_ok then
      local frame = mark.frame
      if frame then
        Actions.try_click(frame)
      end
    end
  end
  hs.timer.doAfter(0, function()
    Marks.show(false, "link")
  end)
end

---Go to input mode
---@return nil
function Commands.cmd_goto_input()
  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local element = mark.element

    local press_ok = element:performAction("AXPress")

    if press_ok then
      local focused = Utils.get_attribute(element, "AXFocused")
      if not focused then
        Actions.try_click(mark.frame)
        return
      end
    end

    Actions.try_click(mark.frame)
  end
  hs.timer.doAfter(0, function()
    Marks.show(false, "input")
  end)
end

---Right click
---@return nil
function Commands.cmd_right_click()
  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
    local element = mark.element

    local press_ok = element:performAction("AXShowMenu")

    if not press_ok then
      local frame = mark.frame
      if frame then
        Actions.try_click(frame, "right")
      end
    end
  end
  hs.timer.doAfter(0, function()
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
  hs.timer.doAfter(0, function()
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

      local download_url_attr = Utils.get_attribute(element, "AXURL")

      if download_url_attr then
        local url = download_url_attr.url

        if url and url:match("^data:image/") then
          -- Handle base64 images
          local base64_data = url:match("^data:image/[^;]+;base64,(.+)$")
          if base64_data then
            local decoded_data = hs.base64.decode(base64_data)
            ---@diagnostic disable-next-line: param-type-mismatch
            local file_name = description:gsub("%W+", "_") .. ".jpg"
            local file_path = os.getenv("HOME") .. "/Downloads/" .. file_name

            local file = io.open(file_path, "wb")
            if file then
              file:write(decoded_data)
              file:close()
              hs.alert.show("Image saved: " .. file_name, nil, nil, 2)
            end
          end
        else
          -- Handle regular URLs
          hs.http.asyncGet(url, nil, function(status, body, headers)
            if status == 200 then
              local content_type = headers["Content-Type"] or ""
              if content_type:match("^image/") then
                local file_name = url:match("^.+/(.+)$") or "image.jpg"
                if not file_name:match("%.%w+$") then
                  file_name = file_name .. ".jpg"
                end

                local file_path = os.getenv("HOME") .. "/Downloads/" .. file_name
                local file = io.open(file_path, "wb")
                if file then
                  file:write(body)
                  file:close()
                  hs.alert.show("Image downloaded: " .. file_name, nil, nil, 2)
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
function Commands.cmd_move_mouse_to_link()
  ModeManager.set_mode(MODES.LINKS)
  State.on_click_callback = function(mark)
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
  hs.timer.doAfter(0, function()
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

  local ax_window = Elements.get_ax_window()
  if not ax_window then
    return
  end

  ElementFinder.find_next_button_elements(ax_window, function(elements)
    if #elements > 0 then
      elements[1]:performAction("AXPress")
    else
      hs.alert.show("No next button found", nil, nil, 2)
    end
  end)
end

---Prev page
---@return nil
function Commands.cmd_prev_page()
  if not Utils.is_in_browser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local ax_window = Elements.get_ax_window()
  if not ax_window then
    return
  end

  ElementFinder.find_prev_button_elements(ax_window, function(elements)
    if #elements > 0 then
      elements[1]:performAction("AXPress")
    else
      hs.alert.show("No previous button found", nil, nil, 2)
    end
  end)
end

---Copy page URL to clipboard
---@return nil
function Commands.cmd_copy_page_url_to_clipboard()
  if not Utils.is_in_browser() then
    hs.alert.show("Only available in browser", nil, nil, 2)
    return
  end

  local ax_web_area = Elements.get_ax_web_area()
  local url = ax_web_area and Utils.get_attribute(ax_web_area, "AXURL")
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
local function handle_vim_input(char, modifiers)
  log.df("handleVimInput: " .. char .. " modifiers: " .. hs.inspect(modifiers))

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
    local has_partial_matches = false
    for i, _ in ipairs(State.marks) do
      if i > #State.all_combinations then
        break
      end

      local markText = State.all_combinations[i]:upper()
      if markText:sub(1, #State.link_capture) == State.link_capture then
        has_partial_matches = true
        break
      end
    end

    if not has_partial_matches then
      State.link_capture = ""
      Marks.draw()
    end
    return
  end

  -- Build key combination
  local key_combo = ""
  if modifiers and modifiers.ctrl then
    key_combo = "C-"
  end
  key_combo = key_combo .. char

  if State.mode == MODES.MULTI then
    key_combo = State.multi .. key_combo
  end

  -- Execute mapping
  local mapping = M.config.mapping[key_combo]
  if mapping then
    ModeManager.set_mode(MODES.NORMAL)

    if type(mapping) == "string" then
      local cmd = Commands[mapping]
      if cmd then
        cmd()
      else
        log.wf("Unknown command: " .. mapping)
      end
    elseif type(mapping) == "table" then
      hs.eventtap.keyStroke(mapping[1], mapping[2], 0)
    end
  elseif State.mapping_prefixes[key_combo] then
    ModeManager.set_mode(MODES.MULTI, key_combo)
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
  local key_code = event:getKeyCode()
  local modifiers = { ctrl = flags.ctrl }

  -- Handle escape key
  if key_code == hs.keycodes.map["escape"] then
    local delay_since_last_escape = (hs.timer.absoluteTime() - State.last_escape) / 1e9
    State.last_escape = hs.timer.absoluteTime()

    if Utils.is_in_browser() and delay_since_last_escape < M.config.double_press_delay then
      Actions.force_unfocus()
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
  if State.mode == MODES.LINKS and key_code == hs.keycodes.map["delete"] then
    hs.timer.doAfter(0, function()
      handle_vim_input("backspace", { ctrl = flags.ctrl })
    end)
    return true
  end

  local char = hs.keycodes.map[key_code]

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

  hs.timer.doAfter(0, function()
    handle_vim_input(char, modifiers)
  end)

  return true
end

--------------------------------------------------------------------------------
-- Watchers
--------------------------------------------------------------------------------

---Clears all caches and state when switching apps
---@return nil
local function cleanup_on_app_switch()
  -- Clear all element caches
  Utils.clear_cache()

  -- Clear any active marks and canvas
  Marks.clear()

  -- Reset link capture state
  State.link_capture = ""

  -- Force garbage collection to free up memory
  collectgarbage("collect")

  log.df("Cleaned up caches and state for app switch")
end

local app_watcher = nil

---Starts the app watcher
---@return nil
local function start_watcher()
  if app_watcher then
    app_watcher:stop()
    app_watcher = nil
  end

  app_watcher = hs.application.watcher.new(function(app_name, event_type)
    log.df(string.format("App event: %s - %s", app_name, event_type))

    if event_type == hs.application.watcher.activated then
      log.df(string.format("App activated: %s", app_name))

      cleanup_on_app_switch()

      if not State.event_loop then
        State.event_loop = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, event_handler):start()
        log.df("Started event loop")
      end

      if Utils.tbl_contains(M.config.excluded_apps, app_name) then
        ModeManager.set_mode(MODES.DISABLED)
        log.df("Disabled mode for excluded app: " .. app_name)
      else
        ModeManager.set_mode(MODES.NORMAL)
      end
    end
  end)

  app_watcher:start()

  log.df("App watcher started")
end

---Periodic cache cleanup to prevent memory leaks
---@return nil
local function setup_periodic_cleanup()
  if State.cleanup_timer then
    State.cleanup_timer:stop()
  end

  State.cleanup_timer = hs.timer
    .new(30, function() -- Every 30 seconds
      -- Only clean up if we're not actively showing marks
      if State.mode ~= MODES.LINKS then
        Utils.clear_cache()
        collectgarbage("collect")
        log.df("Periodic cache cleanup completed")
      end
    end)
    :start()
end

---Clean up timers and watchers
---@return nil
local function cleanup_watchers()
  if app_watcher then
    app_watcher:stop()
    app_watcher = nil
    log.df("Stopped app watcher")
  end

  if State.cleanup_timer then
    State.cleanup_timer:stop()
    State.cleanup_timer = nil
    log.df("Stopped cleanup timer")
  end
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
function M:init(userConfig)
  print("-- Initializing Vimium...")
  M.config = _utils.tbl_deep_extend("force", DEFAULT_CONFIG, userConfig or {})
  log = hs.logger.new(M.mod_name, M.config.log_level)

  Utils.fetch_mapping_prefixes()
  Utils.generate_combinations()
  RoleMaps.init() -- Initialize role maps for performance
end

---Starts the module
---@return nil
function M:start()
  print("-- Starting Vimium...")

  cleanup_watchers()
  start_watcher()
  setup_periodic_cleanup()
  MenuBar.create()

  local current_app = Elements.get_app()
  if current_app and Utils.tbl_contains(M.config.excluded_apps, current_app:name()) then
    ModeManager.set_mode(MODES.DISABLED)
  else
    ModeManager.set_mode(MODES.NORMAL)
  end
end

---Stops the module
---@return nil
function M:stop()
  print("-- Stopping Vimium...")

  cleanup_watchers()

  if State.event_loop then
    State.event_loop:stop()
    State.event_loop = nil
    log.df("Stopped event loop")
  end

  MenuBar.destroy()
  Marks.clear()

  cleanup_on_app_switch()
end

return M
