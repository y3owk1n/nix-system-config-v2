---@type PluginModule
local M = {}

M.name = "snacks"

M.priority = 2

function M.setup()
  vim.pack.add({ "https://github.com/folke/snacks.nvim" })

  local plugin_ok, plugin = pcall(require, "snacks")

  if not plugin_ok then
    return
  end

  ---@type snacks.Config
  local plugin_opts = {
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = {
      enabled = true,
    },
    input = {
      enabled = true,
    },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    lazygit = {
      configure = false,
      config = {
        os = { editPreset = "nvim-remote" },
      },
    },
  }

  plugin.setup(plugin_opts)

  local augroup = vim.api.nvim_create_augroup("SnacksInit", { clear = true })

  ---init
  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    callback = function()
      -- Setup some globals for debugging (lazy-loaded)
      _G.dd = function(...)
        Snacks.debug.inspect(...)
      end
      _G.bt = function()
        Snacks.debug.backtrace()
      end
      vim.print = _G.dd -- Override print to use snacks for `:=` command

      -- Create some toggle mappings
      Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
      Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
      Snacks.toggle.diagnostics():map("<leader>ud")
      Snacks.toggle.line_number():map("<leader>ul")
      Snacks.toggle
        .option("conceallevel", {
          off = 0,
          on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
        })
        :map("<leader>uc")
      Snacks.toggle.inlay_hints():map("<leader>uh")
      Snacks.toggle.option("foldenable", { name = "Fold" }):map("<leader>uf")
    end,
  })

  ---notifier keymaps
  vim.keymap.set("n", "<leader>N", function()
    Snacks.notifier.show_history()
  end, { desc = "Notification History" })
  vim.keymap.set("n", "<leader>un", function()
    Snacks.notifier.hide()
  end, { desc = "Dismiss All Notifications" })

  ---rename keymaps
  vim.keymap.set("n", "<leader>cr", function()
    Snacks.rename.rename_file({
      on_rename = function(to, from)
        require("warp").on_file_update(from, to)
      end,
    })
  end, { desc = "Rename File" })

  ---git
  vim.keymap.set("n", "<leader>gb", function()
    Snacks.gitbrowse()
  end, { desc = "Git Browse" })
  vim.keymap.set("n", "<leader>gg", function()
    Snacks.lazygit()
  end, { desc = "Lazygit" })
end

return M
