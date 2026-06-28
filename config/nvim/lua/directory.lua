local M = {}
local ns = vim.api.nvim_create_namespace("directory_icons")
local ns_git = vim.api.nvim_create_namespace("directory_git")

local function get_git_status(cwd)
  local git_root = vim.fs.root(cwd, ".git")
  if not git_root then
    return nil
  end

  local result = vim
    .system({ "git", "status", "--porcelain" }, {
      text = true,
      cwd = git_root,
    })
    :wait()

  if result.code ~= 0 then
    return nil
  end

  local prefix = cwd:gsub("^" .. vim.pesc(git_root) .. "/?", "")
  if prefix ~= "" then
    prefix = prefix .. "/"
  end

  local status_map = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    local status, path = line:match("^(..)%s+(.*)")
    if status and path then
      local rel = path:gsub("^" .. vim.pesc(prefix), "")

      -- index full path
      status_map[rel] = status

      -- index just the basename (for files directly visible)
      local basename = rel:match("[^/]+$")
      if basename and not status_map[basename] then
        status_map[basename] = status
      end

      -- index the first component visible in the buffer
      -- e.g. rel = "lua/a/b/c/keymap.lua" -> first = "lua/"
      local first = rel:match("^([^/]+)/")
      if first then
        if not status_map[first .. "/"] then
          status_map[first .. "/"] = status
        end
      end
    end
  end

  return status_map
end

local status_symbols = {
  [" M"] = { "✹", "MiniDiffSignChange" },
  ["M "] = { "•", "MiniDiffSignChange" },
  ["MM"] = { "≠", "MiniDiffSignChange" },
  ["A "] = { "+", "MiniDiffSignAdd" },
  ["??"] = { "?", "MiniDiffSignDelete" },
  ["!!"] = { "!", "MiniDiffSignChange" },
  ["D "] = { "-", "MiniDiffSignDelete" },
  ["R "] = { "→", "MiniDiffSignChange" },
}

local function render(buf)
  buf = buf or 0
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_clear_namespace(buf, ns_git, 0, -1)

  -- use buffer name as cwd, it's always the directory being shown
  local cwd = vim.api.nvim_buf_get_name(buf)
  local status_map = get_git_status(cwd)
  local devicons = require("nvim-web-devicons")

  for i, name in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    -- icons
    local icon, icon_hl
    if name:sub(-1) == "/" then
      icon, icon_hl = "󰉋", "Directory"
    else
      icon, icon_hl = devicons.get_icon(name, vim.fs.ext(name))
      if not icon then
        icon, icon_hl = devicons.get_icon_by_filetype(vim.bo[buf].filetype, { default = true })
      end
    end

    vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
      virt_text = { { icon .. " ", icon_hl } },
      virt_text_pos = "inline",
    })

    -- git signs
    if status_map then
      -- name already has trailing slash for dirs, no slash for files
      -- so it naturally matches our status_map keys
      local entry = status_map[name] or status_map[name:gsub("/$", "")]
      local sym_hl = entry and status_symbols[entry]
      if sym_hl then
        vim.api.nvim_buf_set_extmark(buf, ns_git, i - 1, 0, {
          sign_text = sym_hl[1],
          sign_hl_group = sym_hl[2],
          priority = 2,
        })
      end
    end
  end
end

function M.render(buf)
  render(buf)
end

return M
