-- This module is to spawn a neovim editor for text inputs using secondary terminal

-- Configuration
local config = {
	padding = 20,
	temp_file = os.tmpname(),
	nvim_path = "/etc/profiles/per-user/kylewong/bin/nvim",
	alacritty_cli = "/etc/profiles/per-user/kylewong/bin/alacritty",
	debug = false,
	valid_roles = {
		"AXTextField",
		"AXTextArea",
		"AXComboBox",
		"AXSearchField",
		"AXTextView",
	},
	excluded_apps = { -- Bundle IDs
		"com.apple.Terminal",
		"com.mitchellh.ghostty",
		"org.alacritty",
		"net.kovidgoyal.kitty",
	},
}

-- Debug logging
local function log(msg)
	if config.debug then
		print("[Alacritty Edit] " .. msg)
	end
end

-- Get focused element
local function getFocusedElement()
	local focused = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
	if not focused then
		log("No focused element")
		return nil
	end

	local role = focused:attributeValue("AXRole")
	if not role or not hs.fnutils.contains(config.valid_roles, role) then
		log("Not a text input (Role: " .. (role or "nil") .. ")")
		return nil
	end

	local frame = focused:attributeValue("AXFrame")
	local text = focused:attributeValue("AXValue") or ""
	if not frame then
		log("Element has no frame")
		return nil
	end

	return { element = focused, frame = frame, text = text }
end

local function launchNeovim(bounds, initialText)
	os.remove(config.temp_file)

	local file = io.open(config.temp_file, "w")
	if not file then
		log("Failed to create temp file")
		return
	end
	file:write(initialText)
	file:close()

	-- Launch Alacritty using task with proper cleanup
	local nvim = hs.task.new("/bin/sh", function(exitCode)
		hs.timer.doAfter(2, function() -- Increased cleanup delay
			os.remove(config.temp_file)
			log("Cleanup complete")
		end)
	end, { "-c", config.alacritty_cli .. " -e " .. config.nvim_path .. " " .. config.temp_file })
	nvim:start()

	-- Fixed window positioning with proper finder scoping
	local retries = 0
	local finder
	finder = hs.timer.doEvery(0.3, function()
		local win = hs.window.find("Alacritty")
		if win then
			finder:stop() -- Now properly referenced
			win:moveToUnit({
				x = (bounds.x - win:screen():frame().x) / win:screen():frame().w,
				y = (bounds.y - win:screen():frame().y) / win:screen():frame().h,
				w = bounds.w / win:screen():frame().w,
				h = bounds.h / win:screen():frame().h,
			})
			win:focus()
			log("Alacritty positioned")
		elseif retries > 10 then
			if finder then
				finder:stop()
			end
			log("Window not found")
		end
		retries = retries + 1
	end)
end

-- Watch for file changes with existence check
local function watchForChanges(focusedElement)
	local watcher = hs.pathwatcher.new(config.temp_file, function()
		-- Check if file still exists
		if not hs.fs.attributes(config.temp_file) then
			return
		end

		local file = io.open(config.temp_file, "r")
		if not file then
			return
		end
		local content = file:read("*a")
		file:close()
		focusedElement.element:setAttributeValue("AXValue", content)
		log("Changes synced")
	end)
	watcher:start()
	return watcher
end

-- Main function
local function editInNeovim()
	local current_app = hs.application.frontmostApplication():bundleID()
	if hs.fnutils.contains(config.excluded_apps, current_app) then
		hs.alert("Skipping - current app is excluded: " .. current_app)
		return
	end

	local focused = getFocusedElement()
	if not focused or not focused.frame then
		hs.alert("Not a valid text input")
		return
	end

	-- Calculate bounds relative to screen
	local screen = hs.screen.mainScreen():frame()
	local bounds = {
		x = focused.frame.x - config.padding,
		y = focused.frame.y - config.padding,
		w = focused.frame.w + (config.padding * 2),
		h = focused.frame.h + (config.padding * 2),
	}

	-- Ensure bounds stay on screen
	bounds.x = math.max(screen.x, math.min(bounds.x, screen.x + screen.w - bounds.w))
	bounds.y = math.max(screen.y, math.min(bounds.y, screen.y + screen.h - bounds.h))

	launchNeovim(bounds, focused.text)
	watchForChanges(focused)
	log('Editing in Neovim - Save with ":w"')
end

-- Bind to hotkey
hs.hotkey.bind({ "cmd", "ctrl" }, "e", editInNeovim)
