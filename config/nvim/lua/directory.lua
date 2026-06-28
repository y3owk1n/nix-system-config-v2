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

  -- get the relative offset from git root to cwd
  -- e.g. git_root = "/home/user/.dotfiles", cwd = "/home/user/.dotfiles/config/nvim"
  -- prefix = "config/nvim/"
  local prefix = cwd:gsub("^" .. vim.pesc(git_root) .. "/?", "")
  if prefix ~= "" then
    prefix = prefix .. "/"
  end

  local status_map = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    local status, path = line:match("^(..)%s+(.*)")
    if status and path then
      -- strip the cwd prefix so paths are relative to what's visible
      local rel = path:gsub("^" .. vim.pesc(prefix), "")
      status_map[rel] = status
      for dir in rel:gmatch("(.*)/[^/]+") do
        if not status_map[dir] then
          status_map[dir] = status
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

  local cwd = vim.b[buf].directory_cwd or vim.uv.cwd()
  local status_map = get_git_status(cwd)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, name in ipairs(lines) do
    -- icon extmark
    local icon, icon_hl
    if name:sub(-1) == "/" then
      icon, icon_hl = "󰉋", "Directory"
    else
      local devicons = require("nvim-web-devicons")
      icon, icon_hl = devicons.get_icon(name, vim.fs.ext(name))
      if not icon then
        icon, icon_hl = devicons.get_icon_by_filetype(vim.bo[buf].filetype, { default = true })
      end
    end

    vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
      virt_text = { { icon .. " ", icon_hl } },
      virt_text_pos = "inline",
    })

    -- git extmark
    if status_map then
      local rel = name:gsub("/$", "")
      local sym_hl = status_symbols[status_map[rel]]
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
