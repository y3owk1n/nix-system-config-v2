---@class Statusline
local M = {}

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

local function trim_trailing_spaces(str)
  return str:gsub("%s+$", "")
end

local function block(str)
  return "%{%" .. str .. "%}"
end

-- ------------------------------------------------------------------
-- Modules
-- ------------------------------------------------------------------

function M.git_status()
  local repo_info = vim.b.githead_summary
  local has_git = repo_info ~= nil and repo_info.head_name ~= nil

  if not has_git or vim.bo.buftype ~= "" then
    return ""
  end

  return string.format("[ %s]", repo_info.head_name)
end

function M.diff_status()
  local changes = {
    add = vim.b.minidiff_summary and vim.b.minidiff_summary.add or 0,
    delete = vim.b.minidiff_summary and vim.b.minidiff_summary.delete or 0,
    change = vim.b.minidiff_summary and vim.b.minidiff_summary.change or 0,
  }

  local has_diff = vim.b.minidiff_summary ~= nil and changes.add + changes.delete + changes.change > 0

  if not has_diff or vim.bo.buftype ~= "" then
    return ""
  end

  local add_str = changes.add > 0 and string.format("+%s ", changes.add) or ""
  local delete_str = changes.delete > 0 and string.format("-%s ", changes.delete) or ""
  local change_str = changes.change > 0 and string.format("~%s ", changes.change) or ""

  return trim_trailing_spaces(string.format(" %s%s%s", add_str, delete_str, change_str))
end

function M.warp_status()
  local warp_exists, warp = pcall(require, "warp")

  if not warp_exists or (warp and warp.count() < 1) then
    return ""
  end

  local item = warp.get_item_by_buf(0)
  local current = item and item.index or "-"
  local total = warp.count()

  return string.format(" 󱐋 [%s/%s]", tonumber(current) or "-", tonumber(total))
end

function M.have_git_diff()
  if M.git_status() .. M.diff_status() .. M.warp_status() ~= "" then
    return true
  end
  return false
end

function M.lsp_status()
  local names = {}
  for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
    table.insert(names, server.name)
  end

  if #names == 0 then
    return ""
  end

  return "  [" .. table.concat(names, " ") .. "]"
end

local function setup_autocmds()
  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = vim.api.nvim_create_augroup("LspStatus", {}),
    callback = function()
      vim.cmd("redrawstatus")
    end,
  })
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@class Statusline.Config

M.config = {}

---@type Statusline.Config
M.defaults = {}

---Setup the plugin
---@param user_config? Statusline.Config
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  setup_autocmds()

  local eval_have_git_diff = "luaeval('(require(''statusline'').have_git_diff())')"
  local eval_git_status = "luaeval('(require(''statusline'').git_status())')"
  local eval_diff_status = "luaeval('(require(''statusline'').diff_status())')"
  local eval_warp_status = "luaeval('(require(''statusline'').warp_status())')"
  local eval_lsp_status = "luaeval('(require(''statusline'').lsp_status())')"

  local left_component =
    string.format("%s ? %s .. %s .. %s", eval_have_git_diff, eval_git_status, eval_diff_status, eval_warp_status)

  -- before the default statusline, push the default statusline to center
  vim.opt.statusline:prepend(block(left_component .. " .. '%=' : '' "))

  -- after the default statusline
  vim.opt.statusline:append(block(eval_lsp_status))
end

return M
