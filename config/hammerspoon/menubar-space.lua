local obj = {}
local menuBar = {}

function menuBar.new()
	if menuBar.item then
		menuBar.delete()
	end
	menuBar.item = hs.menubar.new()
end

function menuBar.delete()
	if menuBar.item then
		menuBar.item:delete()
	end
	menuBar.item = nil
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
	menuBar.item:setTitle(tostring(visualNumber))
end

function obj:start()
	menuBar.new()
	setSpaceNumber()

	-- Watch for space changes
	hs.spaces.watcher
		.new(function()
			setSpaceNumber()
		end)
		:start()
end

function obj:stop()
	menuBar.delete()
end

return obj
