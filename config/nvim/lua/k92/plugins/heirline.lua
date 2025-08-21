---@type LazySpec
return {
  "rebelot/heirline.nvim",
  lazy = false,
  opts = function()
    local conditions = require("heirline.conditions")
    local utils = require("heirline.utils")

    local C = {
      _nc = "#1f1d30",
      base = "#232136",
      surface = "#2a273f",
      overlay = "#393552",
      muted = "#6e6a86",
      subtle = "#908caa",
      text = "#e0def4",
      love = "#eb6f92",
      gold = "#f6c177",
      rose = "#ea9a97",
      pine = "#3e8fb0",
      foam = "#9ccfd8",
      iris = "#c4a7e7",
      leaf = "#95b1ac",
      highlight_low = "#2a283e",
      highlight_med = "#44415a",
      highlight_high = "#56526e",
      none = "NONE",
    }

    require("rose-pine.palette")

    local catppuccin_exists, catppuccin = pcall(require, "rose-pine.palette")
    if catppuccin_exists then
      C = catppuccin
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
          n = "pine",
          i = "foam",
          v = "iris",
          V = "iris",
          ["\22"] = "iris",
          c = "leaf",
          s = "leaf",
          S = "leaf",
          ["\19"] = "leaf",
          R = "love",
          r = "love",
          ["!"] = "rose",
          t = "rose",
        },
      },
      {
        provider = function(self)
          return " %2(" .. self.mode_names[self.mode] .. "%) "
        end,
        hl = function(self)
          local mode = self.mode:sub(1, 1) -- get only the first mode character
          return { bg = "none", fg = "love", bold = true }
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
      hl = { fg = "love" },

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
      hl = { fg = "love", bold = true },

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
        return { fg = "love" }
      end,
    }

    local FileType = {
      provider = function()
        return string.upper(vim.bo.filetype)
      end,
      hl = { fg = "love", bold = true },
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
        -- %l = current line number
        -- %L = number of lines in the buffer
        -- %c = column number
        -- %P = percentage through file of displayed window
        provider = " %7(%l/%3L%):%2c %P ",
        hl = { fg = "love" },
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
        hl = { fg = "love", bold = true },
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
        hl = { fg = "love" },
      },
      {
        provider = function(self)
          return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
        end,
        hl = { fg = "gold" },
      },
      {
        provider = function(self)
          return self.info > 0 and (self.info_icon .. self.info .. " ")
        end,
        hl = { fg = "pine" },
      },
      {
        provider = function(self)
          return self.hints > 0 and (self.hint_icon .. self.hints)
        end,
        hl = { fg = "foam" },
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
      { -- git branch name
        provider = function(self)
          return " " .. self.repo_info.head_name
        end,
        hl = { bold = true, fg = "love" },
      },
      -- You could handle delimiters, icons and counts similar to Diagnostics
      {
        provider = function(self)
          local count = self.changes.add or 0
          return count > 0 and ("  " .. count)
        end,
        hl = { fg = "leaf" },
      },
      {
        provider = function(self)
          local count = self.changes.delete or 0
          return count > 0 and ("  " .. count)
        end,
        hl = { fg = "love" },
      },
      {
        provider = function(self)
          local count = self.changes.change or 0
          return count > 0 and ("  " .. count)
        end,
        hl = { fg = "gold" },
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
        hl = { fg = "foam", bold = true },
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
      hl = { fg = "pine" },
    }

    local TerminalName = {
      -- we could add a condition to check that buftype == 'terminal'
      -- or we could do that later (see #conditional-statuslines below)
      provider = function()
        local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
        return " " .. tname
      end,
      hl = { fg = "pine", bold = true },
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

    local opts = {
      opts = {
        colors = C,
      },
      statusline = StatusLines,
    }

    return opts
  end,
}
