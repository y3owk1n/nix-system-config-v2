---@type PluginModule
local M = {}

M.name = "mini.pick"

M.requires = { "mini.extra" }

M.lazy = {
  cmd = { "Pick" },
  keys = {
    "<leader><space>",
    "<leader>sf",
    "<leader>sh",
    "<leader>sg",
    "<leader>sR",
    "<leader>sb",
    "<leader>st",
    "<leader>sH",
    "<leader>sk",
    "<leader>sd",
    "<leader>so",
    "grd",
    "grr",
    "gri",
    "grt",
    "gO",
  },
}

function M.setup()
  vim.pack.add({ "https://github.com/echasnovski/mini.pick" })

  local plugin_ok, plugin = pcall(require, "mini.pick")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    mappings = { choose_in_vsplit = "<C-v>", choose_in_split = "<C-s>" },
    window = {
      config = function()
        local height = math.floor(0.618 * vim.o.lines)
        local width = math.floor(0.618 * vim.o.columns)
        return {
          anchor = "NW",
          height = height,
          width = width,
          row = math.floor(0.5 * (vim.o.lines - height)),
          col = math.floor(0.5 * (vim.o.columns - width)),
        }
      end,
      prompt_prefix = " ",
    },
  }

  plugin.setup(plugin_opts)

  --- override vim.ui.select
  vim.ui.select = plugin.ui_select

  --- setting keymaps
  vim.keymap.set("n", "<leader><space>", function()
    plugin.builtin.files()
  end, { desc = "Find Files" })

  vim.keymap.set("n", "<leader>sf", function()
    plugin.builtin.files()
  end, { desc = "Find Files" })

  vim.keymap.set("n", "<leader>sh", function()
    plugin.builtin.help()
  end, { desc = "Help Pages" })

  vim.keymap.set("n", "<leader>sg", function()
    plugin.builtin.grep_live()
  end, { desc = "Grep" })

  vim.keymap.set("n", "<leader>sR", function()
    plugin.builtin.resume()
  end, { desc = "Resume" })

  vim.keymap.set("n", "<leader>sb", function()
    plugin.builtin.buffers()
  end, { desc = "Buffers" })

  vim.keymap.set("n", "<leader>st", function()
    local keywords = { "TODO", "FIXME", "HACK", "WARN", "PERF", "NOTE", "TEST", "BUG", "ISSUE" }

    local rg_pattern = [[\b(]] .. table.concat(keywords, "|") .. [[)\b:]]

    plugin.builtin.grep({ pattern = rg_pattern })
  end, { desc = "Todo" })

  --- setting up extra picker
  local extra_ok, extra = pcall(require, "mini.extra")

  if extra_ok then
    vim.keymap.set("n", "<leader>sH", function()
      extra.pickers.hl_groups()
    end, { desc = "Highlights" })

    vim.keymap.set("n", "<leader>sk", function()
      extra.pickers.keymaps()
    end, { desc = "Keymaps" })

    vim.keymap.set("n", "<leader>sd", function()
      extra.pickers.diagnostic()
    end, { desc = "Diagnostics" })

    vim.keymap.set("n", "<leader>so", function()
      extra.pickers.options()
    end, { desc = "Options" })

    --- lsp keymaps
    vim.keymap.set("n", "grd", function()
      extra.pickers.lsp({ scope = "definition" })
    end, { desc = "Definition" })

    vim.keymap.set("n", "grr", function()
      extra.pickers.lsp({ scope = "references" })
    end, { desc = "References" })

    vim.keymap.set("n", "gri", function()
      extra.pickers.lsp({ scope = "implementation" })
    end, { desc = "Implementation" })

    vim.keymap.set("n", "grt", function()
      extra.pickers.lsp({ scope = "type_definition" })
    end, { desc = "Type Definition" })

    vim.keymap.set("n", "gO", function()
      extra.pickers.lsp({ scope = "document_symbol" })
    end, { desc = "Document Symbols" })
  end
end

return M
