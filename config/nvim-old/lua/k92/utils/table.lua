local M = {}

M.add_unique_items = function(target_table, items)
  -- Helper function to check if a value exists in the table
  local function contains(table, value)
    for _, v in ipairs(table) do
      if v == value then
        return true
      end
    end
    return false
  end

  -- Add items to the target_table only if they aren't already present
  for _, item in ipairs(items) do
    if not contains(target_table, item) then
      table.insert(target_table, item)
    end
  end
end

return M
