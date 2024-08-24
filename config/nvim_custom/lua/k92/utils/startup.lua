local M = {}

M.show_startuptime = function()
	---@diagnostic disable-next-line: different-requires
	local stats = require("lazy").stats()
	local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
	return ("⚡ " .. stats.loaded .. "/" .. stats.count .. " (" .. ms .. "ms)")
end

return M
