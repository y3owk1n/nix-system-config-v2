local M = {
	menuBar = {},
}

function M.menuBar.new()
	if M.menuBar.item then
		M.menuBar.delete()
	end
	M.menuBar.item = hs.menubar.new()
end

function M.menuBar.delete()
	if M.menuBar.item then
		M.menuBar.item:delete()
	end
	M.menuBar.item = nil
end

local function setSpaceNumber()
	local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
	local currentID = hs.spaces.focusedSpace()
	local visualNumber

	for i, spaceID in ipairs(spaces) do
		if spaceID == currentID then
			visualNumber = i
			break
		end
	end

	-- Set the menubar item title to the visual space number
	M.menuBar.item:setTitle(tostring(visualNumber))
end

function M:start()
	M.menuBar.new()
	setSpaceNumber()

	-- Watch for space changes
	hs.spaces.watcher
		.new(function()
			setSpaceNumber()
		end)
		:start()
end

function M:stop()
	M.menuBar.delete()
end

return M
