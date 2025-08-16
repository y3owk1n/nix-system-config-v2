---@type LazySpec
return {
  "rebelot/heirline.nvim",
  lazy = false,
  opts = function(_, opts)
    local conditions = require("heirline.conditions")
    local utils = require("heirline.utils")

    local C = {}

    local catppuccin_exists, catppuccin = pcall(require, "catppuccin.palettes")
    if catppuccin_exists then
      C = catppuccin.get_palette("mocha")
    else
      C = {
        base = "#1e1e2e",
        mantle = "#181825",
        crust = "#11111b",
        text = "#cdd6f4",
        subtext0 = "#a6adc8",
        subtext1 = "#bac2de",
        overlay0 = "#7f849c",
        overlay1 = "#9399b2",
        overlay2 = "#a6adc8",
        surface0 = "#313244",
        surface1 = "#45475a",
        surface2 = "#585b70",
        blue = "#89b4fa",
        lavender = "#b4befe",
        sapphire = "#74c7ec",
        sky = "#89dceb",
        teal = "#94e2d5",
        green = "#a6e3a1",
        yellow = "#f9e2af",
        peach = "#fab387",
        maroon = "#eba0ac",
        red = "#f38ba8",
        mauve = "#cba6f7",
        pink = "#f5c2e7",
        flamingo = "#f2cdcd",
        rosewater = "#f5e0dc",
      }
    end

    local warp_exists, warp = pcall(require, "warp")

    local Align = { provider = "%=" }
    local Space = { provider = " " }

    local ViMode = {
      -- get vim current mode, this information will be required by the provider
      -- and the highlight functions, so we compute it only once per component
      -- evaluation and store it as a component attribute
      init = function(self)
        self.mode = vim.fn.mode(1) -- :h mode()
      end,
      -- Now we define some dictionaries to map the output of mode() to the
      -- corresponding string and color. We can put these into `static` to compute
      -- them at initialisation time.
      static = {
        mode_names = { -- change the strings if you like it vvvvverbose!
          n = "N",
          no = "N?",
          nov = "N?",
          noV = "N?",
          ["no\22"] = "N?",
          niI = "Ni",
          niR = "Nr",
          niV = "Nv",
          nt = "Nt",
          v = "V",
          vs = "Vs",
          V = "V_",
          Vs = "Vs",
          ["\22"] = "^V",
          ["\22s"] = "^V",
          s = "S",
          S = "S_",
          ["\19"] = "^S",
          i = "I",
          ic = "Ic",
          ix = "Ix",
          R = "R",
          Rc = "Rc",
          Rx = "Rx",
          Rv = "Rv",
          Rvc = "Rv",
          Rvx = "Rv",
          c = "C",
          cv = "Ex",
          r = "...",
          rm = "M",
          ["r?"] = "?",
          ["!"] = "!",
          t = "T",
        },
        mode_colors = {
          n = "blue",
          i = "green",
          v = "mauve",
          V = "mauve",
          ["\22"] = "mauve",
          c = "peach",
          s = "pink",
          S = "pink",
          ["\19"] = "pink",
          R = "red",
          r = "red",
          ["!"] = "green",
          t = "green",
        },
      },
      {
        provider = "",
        hl = function(self)
          local mode = self.mode:sub(1, 1) -- get only the first mode character
          return { fg = self.mode_colors[mode], bg = "none" }
        end,
      },
      {
        provider = function(self)
          return "%2(" .. self.mode_names[self.mode] .. "%)"
        end,
        hl = function(self)
          local mode = self.mode:sub(1, 1) -- get only the first mode character
          return { bg = self.mode_colors[mode], fg = "base", bold = true }
        end,
      },
      {
        provider = "",
        hl = function(self)
          local mode = self.mode:sub(1, 1) -- get only the first mode character
          return { fg = self.mode_colors[mode], bg = "none" }
        end,
      },
      update = {
        "ModeChanged",
        pattern = "*:*",
        callback = vim.schedule_wrap(function()
          vim.cmd("redrawstatus")
        end),
      },
    }
    local FileNameBlock = {
      -- let's first set up some attributes needed by this component and its children
      init = function(self)
        self.filename = vim.api.nvim_buf_get_name(0)
      end,
    }
    -- We can now define some children separately and add them later

    local FileName = {
      init = function(self)
        self.lfilename = vim.fn.fnamemodify(self.filename, ":.")
        if self.lfilename == "" then
          self.lfilename = "[No Name]"
        end
      end,
      hl = { fg = "text" },

      flexible = 2,

      {
        provider = function(self)
          return self.lfilename
        end,
      },
      {
        provider = function(self)
          return vim.fn.pathshorten(self.lfilename)
        end,
      },
    }

    local FileFlags = {
      {
        condition = function()
          return vim.bo.modified
        end,
        provider = " [+]",
      },
      {
        condition = function()
          return not vim.bo.modifiable or vim.bo.readonly
        end,
        provider = " ",
      },
    }

    local WorkDir = {
      init = function(self)
        local cwd = vim.fn.getcwd(0)
        self.cwd = vim.fn.fnamemodify(cwd, ":~")
      end,
      -- hl = { fg = "blue", bold = true },

      flexible = 1,

      {
        -- evaluates to the full-lenth path
        provider = function(self)
          local trail = self.cwd:sub(-1) == "/" and "" or "/"
          return self.cwd .. trail .. ""
        end,
      },
      {
        -- evaluates to the shortened path
        provider = function(self)
          local cwd = vim.fn.pathshorten(self.cwd)
          local trail = self.cwd:sub(-1) == "/" and "" or "/"
          return cwd .. trail .. ""
        end,
      },
      {
        -- evaluates to "", hiding the component
        provider = "",
      },
    }

    -- let's add the children to our FileNameBlock component
    FileNameBlock = utils.insert(
      FileNameBlock,
      WorkDir,
      FileName,
      FileFlags,
      { provider = "%<" } -- this means that the statusline is cut here when there's not enough space
    )

    local FileIcon = {
      init = function(self)
        local extension = vim.bo.filetype
        self.icon = require("mini.icons").get("filetype", extension)
      end,
      provider = function(self)
        return self.icon and (self.icon .. " ")
      end,
      hl = function()
        return { fg = "blue" }
      end,
    }

    local FileType = {
      provider = function()
        return string.upper(vim.bo.filetype)
      end,
      hl = { fg = "text", bold = true },
    }

    local FileTypeBlock = utils.insert(FileIcon, FileType)

    local FileSize = {
      provider = function()
        -- stackoverflow, compute human readable file size
        local suffix = { "b", "k", "M", "G", "T", "P", "E" }
        local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
        fsize = (fsize < 0 and 0) or fsize
        if fsize < 1024 then
          return fsize .. suffix[1]
        end
        local i = math.floor((math.log(fsize) / math.log(1024)))
        return string.format("%.2g%s", fsize / math.pow(1024, i), suffix[i + 1])
      end,
    }

    local Ruler = {
      {
        provider = "",
        hl = { fg = "surface1", bg = "none" },
      },
      {
        -- %l = current line number
        -- %L = number of lines in the buffer
        -- %c = column number
        -- %P = percentage through file of displayed window
        provider = "%7(%l/%3L%):%2c %P",
        hl = { bg = "surface1", fg = "text" },
      },
      {
        provider = "",
        hl = { fg = "surface1", bg = "none" },
      },
    }

    local LSPActive = {
      condition = conditions.lsp_attached,
      update = { "LspAttach", "LspDetach" },

      -- You can keep it simple,
      -- provider = " [LSP]",

      -- Or complicate things a bit and get the servers names
      {
        provider = Space.provider,
      },
      {
        provider = function()
          local names = {}
          for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
            table.insert(names, server.name)
          end
          return " [" .. table.concat(names, " ") .. "]"
        end,
        hl = { fg = "text", bold = true },
      },
    }

    local Diagnostics = {
      condition = conditions.has_diagnostics,

      static = {
        error_icon = " ",
        warn_icon = " ",
        info_icon = " ",
        hint_icon = " ",
      },

      init = function(self)
        self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
      end,

      update = { "DiagnosticChanged", "BufEnter" },

      {
        provider = Space.provider,
      },
      {
        provider = Space.provider,
      },
      {
        provider = function(self)
          -- 0 is just another output, we can decide to print it or not!
          return self.errors > 0 and (self.error_icon .. self.errors .. " ")
        end,
        hl = { fg = "red" },
      },
      {
        provider = function(self)
          return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
        end,
        hl = { fg = "yellow" },
      },
      {
        provider = function(self)
          return self.info > 0 and (self.info_icon .. self.info .. " ")
        end,
        hl = { fg = "blue" },
      },
      {
        provider = function(self)
          return self.hints > 0 and (self.hint_icon .. self.hints)
        end,
        hl = { fg = "teal" },
      },
    }

    local Git = {
      condition = function()
        local repo_info = vim.b.githead_summary
        return repo_info ~= nil and repo_info.head_name ~= nil
      end,
      init = function(self)
        self.repo_info = vim.b.githead_summary
        self.changes = {
          add = vim.b.minidiff_summary and vim.b.minidiff_summary.add or 0,
          delete = vim.b.minidiff_summary and vim.b.minidiff_summary.delete or 0,
          change = vim.b.minidiff_summary and vim.b.minidiff_summary.change or 0,
        }
      end,
      {
        provider = Space.provider,
      },
      {
        provider = "",
        hl = { fg = "surface0" },
      },
      { -- git branch name
        provider = function(self)
          return " " .. self.repo_info.head_name
        end,
        hl = { bold = true, bg = "surface0", fg = "rosewater" },
      },
      -- You could handle delimiters, icons and counts similar to Diagnostics
      {
        provider = function(self)
          local count = self.changes.add or 0
          return count > 0 and ("  " .. count)
        end,
        hl = { fg = "green", bg = "surface0" },
      },
      {
        provider = function(self)
          local count = self.changes.delete or 0
          return count > 0 and ("  " .. count)
        end,
        hl = { fg = "red", bg = "surface0" },
      },
      {
        provider = function(self)
          local count = self.changes.change or 0
          return count > 0 and ("  " .. count)
        end,
        hl = { fg = "yellow", bg = "surface0" },
      },

      {
        provider = "",
        hl = { fg = "surface0" },
      },
    }

    local Warp = {}

    if warp_exists then
      Warp = {
        condition = function()
          return warp.count() > 0
        end,
        init = function(self)
          local item = warp.get_item_by_buf(0)
          self.current = item and item.index or "-"
          self.total = warp.count()
        end,
        hl = { fg = "teal", bold = true },
        {
          provider = Space.provider,
        },
        {
          provider = function(self)
            local output = {}

            if self.total > 0 then
              table.insert(output, string.format("[%s/%s]", tonumber(self.current) or "-", tonumber(self.total)))
            end

            local statusline = table.concat(output, " ")
            return string.format("󱐋 %s", statusline)
          end,
        },
      }
    end

    local HelpFileName = {
      condition = function()
        return vim.bo.filetype == "help"
      end,
      provider = function()
        local filename = vim.api.nvim_buf_get_name(0)
        return vim.fn.fnamemodify(filename, ":t")
      end,
      hl = { fg = "blue" },
    }

    local TerminalName = {
      -- we could add a condition to check that buftype == 'terminal'
      -- or we could do that later (see #conditional-statuslines below)
      provider = function()
        local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
        return " " .. tname
      end,
      hl = { fg = "blue", bold = true },
    }

    local DefaultStatusline = {
      ViMode,
      Git,
      Warp,
      Align,
      FileNameBlock,
      Diagnostics,
      Align,
      LSPActive,
      Space,
      FileTypeBlock,
      Space,
      FileSize,
      Space,
      Ruler,
    }

    local InactiveStatusline = {
      condition = conditions.is_not_active,
      FileTypeBlock,
      Space,
      FileName,
      Align,
    }

    local SpecialStatusline = {
      condition = function()
        return conditions.buffer_matches({
          buftype = { "nofile", "prompt", "help", "quickfix" },
          filetype = { "^git.*", "ministarter" },
        })
      end,

      FileTypeBlock,
      Space,
      HelpFileName,
      Align,
    }

    local TerminalStatusline = {
      condition = function()
        return conditions.buffer_matches({ buftype = { "terminal" } })
      end,

      -- Quickly add a condition to the ViMode to only show it when buffer is active!
      { condition = conditions.is_active, ViMode, Space },
      Space,
      TerminalName,
      Align,
    }

    local StatusLines = {
      hl = function()
        if conditions.is_active() then
          return "StatusLine"
        else
          return "StatusLineNC"
        end
      end,

      -- the first statusline with no condition, or which condition returns true is used.
      -- think of it as a switch case with breaks to stop fallthrough.
      fallthrough = false,

      SpecialStatusline,
      TerminalStatusline,
      InactiveStatusline,
      DefaultStatusline,
    }

    opts.opts = {
      colors = C,
    }

    opts.statusline = StatusLines
  end,
}
