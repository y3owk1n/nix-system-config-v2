---Create an augroup
---@param name string
---@return integer
local function augroup(name)
  return vim.api.nvim_create_augroup("k92_" .. name, { clear = false })
end

-- =========================================================
--  Start Treesitter
-- =========================================================

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("treesitter"),
  callback = function(args)
    if not vim.treesitter.highlighter.active[args.buf] then
      pcall(vim.treesitter.start)
    end
  end,
})

-- =========================================================
--  Lsp progress notification
--  This uses primitives from my notifier plugin
--  Won't work on vanilla vim.notify
-- =========================================================

local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_index = 1

vim.api.nvim_create_autocmd("LspProgress", {
  group = augroup("lsp_progress"),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    local value = ev.data.params.value
    local token = ev.data.token
    local is_complete = value.kind == "end"

    if not value then
      return
    end

    local client_name = client.name

    local function get_right_percentage(percentage)
      if percentage == 0 or percentage == nil then
        return nil
      end
      return percentage
    end

    local progress_data = {
      percentage = get_right_percentage(value.percentage),
      description = value.title or "Loading workspace",
      file_progress = value.message or nil,
    }

    if is_complete then
      progress_data.description = "Done"
      progress_data.file_progress = nil
      progress_data.percentage = 100
    end

    spinner_index = (spinner_index % #spinner) + 1

    local icon
    if is_complete then
      icon = " "
    else
      icon = spinner[spinner_index]
    end

    vim.notify("", vim.log.levels.INFO, {
      id = string.format("lsp_progress_%s_%s", client_name, token),
      title = client_name,
      _notif_formatter = function(opts)
        local notif = opts.notif
        local _notif_formatter_data = notif._notif_formatter_data

        if not _notif_formatter_data then
          return {}
        end

        local separator = { display_text = " " }

        local icon_hl = notif.hl_group or opts.log_level_map[notif.level].hl_group

        local percent_text = _notif_formatter_data.percentage
            and string.format("%3d%%", _notif_formatter_data.percentage)
          or nil

        local description_text = _notif_formatter_data.description

        local file_progress_text = _notif_formatter_data.file_progress or nil

        local entries = {}

        if icon then
          table.insert(entries, { display_text = icon, hl_group = icon_hl })
          table.insert(entries, separator)
        end

        if percent_text then
          table.insert(entries, { display_text = percent_text, hl_group = "Normal" })
          table.insert(entries, separator)
        end

        table.insert(entries, { display_text = description_text, hl_group = "Comment" })

        if file_progress_text then
          table.insert(entries, separator)
          table.insert(entries, { display_text = file_progress_text, hl_group = "Removed" })
        end

        if client_name then
          table.insert(entries, separator)
          table.insert(entries, { display_text = client_name, hl_group = "ErrorMsg" })
        end

        return entries
      end,
      _notif_formatter_data = progress_data,
    })
  end,
})

-- =========================================================
--  LSP attached with actions
-- =========================================================

local icons = require("mini.icons")

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("lsp"),
  callback = function(args)
    local bufnr = args.buf

    vim.opt_local.signcolumn = "yes:1"

    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if not client then
      return
    end

    if client:supports_method("textDocument/completion") then
      vim.opt_local.complete = ".,w,b,u"
      vim.opt_local.completeopt = "menu,menuone,popup,noinsert,noselect,fuzzy"
      vim.opt_local.pumheight = 15
      vim.opt_local.pumblend = 5

      local provider = client.server_capabilities.completionProvider
      if provider then
        local triggers = vim.deepcopy(provider.triggerCharacters or {})
        local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"

        for i = 1, #chars do
          local c = chars:sub(i, i)
          if not vim.tbl_contains(triggers, c) then
            table.insert(triggers, c)
          end
        end

        provider.triggerCharacters = triggers
      end

      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
        convert = function(item)
          local kinds = vim.lsp.protocol.CompletionItemKind
          local kind_name = kinds[item.kind] or "Text"

          local icon, hl = icons.get("lsp", kind_name)

          local label = item.label:gsub("^%s+", ""):gsub("%s+$", "")

          local deprecated = item.deprecated
            or vim.tbl_contains(item.tags or {}, vim.lsp.protocol.CompletionTag.Deprecated)
          if deprecated then
            label = "~~" .. label .. "~~"
          end

          return {
            abbr = icon .. " " .. label,
            abbr_hlgroup = hl,
            kind = "",
            menu = item.labelDetails and vim
              .iter({
                item.labelDetails.detail,
                item.labelDetails.description,
              })
              :filter(function(s)
                return s and s ~= ""
              end)
              :join(" ") or "",
          }
        end,
      })

      -- retrigger on backspace (deduped per buffer)
      local group = vim.api.nvim_create_augroup("lsp_completion_" .. bufnr, { clear = true })

      vim.api.nvim_create_autocmd("TextChangedI", {
        group = group,
        buffer = bufnr,
        callback = function()
          if vim.fn.pumvisible() == 1 then
            return
          end

          local col = vim.api.nvim_win_get_cursor(0)[2]
          local before = vim.api.nvim_get_current_line():sub(1, col)

          if before:match("[%w_]$") then
            vim.lsp.completion.get()
          end
        end,
      })
    end

    -- rename filename
    vim.keymap.set("n", "<leader>cr", function()
      require("custom.lsp-rename").rename_file()
    end, { buffer = bufnr, desc = "Rename file" })

    -- lsp thingy (the rest are already included by neovim default)
    vim.keymap.set("n", "grd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })

    -- map <CR> to select completion item
    -- because <C-y> is mapped for accept supermaven completion......
    -- this can be removed when we no longer use supermaven
    -- supermaven default is <Tab> to accept, but it causes issue on inline typing where we can't use <Tab> to indent anymore...
    vim.keymap.set("i", "<CR>", function()
      return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
    end, { buffer = bufnr, expr = true })
  end,
})

-- =========================================================
--  Yank highlight
-- =========================================================

-- we are using undo-glow for highlight

-- vim.api.nvim_create_autocmd("TextYankPost", {
--   group = augroup("text_yank_post"),
--   callback = function()
--     vim.hl.on_yank()
--   end,
-- })

-- =========================================================
--  Close quickfix window on enter
-- =========================================================

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("file_type_qf"),
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR><cmd>cclose<CR>", { buffer = true })
  end,
})

-- =========================================================
--  Close with q key
-- =========================================================

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "checkhealth",
    "dbout",
    "grug-far",
    "help",
    "qf",
    "startuptime",
    "tsplayground",
    "mininotify-history",
    "lspinfo",
    "lsplog",
    "lintinfo",
    "cmd",
    "nvim-pack",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false

    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
      end, { buffer = event.buf, silent = true })
    end)
  end,
})

-- =========================================================
--  Trim whitespace on save
-- =========================================================

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("remove_whitespace_on_save"),
  callback = function()
    local view = vim.fn.winsaveview()

    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- =========================================================
--  Disable auto commenting new lines
-- =========================================================

vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("no_auto_commeting_new_lines"),
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- =========================================================
--  Auto reload when file changed
-- =========================================================

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.bo.buftype == "" then
      vim.cmd("checktime")
    end
  end,
})

-- =========================================================
--  Resize splits
-- =========================================================

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- =========================================================
--  Move help to the right split
-- =========================================================

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("split_help_right"),
  pattern = "help",
  command = "wincmd L",
})

-- =========================================================
--  Do something when vim.pack updates
-- =========================================================

vim.api.nvim_create_autocmd("PackChanged", {
  group = augroup("pack_changed"),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind

    -- run TSUpdate when nvim-treesitter is updated
    if name == "nvim-treesitter" and kind == "update" then
      pcall(function()
        vim.cmd("TSUpdate")
      end)
    end
  end,
})
