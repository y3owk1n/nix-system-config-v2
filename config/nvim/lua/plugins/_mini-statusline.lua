---@type PluginModule
local M = {}

M.name = "mini.statusline"

M.lazy = {
  event = { "VeryLazy" },
}

M.registry = {
  { src = "https://github.com/nvim-mini/mini.statusline", name = "mini.statusline" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.statusline")

  if not plugin_ok then
    return
  end

  local use_icons = true

  local section_git = function(args)
    if plugin.is_truncated(args.trunc_width) then
      return ""
    end

    local repo_info = vim.b.githead_summary or {}
    local branch_name = repo_info.head_name or ""

    if branch_name == "" then
      return ""
    end

    local icon = args.icon or (use_icons and "" or "Git")
    return icon .. " " .. branch_name
  end

  local section_warp = function(args)
    local warp_exists, warp = pcall(require, "warp")
    if not warp_exists or not warp or warp.count() < 1 then
      return ""
    end

    if plugin.is_truncated(args.trunc_width) then
      return ""
    end

    local item = warp.get_item_by_buf(0)
    local current = item and item.index or "-"
    local total = warp.count()

    local icon = args.icon or (use_icons and "󱐋" or "Warp")
    return string.format("%s%s/%s", icon, current, total)
  end

  local active_content = function()
    local mode, mode_hl = plugin.section_mode({ trunc_width = 120 })
    local git = section_git({ trunc_width = 40 })
    local diff = plugin.section_diff({ trunc_width = 75 })
    local diagnostics = plugin.section_diagnostics({ trunc_width = 75 })
    local warp = section_warp({ trunc_width = 40 })
    local lsp = plugin.section_lsp({ trunc_width = 75 })
    local filename = plugin.section_filename({ trunc_width = 140 })
    local fileinfo = plugin.section_fileinfo({ trunc_width = 120 })
    local location = plugin.section_location({ trunc_width = 75 })
    local search = plugin.section_searchcount({ trunc_width = 75 })

    return plugin.combine_groups({
      { hl = mode_hl, strings = { mode } },
      { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp, warp } },
      "%=", -- Mark general truncate point
      { hl = "MiniStatuslineFilename", strings = { filename } },
      "%=", -- End left alignment
      { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
      { hl = mode_hl, strings = { search, location } },
    })
  end

  local plugin_opts = {
    content = {
      active = active_content,
      inactive = nil,
    },
    use_icons = use_icons,
  }

  plugin.setup(plugin_opts)
end

return M
