---@type PluginModule
local M = {}

M.name = "warp"

M.lazy = {
  event = { "UIEnter" },
}

function M.setup()
  vim.pack.add({ "https://github.com/y3owk1n/warp.nvim" })

  local plugin_ok, plugin = pcall(require, "warp")

  if not plugin_ok then
    return
  end

  ---@type Warp.Config
  local plugin_opts = {
    keymaps = {
      split_horizontal = { "-" },
      split_vertical = { "\\" },
    },
    window = {
      list = function(lines)
        -- get all the line widths
        local line_widths = vim.tbl_map(vim.fn.strdisplaywidth, lines)
        -- set the width te either the max width or at least 30 characters
        local max_width = math.max(math.max(unpack(line_widths)), 30)
        -- set the height to if the number of lines is less than 8 then 8
        -- otherwise the number of lines
        local max_height = #lines < 8 and 8 or math.min(#lines, vim.o.lines - 3)
        -- get the current height of the TUI
        local nvim_tui_height = vim.api.nvim_list_uis()[1]

        return {
          width = max_width,
          height = max_height,
          row = nvim_tui_height.height - max_height - 4,
          col = 0,
        }
      end,
    },
  }

  plugin.setup(plugin_opts)

  vim.schedule(function()
    vim.keymap.set("n", "<leader>h", "", { desc = "warp" })
    vim.keymap.set("n", "<leader>hm", "", { desc = "move" })
    vim.keymap.set("n", "<leader>ha", "<cmd>WarpAddFile<cr>", { desc = "[Warp] Add" })
    vim.keymap.set("n", "<leader>hA", "<cmd>WarpAddOnScreenFiles<cr>", { desc = "[Warp] Add" })
    vim.keymap.set("n", "<leader>hd", "<cmd>WarpDelFile<cr>", { desc = "[Warp] Delete" })
    vim.keymap.set("n", "<leader>he", "<cmd>WarpShowList<cr>", { desc = "[Warp] Show list" })
    vim.keymap.set("n", "<leader>hml", "<cmd>WarpMoveTo next<cr>", { desc = "[Warp] Move to next index" })
    vim.keymap.set("n", "<leader>hmh", "<cmd>WarpMoveTo prev<cr>", { desc = "[Warp] Move to prev index" })
    vim.keymap.set("n", "<leader>hmL", "<cmd>WarpMoveTo last<cr>", { desc = "[Warp] Move to last index" })
    vim.keymap.set("n", "<leader>hmH", "<cmd>WarpMoveTo first<cr>", { desc = "[Warp] Move to first index" })
    vim.keymap.set("n", "<leader>hx", "<cmd>WarpClearCurrentList<cr>", { desc = "[Warp] Clear current list" })
    vim.keymap.set("n", "<leader>hX", "<cmd>WarpClearAllList<cr>", { desc = "[Warp] Clear all lists" })
    vim.keymap.set("n", "<leader>hl", "<cmd>WarpGoToIndex next<cr>", { desc = "[Warp] Go to next index" })
    vim.keymap.set("n", "<leader>hh", "<cmd>WarpGoToIndex prev<cr>", { desc = "[Warp] Go to prev index" })
    vim.keymap.set("n", "<leader>hL", "<cmd>WarpGoToIndex first<cr>", { desc = "[Warp] Go to first index" })
    vim.keymap.set("n", "<leader>hH", "<cmd>WarpGoToIndex last<cr>", { desc = "[Warp] Go to last index" })

    for i = 1, 9 do
      vim.keymap.set("n", tostring(i), function()
        plugin.goto_index(i)
      end, { desc = "[Warp] Goto #" .. i })
    end
  end)
end

return M
