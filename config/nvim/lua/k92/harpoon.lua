--- This is a simpler harpoon reimplementation.

--- @class HarpoonItem
--- @field path string
--- @field line number

--- @class Harpoon
local M = {}

local api = vim.api
local fn = vim.fn
local fs = vim.fs

local storage_dir = fn.stdpath("data") .. "/harpoon"

--------------------------------------------------
-- 1. per-project storage path
--------------------------------------------------
--- Get a safe, unique JSON file path for the current working directory
--- @return string
local function get_storage_path()
  fn.mkdir(storage_dir, "p")
  local cwd = fn.fnamemodify(fn.getcwd(), ":~")
  -- replace '/' with '%%' so the file name is valid
  local safe = cwd:gsub("/", "%%")
  return storage_dir .. "/" .. safe .. ".json"
end

--------------------------------------------------
-- 2. persistence
--------------------------------------------------
--- @type HarpoonItem[]
local harpoon_list = {}

--- Load list from disk into memory
local function load_list()
  local f = io.open(get_storage_path(), "r")
  if f then
    local contents = f:read("*a")
    f:close()
    local ok, data = pcall(vim.json.decode, contents)
    if ok then
      harpoon_list = data
    else
      harpoon_list = {}
      fn.rename(get_storage_path(), get_storage_path() .. ".bak")
      vim.notify("Harpoon: Corrupted JSON backed up", vim.log.levels.WARN)
    end
  else
    harpoon_list = {}
  end
end

--- Save list to disk
local function save_list()
  local ok, encoded = pcall(vim.json.encode, harpoon_list)
  if not ok then
    vim.notify("Harpoon: Failed to save list", vim.log.levels.ERROR)
    return
  end
  local f = assert(io.open(get_storage_path(), "w"))
  f:write(encoded)
  f:close()
end

--------------------------------------------------
-- 3. autoreload on DirChanged
--------------------------------------------------
local group = api.nvim_create_augroup("Harpoon", { clear = true })
api.nvim_create_autocmd("DirChanged", { group = group, callback = load_list })
load_list()

--------------------------------------------------
-- 4. Public API
--------------------------------------------------
--- Get all harpooned items
--- @return HarpoonItem[]
function M.get_list()
  return harpoon_list
end

--- Get the count of harpooned items
--- @return number
function M.get_list_count()
  return #harpoon_list
end

--- Get a specific item by index
--- @param index number
--- @return HarpoonItem|nil
function M.get_item(index)
  if index < 1 or index > #harpoon_list then
    return nil
  end
  return harpoon_list[index]
end

--- Find the index of an entry by buffer
--- @param buf number
--- @return number|nil
function M.get_index_by_buf(buf)
  local path = fs.normalize(api.nvim_buf_get_name(buf))
  for i, entry in ipairs(harpoon_list) do
    if fs.normalize(entry.path) == path then
      return i
    end
  end
  return nil
end

--- Update entries if file or folder was updated
--- @param from string
--- @param to string
function M.on_file_update(from, to)
  local changed = false
  for _, entry in ipairs(harpoon_list) do
    if entry.path == from then
      entry.path = to
      changed = true
    elseif vim.startswith(entry.path, from .. "/") then
      -- also fix sub-paths if the renamed item is a directory
      entry.path = to .. entry.path:sub(#from + 1)
      changed = true
    end
  end
  if changed then
    save_list()
    vim.notify("Harpoon: updated after source updates", vim.log.levels.INFO)
  end
end

--------------------------------------------------
-- 4. core actions
--------------------------------------------------
--- Check if a file exists
--- @param p string
--- @return boolean
local function file_exists(p)
  return vim.loop.fs_stat(p) ~= nil
end

--- Get (and load if necessary) the buffer number for an entry
--- @param entry HarpoonItem
--- @return number
local function get_buf(entry)
  -- return the buffer number for entry.path (open it if needed)
  local buf = fn.bufnr(entry.path)
  if buf == -1 then
    buf = fn.bufadd(entry.path)
    fn.bufload(buf)
  end
  return buf
end

--- Add or update current buffer in list
local function add()
  local buf = api.nvim_get_current_buf()
  local path = fs.normalize(api.nvim_buf_get_name(buf))
  local current_line = fn.line(".")

  local found = false
  for i, e in ipairs(harpoon_list) do
    if e.path == path then
      -- Update the line number
      harpoon_list[i].line = current_line
      found = true
      break
    end
  end

  if not found then
    table.insert(harpoon_list, { path = path, line = current_line })
  end

  save_list()
  if found then
    vim.notify("Harpoon: Updated line number", vim.log.levels.INFO)
  else
    vim.notify("Harpoon: Added to #" .. #harpoon_list, vim.log.levels.INFO)
  end
end

--- Navigate to a harpooned file by index
--- @param idx number
local function goto_index(idx)
  local entry = harpoon_list[idx]
  if not entry then
    return
  end
  if not file_exists(entry.path) then
    vim.notify("Harpoon: file no longer exists – removed", vim.log.levels.WARN)
    table.remove(harpoon_list, idx)
    save_list()
    return
  end
  local buf = get_buf(entry)
  api.nvim_set_current_buf(buf)
  api.nvim_win_set_cursor(0, { entry.line or 1, 0 })
end

--- Clear current project's list
local function clear_current()
  harpoon_list = {}
  save_list()
end

--- Clear all harpoon lists across all projects
local function clear_all()
  local files = fn.readdir(storage_dir)
  if not files then
    vim.notify("Harpoon: No harpoon data found", vim.log.levels.INFO)
    return
  end

  -- confirmation prompt
  vim.ui.input({
    prompt = "Clear all harpoon lists for all projects? (y/n) ",
    completion = "file",
  }, function(input)
    if input == nil then
      return
    end

    if input:lower() == "y" then
      clear_current()
      for _, f in ipairs(files) do
        if f:match("%.json$") then
          fn.delete(storage_dir .. "/" .. f)
        end
      end
      vim.notify("Harpoon: All harpoon lists cleared", vim.log.levels.INFO)
    end
  end)
end

--------------------------------------------------
-- 5. floating UI
--------------------------------------------------
--- @type number|nil
local floating_win

--- @type number|nil
local floating_buf

--- Show the floating window with the harpoon list
---@param list_idx number|nil
local function open_window(list_idx)
  -- prune missing files
  local i = 1
  while i <= #harpoon_list do
    if not file_exists(harpoon_list[i].path) then
      table.remove(harpoon_list, i)
    else
      i = i + 1
    end
  end
  save_list() -- keep the on-disk file clean

  if #harpoon_list == 0 then
    vim.notify("Harpoon: Nothing found...", vim.log.levels.INFO)
    return
  end

  if floating_win and api.nvim_win_is_valid(floating_win) then
    api.nvim_win_close(floating_win, true)
  end
  floating_buf = api.nvim_create_buf(false, true)
  floating_win = api.nvim_open_win(floating_buf, true, {
    relative = "editor",
    width = 60,
    height = math.min(#harpoon_list, 20),
    col = (vim.o.columns - 60) / 2,
    row = (vim.o.lines - #harpoon_list - 2) / 2,
    style = "minimal",
    border = "rounded",
    title = "Harpoon List",
  })

  -- buffer options
  api.nvim_set_option_value("filetype", "harpoon-list", { buf = floating_buf })
  api.nvim_set_option_value("buftype", "nofile", { buf = floating_buf })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = floating_buf })
  api.nvim_set_option_value("swapfile", false, { buf = floating_buf })

  local lines = {}
  for idx, entry in ipairs(harpoon_list) do
    local display = fn.fnamemodify(entry.path, ":~:.")
    if idx == list_idx then
      display = display .. " *"
    end
    lines[idx] = string.format("%d  %s", idx, display)
  end
  api.nvim_buf_set_lines(floating_buf, 0, -1, false, lines)

  api.nvim_set_option_value("modifiable", false, { buf = floating_buf })
  api.nvim_set_option_value("readonly", true, { buf = floating_buf })

  --- @param lhs string
  --- @param rhs fun()
  local function map(lhs, rhs)
    api.nvim_buf_set_keymap(floating_buf, "n", lhs, "", { callback = rhs, nowait = true })
  end

  map("q", function()
    api.nvim_win_close(floating_win, true)
  end)
  map("<Esc>", function()
    api.nvim_win_close(floating_win, true)
  end)
  map("<CR>", function()
    local l = api.nvim_win_get_cursor(0)[1]
    api.nvim_win_close(floating_win, true)
    goto_index(l)
  end)
  map("dd", function()
    local l = api.nvim_win_get_cursor(0)[1]
    table.remove(harpoon_list, l)
    save_list()
    open_window()
  end)
  map("<C-k>", function()
    local old = api.nvim_win_get_cursor(0)[1]
    if old > 1 then
      harpoon_list[old], harpoon_list[old - 1] = harpoon_list[old - 1], harpoon_list[old]
      save_list()
      open_window()
      api.nvim_win_set_cursor(floating_win, { math.max(1, old - 1), 0 })
    end
  end)
  map("<C-j>", function()
    local old = api.nvim_win_get_cursor(0)[1]
    if old < #harpoon_list then
      harpoon_list[old], harpoon_list[old + 1] = harpoon_list[old + 1], harpoon_list[old]
      save_list()
      open_window()
      api.nvim_win_set_cursor(floating_win, { math.min(#harpoon_list, old + 1), 0 })
    end
  end)
  for n = 1, 9 do
    map(tostring(n), function()
      api.nvim_win_close(floating_win, true)
      goto_index(n)
    end)
  end
end

--------------------------------------------------
-- keymaps
--------------------------------------------------
vim.keymap.set("n", "<leader>ha", add, { desc = "add" })
vim.keymap.set("n", "<leader>hh", function()
  local index = M.get_index_by_buf(api.nvim_get_current_buf())
  open_window(index)
end, { desc = "harpoon" })
vim.keymap.set("n", "<leader>hc", function()
  clear_current()
  vim.notify("Harpoon: Cleared current list successfully")
end, { desc = "clear" })
vim.keymap.set("n", "<leader>hC", clear_all, { desc = "clear everything" })
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, function()
    goto_index(i)
  end, { desc = "goto #" .. i })
end

return M
