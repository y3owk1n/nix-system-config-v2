-- Decoration for the builtin "dir" listing (:h dir).
--
-- Icons (inline virt_text) and git signs (sign_text) are placed as persistent
-- extmarks from the DirReadPost hook: both are laid out before decoration
-- providers run, so ephemeral marks are silently dropped for them.
-- Symlink targets and file classification are eol/overlay text, which does
-- work ephemerally, so they go through a decoration provider (:h dir-decorate).

local M = {}

local ns_icon = vim.api.nvim_create_namespace("directory_icons")
local ns_git = vim.api.nvim_create_namespace("directory_git")
local ns_classify = vim.api.nvim_create_namespace("directory_classify")

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

--- Map `git status --porcelain -z` output onto the entry names visible in `cwd`.
--- A change nested below an entry marks that entry.
---@param stdout string NUL-separated records
---@param prefix string listed directory, relative to `root`, "" or "dir/"
---@return table<string, string>
local function parse_status(stdout, prefix)
  local fields = vim.split(stdout, "\0")
  local map = {}
  local i = 1
  while i <= #fields do
    local status, path = fields[i]:match("^(..) (.*)$")
    i = i + 1
    if status then
      -- rename/copy records carry the old path in a trailing field
      if status:find("^[RC]") then
        i = i + 1
      end
      if vim.startswith(path, prefix) then
        local rel = path:sub(#prefix + 1)
        local dir = rel:match("^([^/]+)/")
        -- buffer lines carry a trailing slash for directories
        local key = dir and (dir .. "/") or rel
        map[key] = map[key] or status
      end
    end
  end
  return map
end

---@param buf integer
---@param cwd string
local function place_git_signs(buf, cwd)
  local root = vim.fs.root(cwd, ".git")
  if not root then
    return
  end

  -- the buffer name carries a trailing slash; relpath tolerates it and yields
  -- "." when the listing is the worktree root itself
  local rel = vim.fs.relpath(root, cwd)
  if not rel then
    return
  end
  local prefix = rel ~= "." and (rel .. "/") or ""

  -- -z: no quoting or octal-escaping, so names with spaces or non-ASCII match.
  -- --no-optional-locks: never take index.lock, so a concurrent git in a
  -- terminal cannot fail because the listing refreshed.
  local cmd = { "git", "--no-optional-locks", "status", "--porcelain", "-z" }
  if prefix ~= "" then
    -- bound git's scan to the subtree actually on screen
    vim.list_extend(cmd, { "--", prefix })
  end

  vim.system(cmd, { text = true, cwd = root }, function(res)
    if res.code ~= 0 then
      return
    end
    vim.schedule(function()
      -- the listing may have been reloaded or closed while git ran
      if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_name(buf) ~= cwd then
        return
      end

      local status = parse_status(res.stdout, prefix)
      vim.api.nvim_buf_clear_namespace(buf, ns_git, 0, -1)
      for i, name in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        local sym = status_symbols[status[name] or ""]
        if sym then
          vim.api.nvim_buf_set_extmark(buf, ns_git, i - 1, 0, {
            sign_text = sym[1],
            sign_hl_group = sym[2],
            priority = 2,
          })
        end
      end
    end)
  end)
end

---@param buf integer
local function place_icons(buf)
  local devicons = require("nvim-web-devicons")

  vim.api.nvim_buf_clear_namespace(buf, ns_icon, 0, -1)
  for i, name in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local icon, hl = "󰉋", "Directory"
    if name:sub(-1) ~= "/" then
      -- ext is derived from name; mini.icons' devicons mock ignores it outright
      icon, hl = devicons.get_icon(name, nil, { default = true })
    end
    vim.api.nvim_buf_set_extmark(buf, ns_icon, i - 1, 0, {
      virt_text = { { icon .. " ", hl } },
      virt_text_pos = "inline",
    })
  end
end

local glyph = { fifo = "|", socket = "=", char = "%", block = "#" }

-- Ephemeral, so it survives any DirReadPost handler that reorders lines.
vim.api.nvim_set_decoration_provider(ns_classify, {
  on_win = function(_, _, buf)
    return vim.bo[buf].filetype == "directory"
  end,
  on_range = function(_, _, buf, row)
    local name = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    if not name or name == "" then
      return row + 1
    end

    local path = vim.fs.joinpath(vim.api.nvim_buf_get_name(buf), (name:gsub("/$", "")))
    local stat = vim.uv.fs_lstat(path)
    if not stat then
      return row + 1
    end

    if stat.type == "link" then
      vim.api.nvim_buf_set_extmark(buf, ns_classify, row, 0, {
        virt_text = { { "-> " .. (vim.uv.fs_readlink(path) or "?"), "Dimmed" } },
        virt_text_pos = "eol",
        ephemeral = true,
      })
      return row + 1
    end

    local exe = stat.type == "file" and bit.band(stat.mode, tonumber("111", 8)) ~= 0
    local char = glyph[stat.type] or (exe and "*")
    if char then
      vim.api.nvim_buf_set_extmark(buf, ns_classify, row, #name, {
        virt_text = { { char, "Dimmed" } },
        virt_text_pos = "overlay",
        ephemeral = true,
      })
    end
    return row + 1
  end,
})

--- User DirReadPost handler. Register it after any handler that sorts or
--- filters the listing: extmarks anchor to rows, not to entry names.
---@param args table autocmd callback args
function M.render(args)
  local buf = args.buf or 0
  local cwd = vim.api.nvim_buf_get_name(buf)

  place_icons(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns_git, 0, -1)
  place_git_signs(buf, cwd)
end

return M
