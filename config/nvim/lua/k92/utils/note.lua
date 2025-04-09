local M = {}

---@class k92.utils.note.config
---@field root_dir string @default "~/notes/"
---@field notes_dir_name string @default "notes"

---@class k92.utils.note.create_file_opts
---@field open? boolean @default true
---@field split? "vertical" | "horizontal" | "none" @default "none"

---@class k92.utils.note.pick
---@field type? "notes" | "todos" @default "notes"
---@field grep? boolean @default false

---@type k92.utils.note.config
local config = {
	root_dir = "~/Library/Mobile Documents/com~apple~CloudDocs/Cloud Notes/",
	notes_dir_name = "notes",
	todo_dir_name = "todo",
}

---@param opts? k92.utils.note.create_file_opts
local function merge_default_create_file_opts(opts)
	opts = opts or {}
	if opts.open == nil then
		opts.open = true
	end
	if opts.split == nil then
		opts.split = "vertical"
	end
	return opts
end

--- Format the note name to a standardized format.
--- Lowercases the name, replaces spaces with hyphens, and removes any trailing .md extension.
--- @param name string the raw note name
--- @return string formatted_note_name the formatted note name
local function format_note_name(name)
	local formatted = name:lower():gsub(" ", "-"):gsub("%.md$", "")
	return formatted
end

--- Deformat the note name to a normal sentence.
--- Replaces hyphens and underscores with spaces, and capitalizes the first letter of each word.
--- @param name string the raw note name
--- @return string deformatted_note_name the deformatted note name
local function deformat_note_name(name)
	local deformatted = name:gsub("[-_]", " "):gsub("^%l", string.upper)
	return deformatted
end

--- Generate a unique file path for the note.
--- It appends a counter suffix if a file with the same name exists.
--- @param base_path string The base directory path for the note files.
--- @param formatted_name string The note name after formatting.
--- @return string note_path The unique file path for the note.
local function get_unique_note_path(base_path, formatted_name)
	local note_path = base_path .. formatted_name .. ".md"
	if vim.fn.filereadable(note_path) == 1 then
		local counter = 1
		local new_path = ""
		repeat
			new_path = base_path .. formatted_name .. "-" .. counter .. ".md"
			counter = counter + 1
		until vim.fn.filereadable(new_path) == 0
		note_path = new_path
	end
	return note_path
end

--- Ensure that the given directory exists.
--- If the directory does not exist, it creates it.
--- @param dir string The directory path to ensure.
local function ensure_directory(dir)
	vim.fn.mkdir(dir, "p")
end

--- Write the note file with a header.
--- @param note_path string The complete file path for the note.
--- @param header string The title/header for the note file.
local function write_note_file(note_path, header)
	local dir_path = vim.fn.fnamemodify(note_path, ":p:h")
	ensure_directory(dir_path)

	vim.fn.writefile({ "# " .. header }, note_path)
end

--- Open the note file using the given options.
--- It supports vertical splits, horizontal splits, or editing in the current window.
--- @param note_path string The path of the note file.
--- @param opts k92.utils.note.create_file_opts Options containing the split mode.
local function open_note(note_path, opts)
	local cmd
	if opts.split == "vertical" then
		cmd = "vsplit"
	elseif opts.split == "horizontal" then
		cmd = "split"
	else
		cmd = "edit"
	end
	vim.cmd(string.format("%s %s", cmd, vim.fn.fnameescape(note_path)))
end

--- @param todo_dir string The todo directory.
--- @param today string|osdate Today's date in "YYYY-MM-DD" format.
--- @return string|nil source_path The path of the file from which tasks were rolled over.
local function get_previous_todo_file_from_today(todo_dir, today)
	local find_cmd = string.format([[find %s -type f -name "*.md"]], vim.fn.shellescape(todo_dir))

	local results = vim.fn.systemlist(find_cmd)
	if vim.v.shell_error ~= 0 or #results == 0 then
		return nil
	end

	-- Filter files matching the YYYY-MM-DD.md pattern and with date < today.
	local candidates = {}
	for _, file in ipairs(results) do
		local base = vim.fn.fnamemodify(file, ":t") -- get just the filename
		local y, m, d = base:match("(%d%d%d%d)%-(%d%d)%-(%d%d)%.md$")
		if y and m and d then
			local file_date = string.format("%s-%s-%s", y, m, d)
			if file_date < today then
				table.insert(candidates, { path = file, date = file_date })
			end
		end
	end

	if #candidates == 0 then
		return nil
	end

	table.sort(candidates, function(a, b)
		return a.date > b.date
	end)

	return candidates[1].path
end

--- Helper function that uses ripgrep to search for the most recent previous
--- todo file (based on YYYY-MM-DD filename) that contains unchecked tasks.
--- Unchecked tasks are identified by lines starting with "- [ ]".
--- @param todo_dir string The todo directory.
--- @param today string|osdate Today's date in "YYYY-MM-DD" format.
--- @return table|nil unchecked_tasks List of unchecked task lines, or nil if none found.
--- @return string|nil source_path The path of the file from which tasks were rolled over.
local function rollover_previous_todo_to_today(todo_dir, today)
	local previous_todo_file = get_previous_todo_file_from_today(todo_dir, today)

	if not previous_todo_file then
		return nil, nil
	end

	-- Pick the most recent candidate and read its content.
	local lines = vim.fn.readfile(previous_todo_file)
	local unchecked_tasks = {}
	local new_lines = {}

	-- Remove unchecked tasks from candidate file (lines starting with "- [ ]").
	for _, line in ipairs(lines) do
		if line:match("^%- %[%s*%]") then
			table.insert(unchecked_tasks, line)
		else
			table.insert(new_lines, line)
		end
	end

	-- Only return if there are unchecked tasks.
	if #unchecked_tasks > 0 then
		vim.fn.writefile(new_lines, previous_todo_file)
		return unchecked_tasks, previous_todo_file
	end

	return nil, nil
end

local function get_notes_dir()
	return vim.fn.expand(config.root_dir) .. config.notes_dir_name .. "/"
end

local function get_todo_dir()
	return vim.fn.expand(config.root_dir) .. config.todo_dir_name .. "/"
end

---@param opts k92.utils.note.pick
local function get_picker_dirs(opts)
	local dirs = {}
	if opts.type == "notes" then
		table.insert(dirs, get_notes_dir())
	elseif opts.type == "todos" then
		table.insert(dirs, get_todo_dir())
	end
	return dirs
end

---@param str string
local function is_path_like(str)
	-- Check for slashes or drive letters
	if str:find("[/\\]") or str:match("^%a:[/\\]") then
		return true
	end

	-- Check for common path prefixes
	if str:match("^%.?/") or str:match("^~") then
		return true
	end

	-- Check if it ends with a file extension
	if str:match("%.%w+$") then
		return true
	end

	return false
end

---@param opts? k92.utils.note.create_file_opts
function M.create_note_file(opts)
	opts = merge_default_create_file_opts(opts)

	local base_path = get_notes_dir()
	ensure_directory(base_path)

	-- show an input prompt to the user for a note name
	vim.ui.input({
		prompt = "Note name/path: ",
		default = "",
	}, function(name_or_path)
		if not name_or_path or name_or_path == "" then
			return
		end

		local formatted_name = format_note_name(name_or_path)
		local note_path = get_unique_note_path(base_path, formatted_name)

		if is_path_like(name_or_path) then
			local filename = vim.fn.fnamemodify(name_or_path, ":t")
			name_or_path = deformat_note_name(filename)
		end
		write_note_file(note_path, name_or_path)

		if opts.open then
			open_note(note_path, opts)
		end
	end)
end

--- Create (if necessary) and open a todo file for today.
--- The filename is generated from today's date in "YYYY-MM-DD.md" format.
---@param opts? k92.utils.note.create_file_opts
function M.todo_today(opts)
	opts = merge_default_create_file_opts(opts)

	local todo_dir = get_todo_dir()
	ensure_directory(todo_dir)

	-- Generate today's timestamp using the format "YYYY-MM-DD"
	local today = os.date("%Y-%m-%d")
	local todo_path = todo_dir .. today .. ".md"

	-- If the file doesn't exist, create it and add a header.
	if vim.fn.filereadable(todo_path) == 0 then
		write_note_file(todo_path, "Todo for " .. today)

		-- Only rollover if the file is newly created.
		-- Rollover unchecked tasks from the most recent previous todo file.
		local unchecked_tasks = rollover_previous_todo_to_today(todo_dir, today)
		if unchecked_tasks then
			local today_lines = vim.fn.readfile(todo_path)
			-- Append a blank line if needed.
			if #today_lines > 0 and today_lines[#today_lines] ~= "" then
				table.insert(today_lines, "")
			end
			for _, line in ipairs(unchecked_tasks) do
				table.insert(today_lines, line)
			end
			vim.fn.writefile(today_lines, todo_path)
			vim.notify(string.format("Rolled over %d unchecked todo(s)", #unchecked_tasks))
		else
			vim.notify("No unchecked todos to rollover from previous days.", vim.log.levels.INFO)
		end
	end

	if opts.open then
		open_note(todo_path, opts)
	end
end

---@param opts? k92.utils.note.create_file_opts
function M.inbox(opts)
	opts = merge_default_create_file_opts(opts)

	local inbox_dir = vim.fn.expand(config.root_dir)
	ensure_directory(inbox_dir)

	local inbox_name = "inbox.md"
	local inbox_path = inbox_dir .. inbox_name

	-- If the file doesn't exist, create it and add a header.
	if vim.fn.filereadable(inbox_path) == 0 then
		write_note_file(inbox_path, "Inbox")
	end

	if opts.open then
		open_note(inbox_path, opts)
	end
end

---@param opts? k92.utils.note.pick
function M.pick(opts)
	if opts == nil then
		opts = {}
	end
	opts.type = opts.type or "notes"
	opts.grep = opts.grep or false

	local dirs = get_picker_dirs(opts)

	if opts.grep then
		Snacks.picker.grep({
			dirs = dirs,
		})
	else
		Snacks.picker.files({
			dirs = dirs,
		})
	end
end

return M
