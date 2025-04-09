local M = {}

---@class k92.utils.note.config
---@field root_dir? string @default "~/notes/"
---@field default_split? "vertical" | "horizontal" | "none" @default "vertical"
---@field dir_names? k92.utils.note.config.dir_names
---@field templates? k92.utils.note.config.templates

---@alias k92.utils.note.config.dir_name_key "notes" | "todo" | "journal"

---@class k92.utils.note.config.dir_names
---@field notes? string @default "notes"
---@field todo? string @default "todo"
---@field journal? string @default "journal"

---@class k92.utils.note.config.templates
---@field notes? fun(name: string): string[]
---@field todo? fun(date: string): string[]
---@field journal? fun(date: string): string[]
---@field inbox? fun(date: string): string[]

---@class k92.utils.note.create_file_opts
---@field open? boolean @default true
---@field split? "vertical" | "horizontal" | "none" @default config.default_split

---@class k92.utils.note.pick
---@field type? "notes" | "todos" | "journal" | "all" @default "notes"
---@field grep? boolean @default false

---@type k92.utils.note.config
local config = {
	root_dir = "~/Library/Mobile Documents/com~apple~CloudDocs/Cloud Notes/",
	default_split = "vertical",
	dir_names = {
		notes = "notes",
		todo = "todo",
		journal = "journal",
	},
	templates = {
		notes = function(title)
			return {
				"---",
				"title: " .. title,
				"created: " .. os.date("%Y-%m-%d %H:%M"),
				"---",
				"",
				"# " .. title,
				"",
			}
		end,
		todo = function(date)
			return {
				"---",
				"type: todo",
				"date: " .. date,
				"---",
				"",
				"# Todo for " .. date,
				"",
				"## Tasks",
				"",
			}
		end,
		journal = function(date)
			return {
				"---",
				"type: journal",
				"date: " .. date,
				"---",
				"",
				"# Journal Entry for " .. date,
				"",
				"## Highlights",
				"",
				"## Thoughts",
				"",
				"## Tasks",
				"",
			}
		end,
		inbox = function()
			return {
				"---",
				"type: inbox",
				"---",
				"",
				"# Inbox",
				"",
				"## Quick Notes",
				"",
				"## Tasks",
				"",
				"## References",
				"",
			}
		end,
	},
}

-- UTILITY FUNCTIONS --

local function merge_default_create_file_opts(opts)
	opts = opts or {}
	opts.open = opts.open ~= false
	opts.split = opts.split or config.default_split or "vertical"
	return opts
end

local function sanitize_filename(name)
	return name:gsub('[<>:"/\\|?*]', "-")
end

local function format_note_name(name)
	local formatted = name:lower():gsub(" ", "-"):gsub("%.md$", "")
	return sanitize_filename(formatted)
end

local function deformat_note_name(name)
	local deformatted = name:gsub("[-_]", " "):gsub("^%l", string.upper)
	return deformatted
end

local function ensure_directory(dir)
	vim.fn.mkdir(dir, "p")
end

local function safe_writefile(content, path)
	local ok, err = pcall(vim.fn.writefile, content, path)
	if not ok then
		vim.notify("Error writing file: " .. err, vim.log.levels.ERROR)
		return false
	end
	return true
end

local function is_path_like(str)
	return str:find("[/\\]") or str:match("^%a:[/\\]") or str:match("^%.?/") or str:match("^~") or str:match("%.%w+$")
end

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

local function open_note(note_path, opts)
	local cmd = ({
		vertical = "vsplit",
		horizontal = "split",
		none = "edit",
	})[opts.split] or "edit"

	vim.cmd(string.format("%s %s", cmd, vim.fn.fnameescape(note_path)))
end

local function write_note_file(note_path, header, template_func)
	local dir_path = vim.fn.fnamemodify(note_path, ":p:h")
	ensure_directory(dir_path)

	local content = template_func and template_func(header) or { "# " .. header }
	safe_writefile(content, note_path)
end

-- DIRECTORY FUNCTIONS --

---@param subdir_name k92.utils.note.config.dir_name_key
---@return string
local function get_subdir(subdir_name)
	return vim.fn.expand(config.root_dir) .. config.dir_names[subdir_name] .. "/"
end

local function get_notes_dir()
	return get_subdir("notes")
end

local function get_todo_dir()
	return get_subdir("todo")
end

local function get_journal_dir()
	return get_subdir("journal")
end

---@param opts k92.utils.note.pick
local function get_picker_dirs(opts)
	local dirs = {}
	if opts.type == "all" then
		table.insert(dirs, get_notes_dir())
		table.insert(dirs, get_todo_dir())
		table.insert(dirs, get_journal_dir())
	elseif opts.type == "notes" then
		table.insert(dirs, get_notes_dir())
	elseif opts.type == "todos" then
		table.insert(dirs, get_todo_dir())
	elseif opts.type == "journal" then
		table.insert(dirs, get_journal_dir())
	end
	return dirs
end

-- TODO FUNCTIONS --

---@param todo_dir string
---@param today string|osdate
---@return string|nil path
local function get_previous_todo_file_from_today(todo_dir, today)
	local find_cmd = string.format([[find %s -type f -name "*.md"]], vim.fn.shellescape(todo_dir))
	local results = vim.fn.systemlist(find_cmd)
	if vim.v.shell_error ~= 0 or #results == 0 then
		return nil
	end

	local candidates = {}
	for _, file in ipairs(results) do
		local base = vim.fn.fnamemodify(file, ":t")
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

---@param todo_dir string
---@param today string|osdate
---@return string[]|nil, string|nil
local function rollover_previous_todo_to_today(todo_dir, today)
	local previous_todo_file = get_previous_todo_file_from_today(todo_dir, today)
	if not previous_todo_file then
		return nil, nil
	end

	local lines = vim.fn.readfile(previous_todo_file)
	local unchecked_tasks = {}
	local new_lines = {}

	-- Find the tasks section
	local in_tasks = false
	for _, line in ipairs(lines) do
		if line:match("^##%s+Tasks") then
			in_tasks = true
			table.insert(new_lines, line)
		elseif in_tasks and line:match("^##") then
			in_tasks = false
			table.insert(new_lines, line)
		elseif in_tasks then
			if line:match("^%- %[%s*%]") then
				table.insert(unchecked_tasks, line)
			else
				table.insert(new_lines, line)
			end
		else
			table.insert(new_lines, line)
		end
	end

	if #unchecked_tasks > 0 then
		safe_writefile(new_lines, previous_todo_file)
		return unchecked_tasks, previous_todo_file
	end

	return nil, nil
end

-- PUBLIC FUNCTIONS --

---@param opts? k92.utils.note.create_file_opts
function M.create_note_file(opts)
	opts = merge_default_create_file_opts(opts)

	vim.ui.input({
		prompt = "Note name/path: ",
		default = "",
	}, function(name_or_path)
		if not name_or_path or name_or_path == "" then
			return
		end

		local base_path = get_notes_dir()
		local subdir = vim.fn.fnamemodify(name_or_path, ":h")
		local filename = vim.fn.fnamemodify(name_or_path, ":t")

		if subdir ~= "." then
			base_path = base_path .. subdir .. "/"
			ensure_directory(base_path)
		end

		local formatted_name = format_note_name(filename)
		local note_path = get_unique_note_path(base_path, formatted_name)
		local display_name = is_path_like(name_or_path) and deformat_note_name(filename) or name_or_path

		write_note_file(note_path, display_name, config.templates.notes)

		if opts.open then
			open_note(note_path, opts)
		end
	end)
end

---@param opts? k92.utils.note.create_file_opts
function M.todo_today(opts)
	opts = merge_default_create_file_opts(opts)
	local todo_dir = get_todo_dir()
	ensure_directory(todo_dir)

	local today = os.date("%Y-%m-%d")
	local todo_path = todo_dir .. today .. ".md"

	if vim.fn.filereadable(todo_path) == 0 then
		write_note_file(todo_path, "Todo for " .. today, config.templates.todo)

		local unchecked_tasks, source_path = rollover_previous_todo_to_today(todo_dir, today)
		if unchecked_tasks and source_path then
			local today_lines = vim.fn.readfile(todo_path)
			if #today_lines > 0 and today_lines[#today_lines] ~= "" then
				table.insert(today_lines, "")
			end
			vim.list_extend(today_lines, unchecked_tasks)
			safe_writefile(today_lines, todo_path)
			vim.notify(
				string.format(
					"Rolled over %d unchecked todo(s) from %s",
					#unchecked_tasks,
					vim.fn.fnamemodify(source_path, ":t")
				)
			)
		end
	end

	if opts.open then
		open_note(todo_path, opts)
	end
end

---@param opts? k92.utils.note.create_file_opts
function M.journal_entry(opts)
	opts = merge_default_create_file_opts(opts)
	local journal_dir = get_journal_dir()
	ensure_directory(journal_dir)

	local today = os.date("%Y-%m-%d")
	local journal_path = journal_dir .. today .. ".md"

	if vim.fn.filereadable(journal_path) == 0 then
		write_note_file(journal_path, "Journal Entry for " .. today, config.templates.journal)
	end

	if opts.open then
		open_note(journal_path, opts)
	end
end

---@param opts? k92.utils.note.create_file_opts
function M.inbox(opts)
	opts = merge_default_create_file_opts(opts)
	local inbox_path = vim.fn.expand(config.root_dir) .. "inbox.md"

	if vim.fn.filereadable(inbox_path) == 0 then
		write_note_file(inbox_path, "Inbox", config.templates.inbox)
	end

	if opts.open then
		open_note(inbox_path, opts)
	end
end

---@param opts? k92.utils.note.pick
function M.pick(opts)
	opts = opts or {}
	opts.type = opts.type or "notes"
	opts.grep = opts.grep or false

	local dirs = get_picker_dirs(opts)

	local prompt_name_type = opts.type == "all" and " " or " " .. opts.type .. " "
	local prompt_prefix = opts.grep and "Grep for" or "Pick a"
	local prompt = prompt_prefix .. prompt_name_type .. ": "

	-- Use snacks picker if exists
	local snacks_ok, snacks = pcall(require, "snacks")
	if snacks_ok and snacks and snacks.picker then
		if opts.grep then
			snacks.picker.grep({ dirs = dirs, prompt = prompt })
		else
			snacks.picker.files({ dirs = dirs, prompt = prompt })
		end
		return
	end

	-- else use vim.ui.select
	local function get_files_recursive(directory)
		local files = {}
		local scan = vim.fn.readdir(directory)
		for _, entry in ipairs(scan) do
			local full_path = directory .. entry
			if vim.fn.isdirectory(full_path) == 1 then
				vim.list_extend(files, get_files_recursive(full_path .. "/"))
			elseif entry:match("%.md$") then
				table.insert(files, full_path)
			end
		end
		return files
	end

	local function prepare_items()
		local items = {}
		for _, dir in ipairs(dirs) do
			vim.list_extend(items, get_files_recursive(dir))
		end

		-- Convert to display format
		return vim.tbl_map(function(path)
			local display_path = path:gsub(vim.fn.expand(config.root_dir), "")
			return {
				value = path,
				display = display_path,
			}
		end, items)
	end

	local function fuzzy_filter(query, items)
		query = query:lower()
		return vim.tbl_filter(function(item)
			return item.display:lower():find(query, 1, true) ~= nil
		end, items)
	end

	local items = prepare_items()
	if #items == 0 then
		vim.notify("No" .. prompt_name_type .. "files found in specified directories", vim.log.levels.WARN)
		return
	end

	vim.ui.select(items, {
		prompt = prompt,
		format_item = function(item)
			return item.display
		end,
		kind = "note",
		fuzzy = true,
		filter = fuzzy_filter,
	}, function(selected)
		if selected then
			vim.cmd("edit " .. vim.fn.fnameescape(selected.value))
		end
	end)
end

---Navigate to previous/next todo file
---@param direction "previous"|"next"
function M.todo_navigate(direction)
	local todo_dir = get_todo_dir()
	local current_file = vim.fn.expand("%:t")
	local current_date = current_file:match("^(%d%d%d%d%-%d%d%-%d%d)%.md$")

	local target_date
	if current_date then
		local days = direction == "previous" and -1 or 1
		target_date = os.date(
			"%Y-%m-%d",
			os.time({
				year = current_date:sub(1, 4),
				month = current_date:sub(6, 7),
				day = current_date:sub(9, 10) + days,
			})
		)
	else
		target_date = os.date("%Y-%m-%d")
	end

	local target_file = todo_dir .. target_date .. ".md"
	if vim.fn.filereadable(target_file) == 1 then
		vim.cmd("edit " .. vim.fn.fnameescape(target_file))
	else
		vim.notify("No todo file found for " .. target_date, vim.log.levels.INFO)
	end
end

return M
