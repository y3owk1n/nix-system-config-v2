local M = {}

local function get_index(t, value)
	for k, v in pairs(t) do
		if v.value == value then
			return k
		end
	end
	return nil
end

M.show_harpoon_component = function()
	local harpoon = require("harpoon")
	local current_file_path =
		require("k92.utils.file").current_file_path_relative()

	local total_marks = harpoon:list():length()

	if total_marks == 0 then
		return ""
	end

	local current_mark = "—"

	local mark_idx = get_index(harpoon:list().items, current_file_path)
	if mark_idx ~= nil then
		current_mark = tostring(mark_idx)
	end

	return string.format("󱡅 %s/%d", current_mark, total_marks)
end

return M
