-- This module is originated and credits to `dzirtuss` at `https://github.com/dzirtusss/vifari`
-- I had made lots of modifications to the original code including performance and supporting for system wide instead
-- of just within Safari. In my opinion, there are too many changes that made it hard to contribute back to the original
-- project.

---@diagnostic disable: undefined-global

local _utils = require("utils")
local app_watcher = require("app_watcher")

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

local app_watcher_name = "vimium_module"

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
---@field marks table<number, table<string, table|nil>>
---@field link_capture string
---@field last_escape number
---@field mapping_prefixes table<string, boolean>
---@field all_combinations string[]
---@field event_loop table|nil
---@field canvas table|nil
---@field on_click_callback fun(any)|nil
---@field focus_watcher table|nil
---@field cleanup_timer table|nil

---@class Hs.Vimium.WalkElementOpts
---@field element table
---@field depth number
---@field cb fun(element: table)

---@class Hs.Vimium.FindElementOpts : Hs.Vimium.WalkElementOpts
---@field withUrls? boolean

---@class Hs.Vimium.WalkAndMatchOpts : Hs.Vimium.WalkElementOpts
---@field matcher fun(element: table, extra: any): boolean
---@field extra any

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
  depth = 50,
  max_elements = 676, -- 26*26 combinations
  chunk_size = 20, -- Process elements in chunks for better performance
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
  focus_watcher = nil,
  cleanup_timer = nil,
}

-- Element cache with weak references for garbage collection
local element_cache = setmetatable({}, { __mode = "k" })

local attribute_cache = setmetatable({}, { __mode = "k" })

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
  hs.printf("[Vimium][%s.%03d] %s", timestamp, ms, message)
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
---@param element table
---@param attribute_name string
---@return table|nil
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
    local ax_app = Elements.get_ax_app()
    return ax_app and Utils.get_attribute(ax_app, "AXFocusedUIElement")
  end)
end

---Returns the web area element for AXUIElement
---@return table|nil
function Elements.get_ax_web_area()
  return Utils.get_cached_element("axWebArea", function()
    local ax_window = Elements.get_ax_window()
    return ax_window and Elements.find_ax_role(ax_window, "AXWebArea")
  end)
end

---Returns the menu bar element for AXUIElement
---@return table|nil
function Elements.get_ax_menu_bar()
  return Utils.get_cached_element("axMenuBar", function()
    local ax_app = Elements.get_ax_app()
    return ax_app and Utils.get_attribute(ax_app, "AXMenuBar")
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
---@param root_element table
---@param role string
---@return table|nil
function Elements.find_ax_role(root_element, role)
  if not root_element then
    return nil
  end

  local axRole = Utils.get_attribute(root_element, "AXRole")
  if axRole == role then
    return root_element
  end

  local axChildren = Utils.get_attribute(root_element, "AXChildren") or {}
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
    timer.doAfter(0, Marks.clear)
  end

  if mode == MODES.MULTI then
    State.multi = char
  else
    State.multi = nil
  end

  if MenuBar.item then
    local current_app = Elements.get_app()
    local mode_char = char or default_mode_chars[mode] or "?"

    -- Show app context in menu bar for debugging
    if M.config.show_logs then
      local appName = current_app and current_app:name() or "Unknown"
      MenuBar.item:setTitle(mode_char .. ":" .. appName:sub(1, 3))
    else
      MenuBar.item:setTitle(mode_char)
    end
  end

  Utils.log(string.format("Mode changed: %s -> %s", previous_mode, mode))
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

  local browser_scripts = {
    Safari = 'tell application "Safari" to tell window 1 to set current tab to (make new tab with properties {URL:"%s"})',
    ["Google Chrome"] = 'tell application "Google Chrome" to tell window 1 to make new tab with properties {URL:"%s"}',
    Firefox = 'tell application "Firefox" to tell window 1 to open location "%s"',
    ["Microsoft Edge"] = 'tell application "Microsoft Edge" to tell window 1 to make new tab with properties {URL:"%s"}',
    ["Brave Browser"] = 'tell application "Brave Browser" to tell window 1 to make new tab with properties {URL:"%s"}',
  }

  local current_app = Elements.get_app()
  if not current_app then
    return
  end

  local appName = current_app:name()
  local script = browser_scripts[appName] or browser_scripts["Safari"]

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

function Actions.force_unfocus()
  Utils.log("forced unfocus on escape")

  local focused_element = Elements.get_ax_focused_element()
  if not focused_element then
    return
  end

  focused_element:setAttributeValue("AXFocused", false)

  hs.alert.show("Force unfocused!")
end

--------------------------------------------------------------------------------
-- Element Finding
--------------------------------------------------------------------------------

---Checks if an element is partially visible
---@param element table
---@return boolean
function ElementFinder.is_element_partially_visible(element)
  local ax_hidden = Utils.get_attribute(element, "AXHidden")
  local ax_frame = Utils.get_attribute(element, "AXFrame")

  local frame = element and not ax_hidden and ax_frame

  if not frame or frame.w <= 0 or frame.h <= 0 then
    return false
  end

  local fullArea = Elements.get_full_area()

  if not fullArea then
    return false
  end
  local vx, vy, vw, vh = fullArea.x, fullArea.y, fullArea.w, fullArea.h
  local fx, fy, fw, fh = frame.x, frame.y, frame.w, frame.h

  return fx < vx + vw and fx + fw > vx and fy < vy + vh and fy + fh > vy
end

---Checks if an element contains a specific role
---@param element table
---@param roles_to_check string[]
---@return boolean
function ElementFinder.is_element_contain_roles(element, roles_to_check)
  if not element then
    return false
  end

  local role = Utils.get_attribute(element, "AXRole")
  if not role then
    return false
  end

  return Utils.tbl_contains(roles_to_check or {}, role)
end

---Checks if an element is an image
---@param element table
---@return boolean
function ElementFinder.is_element_image(element)
  if not element then
    return false
  end

  local role = Utils.get_attribute(element, "AXRole")
  local url = Utils.get_attribute(element, "AXURL")

  if not role then
    return false
  end

  return role == "AXImage" and url ~= nil
end

---Gets all descendants of an element
---@param elements table[]
---@param cb fun(element: table)
---@return nil
function ElementFinder.get_descendants(elements, cb)
  local chunk_size = M.config.chunk_size or 20
  for i = 1, #elements, chunk_size do
    local end_idx = math.min(i + chunk_size - 1, #elements)
    for j = i, end_idx do
      cb(elements[j])
    end
  end
end

---Gets all children of an element
---@param main_element table
---@param cb fun(element: table)
---@return nil
function ElementFinder.get_childrens(main_element, cb)
  local role = Utils.get_attribute(main_element, "AXRole")
  local main = Utils.get_attribute(main_element, "AXMain")

  if role == "AXWindow" and main == false then
    return
  end

  local source_types = {
    "AXVisibleRows",
    "AXVisibleChildren",
    "AXChildrenInNavigationOrder",
    "AXChildren",
  }

  for _, source_type in ipairs(source_types) do
    local elements = Utils.get_attribute(main_element, source_type)
    if elements and #elements > 0 then
      ElementFinder.get_descendants(elements, cb)
      return
    end
  end
end

---Walks an element and matches it with a predicate
---@param opts Hs.Vimium.WalkAndMatchOpts
---@return nil
function ElementFinder.walk_and_match(opts)
  local element = opts.element
  local depth = opts.depth
  local extra = opts.extra
  local matcher = opts.matcher
  local cb = opts.cb

  if not element or (depth and depth > M.config.depth) then
    return
  end

  local role = Utils.get_attribute(element, "AXRole")
  local frame = Utils.get_attribute(element, "AXFrame")

  if role == "AXApplication" then
    ElementFinder.get_childrens(element, function(child)
      ElementFinder.walk_and_match({
        element = child,
        depth = (depth or 0) + 1,
        extra = extra,
        matcher = matcher,
        cb = cb,
      })
    end)
    return
  end

  if not frame or not ElementFinder.is_element_partially_visible(element) then
    return
  end

  if matcher(element, extra) then
    cb(element)
  end

  ElementFinder.get_childrens(element, function(child)
    ElementFinder.walk_and_match({
      element = child,
      depth = (depth or 0) + 1,
      extra = extra,
      matcher = matcher,
      cb = cb,
    })
  end)
end

---Finds clickable elements
---@param opts Hs.Vimium.FindElementOpts
---@return nil
function ElementFinder.find_clickable_elements(opts)
  ElementFinder.walk_and_match({
    element = opts.element,
    depth = opts.depth,
    extra = opts.withUrls,
    matcher = function(el, needUrl)
      local url = Utils.get_attribute(el, "AXURL")
      return ElementFinder.is_element_contain_roles(el, M.config.ax_jumpable_roles) and (not needUrl or url ~= nil)
    end,
    cb = opts.cb,
  })
end

---Finds scrollable elements
---@param opts Hs.Vimium.FindElementOpts
---@return nil
function ElementFinder.find_scrollable_elements(opts)
  ElementFinder.walk_and_match({
    element = opts.element,
    depth = opts.depth,
    matcher = function(el)
      return ElementFinder.is_element_contain_roles(el, M.config.ax_scrollable_roles)
    end,
    cb = opts.cb,
  })
end

---Finds URL elements
---@param opts Hs.Vimium.FindElementOpts
---@return nil
function ElementFinder.find_url_elements(opts)
  ElementFinder.walk_and_match({
    element = opts.element,
    depth = opts.depth,
    matcher = function(el)
      return ElementFinder.is_element_contain_roles(el, { "AXURL" })
    end,
    cb = opts.cb,
  })
end

---Finds input elements
---@param opts Hs.Vimium.FindElementOpts
---@return nil
function ElementFinder.find_input_elements(opts)
  ElementFinder.walk_and_match({
    element = opts.element,
    depth = opts.depth,
    matcher = function(el)
      return ElementFinder.is_element_contain_roles(el, M.config.ax_editable_roles)
    end,
    cb = opts.cb,
  })
end

---Finds image elements
---@param opts Hs.Vimium.FindElementOpts
---@return nil
function ElementFinder.find_image_elements(opts)
  ElementFinder.walk_and_match({
    element = opts.element,
    depth = opts.depth,
    matcher = function(el)
      return ElementFinder.is_element_image(el)
    end,
    cb = opts.cb,
  })
end

---Finds next button
---@param opts Hs.Vimium.FindElementOpts
---@return nil
function ElementFinder.find_next_button(opts)
  ElementFinder.walk_and_match({
    element = opts.element,
    depth = opts.depth,
    matcher = function(el)
      local role = Utils.get_attribute(el, "AXRole")
      local title = Utils.get_attribute(el, "AXTitle")

      if (role == "AXLink" or role == "AXButton") and title then
        if title:lower():find("next") then
          return true
        end
      end

      return false
    end,
    cb = opts.cb,
  })
end

---Finds prev button
---@param opts Hs.Vimium.FindElementOpts
---@return nil
function ElementFinder.find_prev_button(opts)
  ElementFinder.walk_and_match({
    element = opts.element,
    depth = opts.depth,
    matcher = function(el)
      local role = Utils.get_attribute(el, "AXRole")
      local title = Utils.get_attribute(el, "AXTitle")

      if (role == "AXLink" or role == "AXButton") and title then
        if title:lower():find("prev") or title:lower():find("previous") then
          return true
        end
      end

      return false
    end,
    cb = opts.cb,
  })
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

  -- Pre-validate frame to avoid processing invalid elements later
  local frame = Utils.get_attribute(element, "AXFrame")
  if frame and frame.w > 0 and frame.h > 0 then
    -- Also cache the role since we'll need it for click actions
    local role = Utils.get_attribute(element, "AXRole")

    State.marks[#State.marks + 1] = {
      element = element,
      frame = frame, -- Cache frame for later use
      role = role,
    }
  end
end

---Shows the marks
---@param withUrls boolean
---@param elementType "link"|"scroll"|"url"|"input"|"image" # The type of elements to find ("link", "scroll", "url", "input").
---@return nil
function Marks.show(withUrls, elementType)
  local ax_app = Elements.get_ax_app()
  if not ax_app then
    return
  end

  Marks.clear()
  State.marks = {}

  local predicates = {
    link = ElementFinder.find_clickable_elements,
    scroll = ElementFinder.find_scrollable_elements,
    url = ElementFinder.find_url_elements,
    input = ElementFinder.find_input_elements,
    image = ElementFinder.find_image_elements,
  }

  local predicates_fn = predicates[elementType]

  if predicates_fn then
    predicates_fn({
      element = ax_app,
      depth = 0,
      cb = Marks.add,
      withUrls = elementType == "link" and withUrls or nil,
    })
  end

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

  -- Pre-calculate visible marks to avoid redundant work
  local visible_marks = {}
  local capture_len = #State.link_capture

  for i, mark in ipairs(State.marks) do
    if i > #State.all_combinations then
      break
    end

    local mark_text = State.all_combinations[i]:upper()

    if capture_len == 0 or (capture_len <= #mark_text and mark_text:sub(1, capture_len) == State.link_capture) then
      visible_marks[#visible_marks + 1] = {
        mark = mark,
        text = mark_text,
        frame = mark.frame or Utils.get_attribute(mark.element, "AXFrame"),
      }
    end
  end

  if #visible_marks == 0 then
    State.canvas:hide()
    return
  end

  local elements_to_draw = {}

  for _, visible_mark in ipairs(visible_marks) do
    if visible_mark.frame then
      local mark_elements = Marks.create_mark_element(visible_mark.frame, visible_mark.text)
      if mark_elements then
        for _, element in ipairs(mark_elements) do
          elements_to_draw[#elements_to_draw + 1] = element
        end
      end
    end
  end

  State.canvas:replaceElements(elements_to_draw)
  State.canvas:show()
end

---Creates a mark element
---@param frame table
---@param text string
---@return table|nil
function Marks.create_mark_element(frame, text)
  if not frame then
    return nil
  end

  local padding = 2
  local font_size = 10
  local text_width = #text * (font_size * 1.1)
  local text_height = font_size * 1.1
  local container_width = text_width + (padding * 2)
  local container_height = text_height + (padding * 2)

  local arrow_height = 3
  local arrow_width = 6
  local corner_radius = 2

  local fill_color = { red = 1, green = 0.96, blue = 0.52, alpha = 1 }
  local border_color = { red = 0, green = 0, blue = 0, alpha = 1 }
  local gradient_color = {
    red = 1,
    green = 0.77,
    blue = 0.26,
    alpha = 1,
  }

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

  return {
    {
      type = "segments",
      fillGradient = "linear",
      fillGradientColors = { fill_color, gradient_color },
      fillGradientAngle = 135,
      strokeColor = border_color,
      strokeWidth = 1,
      withShadow = true,
      shadow = { blurRadius = 5.0, color = { alpha = 1 / 3 }, offset = { h = -1.0, w = 1.0 } },
      closed = true,
      coordinates = {
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
      },
    },
    {
      type = "text",
      text = text,
      textAlignment = "center",
      textColor = { ["red"] = 0, ["green"] = 0, ["blue"] = 0, ["alpha"] = 1 },
      textSize = font_size,
      textFont = ".AppleSystemUIFontHeavy",
      textLineBreak = "clip",
      frame = {
        x = rx,
        y = ry - (arrow_height / 2) + ((rh - text_height) / 2), -- Vertically center
        w = rw,
        h = text_height,
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
      local frame = mark.frame or Utils.get_attribute(element, "AXFrame")
      if frame then
        local click_x, click_y = frame.x + frame.w / 2, frame.y + frame.h / 2
        local original_pos = mouse.absolutePosition()
        mouse.absolutePosition({ x = click_x, y = click_y })
        eventtap.leftClick({ x = click_x, y = click_y })
        timer.doAfter(0.1, function()
          mouse.absolutePosition(original_pos)
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
        local click_x, click_y = frame.x + frame.w / 2, frame.y + frame.h / 2
        local original_pos = mouse.absolutePosition()
        mouse.absolutePosition({ x = click_x, y = click_y })
        eventtap.leftClick({ x = click_x, y = click_y })
        timer.doAfter(0.1, function()
          mouse.absolutePosition(original_pos)
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
        local click_x, click_y = frame.x + frame.w / 2, frame.y + frame.h / 2
        local original_pos = mouse.absolutePosition()
        mouse.absolutePosition({ x = click_x, y = click_y })
        eventtap.rightClick({ x = click_x, y = click_y })
        timer.doAfter(0.05, function()
          mouse.absolutePosition(original_pos)
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

  local ax_window = Elements.get_ax_window()
  if not ax_window then
    return
  end

  ElementFinder.find_next_button({
    element = ax_window,
    depth = 0,
    cb = function(element)
      element:performAction("AXPress")
    end,
  })
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

  ElementFinder.find_prev_button({
    element = ax_window,
    depth = 0,
    cb = function(element)
      element:performAction("AXPress")
    end,
  })
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
        Utils.log("Unknown command: " .. mapping)
      end
    elseif type(mapping) == "table" then
      eventtap.keyStroke(mapping[1], mapping[2], 0)
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
    local delay_since_last_escape = (timer.absoluteTime() - State.last_escape) / 1e9
    State.last_escape = timer.absoluteTime()

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
    timer.doAfter(0, function()
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

  timer.doAfter(0, function()
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

  Utils.log("Cleaned up caches and state for app switch")
end

---Starts the app watcher
---@return nil
local function start_watcher()
  app_watcher.register(app_watcher_name, function(app_name, event_type, app_object)
    Utils.log(string.format("App event: %s - %s", app_name, event_type))

    if event_type == watcher.activated then
      cleanup_on_app_switch()

      if not State.event_loop then
        State.event_loop = eventtap.new({ eventtap.event.types.keyDown }, event_handler):start()
        Utils.log("Started event loop for app: " .. app_name)
      end

      if Utils.tbl_contains(M.config.excluded_apps, app_name) then
        ModeManager.set_mode(MODES.DISABLED)
        Utils.log("Disabled mode for excluded app: " .. app_name)
      end
    end
  end)

  Utils.log("App watcher started")
end

---Monitor focus changes within the same app
---@return nil
local function setup_focus_watcher()
  -- Watch for focus changes to automatically switch between normal/insert modes
  State.focus_watcher = eventtap
    .new({ eventtap.event.types.leftMouseDown, eventtap.event.types.tabKeyDown }, function(event)
      if State.mode == MODES.DISABLED then
        return false
      end

      -- Delay slightly to let focus change complete
      timer.doAfter(0.05, function()
        if Elements.is_editable_control_in_focus() then
          if State.mode ~= MODES.INSERT then
            ModeManager.set_mode(MODES.INSERT)
          end
        else
          if State.mode == MODES.INSERT then
            ModeManager.set_mode(MODES.NORMAL)
          end
        end
      end)

      return false -- Don't consume the event
    end)
    :start()

  Utils.log("Focus watcher started")
end

---Periodic cache cleanup to prevent memory leaks
---@return nil
local function setup_periodic_cleanup()
  if State.cleanup_timer then
    State.cleanup_timer:stop()
  end

  State.cleanup_timer = timer
    .new(30, function() -- Every 30 seconds
      -- Only clean up if we're not actively showing marks
      if State.mode ~= MODES.LINKS then
        Utils.clear_cache()
        collectgarbage("collect")
        Utils.log("Periodic cache cleanup completed")
      end
    end)
    :start()
end

---Clean up timers and watchers
---@return nil
local function cleanup_watchers()
  app_watcher.unregister(app_watcher_name)

  if State.focus_watcher then
    State.focus_watcher:stop()
    State.focus_watcher = nil
  end

  if State.cleanup_timer then
    State.cleanup_timer:stop()
    State.cleanup_timer = nil
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
function M.setup(userConfig)
  M.config = _utils.tbl_deep_extend("force", DEFAULT_CONFIG, userConfig or {})

  Utils.fetch_mapping_prefixes()
  Utils.generate_combinations()

  M:start()
end

---Starts the module
---@return nil
function M:start()
  cleanup_watchers()

  start_watcher()

  setup_focus_watcher()
  setup_periodic_cleanup()

  MenuBar.create()

  local current_app = Elements.get_app()
  if current_app and Utils.tbl_contains(M.config.excluded_apps, current_app:name()) then
    ModeManager.set_mode(MODES.DISABLED)
  else
    ModeManager.set_mode(MODES.NORMAL)
  end

  Utils.log("Vim navigation started")
end

---Stops the module
---@return nil
function M:stop()
  cleanup_watchers()

  if State.event_loop then
    State.event_loop:stop()
    State.event_loop = nil
  end

  MenuBar.destroy()
  Marks.clear()

  cleanup_on_app_switch()

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
