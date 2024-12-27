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
	-- Get the current focused space
	local spaceNumber = hs.spaces.focusedSpace()

	-- Set the menubar item title to the space number
	menuBar.item:setTitle(tostring(spaceNumber))
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
