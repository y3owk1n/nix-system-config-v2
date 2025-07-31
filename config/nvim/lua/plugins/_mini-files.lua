---@type PluginModule
local M = {}

M.name = "mini.files"

M.lazy = {
  keys = {
    "<leader>e",
    "<leader>E",
  },
}

function M.setup()
  vim.pack.add({ "https://github.com/echasnovski/mini.files" })

  local plugin_ok, plugin = pcall(require, "mini.files")

  if not plugin_ok then
    return
  end

  local plugin_opts = {

    windows = {
      preview = true,
      width_focus = 30,
      width_preview = 60,
    },
    mappings = {
      close = "q",
      go_in = "",
      go_in_plus = "l",
      go_out = "",
      go_out_plus = "h",
      mark_goto = "'",
      mark_set = "m",
      reset = "<BS>",
      reveal_cwd = "@",
      show_help = "g?",
      synchronize = "=",
      trim_left = "<",
      trim_right = ">",
    },
    options = { use_as_default_explorer = true },
  }

  plugin.setup(plugin_opts)

  --- setting autocmd
  local augroup = vim.api.nvim_create_augroup("MiniFilesRename", {})
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "MiniFilesActionRename",
    callback = function(ev)
      local from, to = ev.data.from, ev.data.to

      local snacks_exists, snacks = pcall(require, "snacks")
      if snacks_exists then
        snacks.rename.on_rename_file(from, to)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = { "MiniFilesActionRename", "MiniFilesActionMove" },
    callback = function(ev)
      local from, to = ev.data.from, ev.data.to

      local warp_exists, warp = pcall(require, "warp")
      if warp_exists then
        warp.on_file_update(from, to)
      end
    end,
  })

  --- setting keymaps
  vim.keymap.set("n", "<leader>e", function()
    if not plugin.close() then
      local buf_path = vim.api.nvim_buf_get_name(0)
      if buf_path == "" or not vim.uv.fs_stat(buf_path) then
        buf_path = vim.uv.cwd() or ""
      end
      plugin.open(buf_path, true)
    end
  end, { desc = "Explorer (buffer path)" })

  vim.keymap.set("n", "<leader>E", function()
    if not plugin.close() then
      plugin.open(vim.uv.cwd(), true)
    end
  end, { desc = "Explorer (cwd)" })
end

return M
