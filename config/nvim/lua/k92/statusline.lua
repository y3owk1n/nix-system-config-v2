local api = vim.api
local fn = vim.fn
local diagnostic = vim.diagnostic
local bo = vim.bo
local cmd = vim.cmd

local function try_require(module)
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local config = {
	icons = {
		git = {
			added = " ",
			changed = " ",
			removed = " ",
		},
		diagnostics = {
			error = " ",
			warn = " ",
			info = " ",
			hint = " ",
		},
		separator = "| ",
	},
}

local function setup_colors()
	local catppuccin = try_require("catppuccin.palettes")
	if not catppuccin then
		vim.notify("Catppuccin colorscheme not found", vim.log.levels.WARN)
		return
	end

	local colors = catppuccin.get_palette()

	local highlights = {
		-- Mode colors
		{ "StatuslineAccent", colors.lavender, colors.crust },
		{ "StatuslineInsertAccent", colors.base, colors.green },
		{ "StatuslineVisualAccent", colors.base, colors.mauve },
		{ "StatuslineReplaceAccent", colors.base, colors.red },
		{ "StatuslineCmdLineAccent", colors.base, colors.peach },
		{ "StatuslineTerminalAccent", colors.base, colors.teal },

		-- Git colors
		{ "GitSignsAccent", nil, colors.surface0 },
		{ "GitSignsAdd", colors.green, colors.surface0 },
		{ "GitSignsChange", colors.yellow, colors.surface0 },
		{ "GitSignsDelete", colors.red, colors.surface0 },

		-- LSP colors
		{ "LspDiagnosticsSignError", colors.red, nil },
		{ "LspDiagnosticsSignWarn", colors.yellow, nil },
		{ "LspDiagnosticsSignInfo", colors.sky, nil },
		{ "LspDiagnosticsSignHint", colors.teal, nil },

		-- Statusline backgrounds
		{ "StatusLine", nil, colors.mantle },
		{ "StatusLineNC", nil, nil },
		{ "StatusLineExtra", colors.subtext1, colors.surface0 },

		-- Grapple colors
		{ "GrappleStatusLine", colors.flamingo, nil },
	}

	for _, hl in ipairs(highlights) do
		local name, fg, bg = unpack(hl)
		api.nvim_set_hl(0, name, { fg = fg, bg = bg })
	end
end

local modes = {
	["n"] = "NORMAL",
	["no"] = "NORMAL",
	["v"] = "VISUAL",
	["V"] = "VISUAL LINE",
	[""] = "VISUAL BLOCK",
	["s"] = "SELECT",
	["S"] = "SELECT LINE",
	[""] = "SELECT BLOCK",
	["i"] = "INSERT",
	["ic"] = "INSERT",
	["R"] = "REPLACE",
	["Rv"] = "VISUAL REPLACE",
	["c"] = "COMMAND",
	["cv"] = "VIM EX",
	["ce"] = "EX",
	["r"] = "PROMPT",
	["rm"] = "MOAR",
	["r?"] = "CONFIRM",
	["!"] = "SHELL",
	["t"] = "TERMINAL",
}

local mode_colors = {
	n = "StatuslineAccent",
	i = "StatuslineInsertAccent",
	v = "StatuslineVisualAccent",
	V = "StatuslineVisualAccent",
	[""] = "StatuslineVisualAccent",
	R = "StatuslineReplaceAccent",
	c = "StatuslineCmdLineAccent",
	t = "StatuslineTerminalAccent",
}

local components = {
	mode = function()
		local current_mode = api.nvim_get_mode().mode
		return string.format(" %s ", modes[current_mode]):upper()
	end,

	mode_color = function()
		local current_mode = api.nvim_get_mode().mode
		return "%#" .. (mode_colors[current_mode] or "StatuslineAccent") .. "#"
	end,

	filepath = function()
		local cwd = fn.fnamemodify(fn.getcwd(), ":~")
		local fpath = fn.fnamemodify(fn.expand("%"), ":~:.:h")
		if fpath == "" or fpath == "." then
			return string.format(" %s/", cwd)
		end

		-- Split the file path into components
		local path_components = vim.split(fpath, "/", { plain = true })

		-- Determine whether to add "..."
		local path_depth = #path_components
		local display_path

		if path_depth > 1 then
			display_path = "~/" .. path_components[path_depth]
		else
			display_path = path_components[1]
		end

		return string.format("%s/%s/", cwd, display_path)
	end,

	filename = function()
		local fname = fn.expand("%:t")
		if fname == "" then
			return ""
		end
		return fname .. " "
	end,

	filesize = function()
		local size = fn.getfsize(fn.expand("%:p"))
		if size <= 0 then
			return ""
		end

		local suffixes = { "b", "k", "m", "g" }
		local i = 1
		while size > 1024 and i < #suffixes do
			size = size / 1024
			i = i + 1
		end
		return string.format(" %.1f%s ", size, suffixes[i])
	end,

	filetype = function()
		local icon = ""
		local devicons = try_require("nvim-web-devicons")
		if devicons then
			icon = devicons.get_icon(fn.expand("%:t"), bo.filetype) or ""
			icon = icon .. " "
		end
		return string.format(" %s%s ", icon, bo.filetype):upper()
	end,

	file_format = function()
		local enc = bo.fileencoding or "utf-8"
		local fmt = bo.fileformat == "unix" and "LF" or "CRLF"
		return string.format(" %s %s ", enc:upper(), fmt)
	end,

	lineinfo = function()
		return " %P  %l:%c "
	end,

	read_only = function()
		if bo.readonly then
			return ""
		end
		if bo.modifiable == false then
			return ""
		end
		if bo.modified then
			return ""
		end
		return ""
	end,

	diagnostics = function()
		local severities = {
			{ "error", diagnostic.severity.ERROR, config.icons.diagnostics.error },
			{ "warn", diagnostic.severity.WARN, config.icons.diagnostics.warn },
			{ "info", diagnostic.severity.INFO, config.icons.diagnostics.info },
			{ "hint", diagnostic.severity.HINT, config.icons.diagnostics.hint },
		}

		local diagnostics = {}
		for _, severity in pairs(severities) do
			local level, level_num, icon = unpack(severity)
			local count = #diagnostic.get(0, { severity = level_num })

			if count > 0 then
				table.insert(
					diagnostics,
					string.format(" %%#LspDiagnosticsSign%s#%s%d", level:sub(1, 1):upper() .. level:sub(2), icon, count)
				)
			end
		end

		if #diagnostics > 0 then
			return table.concat(diagnostics) .. "%#Normal#" .. " "
		end

		return ""
	end,

	lsp = function()
		local clients = vim.lsp.get_clients({ bufnr = 0 })
		if #clients > 0 then
			return " "
				.. table.concat(
					vim.tbl_map(function(client)
						return client.name:upper()
					end, clients),
					","
				)
				.. " "
		end
		return ""
	end,

	git = function()
		local git_info = vim.b.gitsigns_status_dict
		if not git_info or git_info.head == "" then
			return ""
		end

		local parts = {
			"%#GitSignsAccent# 󰘬 " .. git_info.head:upper() .. " ",
		}

		local changes = {
			{ git_info.added, "Add", config.icons.git.added },
			{ git_info.changed, "Change", config.icons.git.changed },
			{ git_info.removed, "Delete", config.icons.git.removed },
		}

		for _, change in ipairs(changes) do
			local count, type, icon = unpack(change)
			if count and count > 0 then
				table.insert(parts, string.format("%%#GitSigns%s#%s%d ", type, icon, count))
			end
		end

		return table.concat(parts) .. "%#Normal#"
	end,

	grapple = function()
		local grapple = try_require("grapple")
		if not grapple then
			return ""
		end

		local statusline = grapple.statusline()

		if statusline then
			return table.concat({
				"%#GrappleStatusLine#",
				statusline,
				"%#Normal#",
			})
		end
		return ""
	end,
}

Statusline = {}

Statusline.active = function()
	local parts = {}
	local function add(...)
		for _, part in ipairs({ ... }) do
			table.insert(parts, part)
		end
	end

	-- Left side
	add(
		"%#Statusline#",
		components.mode_color(),
		components.mode(),
		"%#Normal#",
		components.git(),
		components.grapple(),
		"%#Normal# ",
		components.filepath(),
		components.filename(),
		components.read_only(),
		"%#Normal#",
		components.diagnostics()
	)

	-- Right side
	add(
		"%=",
		components.lsp(),
		"%#StatusLineExtra#",
		components.filetype(),
		components.filesize(),
		components.file_format(),
		components.lineinfo()
	)

	return table.concat(parts)
end

function Statusline.inactive()
	return " %F"
end

setup_colors()

-- Create the autogroup
local statusline_group = api.nvim_create_augroup("Statusline", { clear = true })

-- Create the autocommands
api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	group = statusline_group,
	callback = function()
		vim.opt_local.statusline = "%!v:lua.Statusline.active()"
	end,
})

api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
	group = statusline_group,
	callback = function()
		vim.opt_local.statusline = "%!v:lua.Statusline.inactive()"
	end,
})

local statusline_timer = vim.loop.new_timer()
api.nvim_create_autocmd({ "DiagnosticChanged", "LspAttach", "LspDetach" }, {
	callback = function()
		statusline_timer:start(
			100,
			0,
			vim.schedule_wrap(function()
				cmd("redrawstatus")
			end)
		)
	end,
})
