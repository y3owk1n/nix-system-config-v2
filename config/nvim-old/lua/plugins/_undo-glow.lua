---@type PluginModule
local M = {}

M.name = "undo-glow"

M.lazy = {
  event = { "UIEnter" },
}

M.registry = {
  { src = "https://github.com/y3owk1n/undo-glow.nvim", name = "undo-glow" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "undo-glow")

  if not plugin_ok then
    return
  end

  ---@type UndoGlow.Config
  local plugin_opts = {
    animation = {
      enabled = true,
      duration = 300,
      window_scoped = true,
    },
    highlights = {
      undo = {
        hl_color = { bg = "#693232" }, -- muted red
      },
      redo = {
        hl_color = { bg = "#2F4640" }, -- muted green
      },
      yank = {
        hl_color = { bg = "#7A683A" }, -- muted yellow
      },
      paste = {
        hl_color = { bg = "#325B5B" }, -- muted cyan
      },
      search = {
        hl_color = { bg = "#5C475C" }, -- muted purple
      },
      comment = {
        hl_color = { bg = "#7A5A3D" }, -- muted orange
      },
      cursor = {
        hl_color = { bg = "#793D54" }, -- muted magenta
      },
    },
    priority = 2048 * 3,
  }

  plugin.setup(plugin_opts)

  local function preserve_cursor()
    local pos = vim.fn.getpos(".")

    vim.schedule(function()
      vim.g.ug_ignore_cursor_moved = true
      vim.fn.setpos(".", pos)
    end)
  end

  vim.keymap.set("n", "u", function()
    plugin.undo()
  end, { desc = "Undo with highlight", noremap = true })

  vim.keymap.set("n", "U", function()
    plugin.redo()
  end, { desc = "Redo with highlight", noremap = true })

  vim.keymap.set("n", "p", function()
    plugin.paste_below()
  end, { desc = "Paste below with highlight", noremap = true })

  vim.keymap.set("n", "P", function()
    plugin.paste_above()
  end, { desc = "Paste above with highlight", noremap = true })

  vim.keymap.set("n", "n", function()
    plugin.search_next({
      animation = {
        animation_type = "strobe",
      },
    })
  end, { desc = "Search next with highlight", noremap = true })

  vim.keymap.set("n", "N", function()
    plugin.search_prev({
      animation = {
        animation_type = "strobe",
      },
    })
  end, { desc = "Search prev with highlight", noremap = true })

  vim.keymap.set("n", "*", function()
    plugin.search_star({
      animation = {
        animation_type = "strobe",
      },
    })
  end, { desc = "Search star with highlight", noremap = true })

  vim.keymap.set("n", "#", function()
    plugin.search_hash({
      animation = {
        animation_type = "strobe",
      },
    })
  end, { desc = "Search hash with highlight", noremap = true })

  vim.keymap.set({ "n", "x" }, "gc", function()
    preserve_cursor()
    return plugin.comment()
  end, { desc = "Toggle comment with highlight", noremap = true, expr = true })

  vim.keymap.set("o", "gc", function()
    plugin.comment_textobject()
  end, { desc = "Toggle textobject with highlight", noremap = true })

  vim.keymap.set("n", "gcc", function()
    return plugin.comment_line()
  end, { desc = "Toggle comment line with highlight", noremap = true, expr = true })

  local augroup = vim.api.nvim_create_augroup("UndoGlow", { clear = true })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup,
    desc = "Highlight when yanking (copying) text",
    callback = function()
      plugin.yank()
    end,
  })

  -- This only handles neovim instance and do not highlight when switching panes in tmux
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup,
    desc = "Highlight when cursor moved significantly",
    callback = function()
      plugin.cursor_moved({
        animation = {
          animation_type = "slide",
        },
      })
    end,
  })

  -- This will handle highlights when focus gained, including switching panes in tmux
  vim.api.nvim_create_autocmd("FocusGained", {
    group = augroup,
    desc = "Highlight when focus gained",
    callback = function()
      ---@type UndoGlow.CommandOpts
      local opts = {
        animation = {
          animation_type = "slide",
        },
      }

      opts = require("undo-glow.utils").merge_command_opts("UgCursor", opts)
      local pos = require("undo-glow.utils").get_current_cursor_row()

      plugin.highlight_region(vim.tbl_extend("force", opts, {
        s_row = pos.s_row,
        s_col = pos.s_col,
        e_row = pos.e_row,
        e_col = pos.e_col,
        force_edge = opts.force_edge == nil and true or opts.force_edge,
      }))
    end,
  })

  vim.api.nvim_create_autocmd("CmdLineLeave", {
    group = augroup,
    pattern = { "/", "?" },
    desc = "Highlight when search cmdline leave",
    callback = function()
      plugin.search_cmd({
        nimation = {
          animation_type = "fade",
        },
      })
    end,
  })
end

return M
