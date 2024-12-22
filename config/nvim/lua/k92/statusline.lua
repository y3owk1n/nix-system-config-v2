local api = vim.api
local fn = vim.fn
local diagnostic = vim.diagnostic
local bo = vim.bo

local function setup_colors()
	local status_ok, catppuccin = pcall(require, "catppuccin.palettes")
	if not status_ok then
		vim.notify("Catppuccin colorscheme not found", vim.log.levels.WARN)
		return
	end

	local colors = catppuccin.get_palette()

	local highlights = {
		-- Mode colors
		{ "StatuslineAccent", colors.lavender, colors.crust },
		{ "StatuslineInsertAccent", colors.green, colors.crust },
		{ "StatuslineVisualAccent", colors.mauve, colors.crust },
		{ "StatuslineReplaceAccent", colors.red, colors.crust },
		{ "StatuslineCmdLineAccent", colors.peach, colors.crust },
		{ "StatuslineTerminalAccent", colors.teal, colors.crust },

		-- Git colors
		{ "GitSignsAdd", colors.green, nil },
		{ "GitSignsChange", colors.yellow, nil },
		{ "GitSignsDelete", colors.red, nil },

		-- LSP colors
		{ "LspDiagnosticsSignError", colors.red, nil },
		{ "LspDiagnosticsSignWarning", colors.yellow, nil },
		{ "LspDiagnosticsSignInformation", colors.sky, nil },
		{ "LspDiagnosticsSignHint", colors.teal, nil },

		-- Statusline backgrounds
		{ "StatusLine", nil, colors.mantle },
		{ "StatusLineNC", nil, colors.crust },
		{ "StatusLineExtra", colors.subtext1, colors.surface0 },

		-- Grapple colors
		{ "GrappleStatusLine", colors.flamingo, nil },
	}

	for _, hl in ipairs(highlights) do
		local name, fg, bg = unpack(hl)
		local cmd = "hi " .. name
		if fg then
			cmd = cmd .. " guifg=" .. fg
		end
		if bg then
			cmd = cmd .. " guibg=" .. bg
		end
		api.nvim_command(cmd)
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

local function mode()
	local current_mode = api.nvim_get_mode().mode
	return string.format(" %s ", modes[current_mode]):upper()
end

local function update_mode_colors()
	local current_mode = api.nvim_get_mode().mode
	local mode_color = "%#StatusLineAccent#"
	if current_mode == "n" then
		mode_color = "%#StatuslineAccent#"
	elseif current_mode == "i" or current_mode == "ic" then
		mode_color = "%#StatuslineInsertAccent#"
	elseif current_mode == "v" or current_mode == "V" or current_mode == "" then
		mode_color = "%#StatuslineVisualAccent#"
	elseif current_mode == "R" then
		mode_color = "%#StatuslineReplaceAccent#"
	elseif current_mode == "c" then
		mode_color = "%#StatuslineCmdLineAccent#"
	elseif current_mode == "t" then
		mode_color = "%#StatuslineTerminalAccent#"
	end
	return mode_color
end

local function filepath()
	local fpath = fn.fnamemodify(vim.fn.expand("%"), ":~:.:h")
	if fpath == "" or fpath == "." then
		return " "
	end

	return string.format(" %%<%s/", fpath)
end

local function filename()
	local fname = fn.expand("%:t")
	if fname == "" then
		return ""
	end
	return fname .. " "
end

local function lsp()
	local count = {}
	local levels = {
		errors = "Error",
		warnings = "Warn",
		info = "Info",
		hints = "Hint",
	}

	for k, level in pairs(levels) do
		count[k] = vim.tbl_count(diagnostic.get(0, { severity = level }))
	end

	local errors = ""
	local warnings = ""
	local hints = ""
	local info = ""

	if count["errors"] ~= 0 then
		errors = " %#LspDiagnosticsSignError# " .. count["errors"]
	end
	if count["warnings"] ~= 0 then
		warnings = " %#LspDiagnosticsSignWarning# " .. count["warnings"]
	end
	if count["hints"] ~= 0 then
		hints = " %#LspDiagnosticsSignHint# " .. count["hints"]
	end
	if count["info"] ~= 0 then
		info = " %#LspDiagnosticsSignInformation# " .. count["info"]
	end

	return errors .. warnings .. hints .. info .. "%#Normal#"
end

local function filetype()
	return string.format(" %s ", bo.filetype):upper()
end

local function lineinfo()
	if bo.filetype == "alpha" then
		return ""
	end
	return " %P %l:%c "
end

local function vcs()
	local git_info = vim.b.gitsigns_status_dict
	if not git_info or git_info.head == "" then
		return ""
	end
	local added = git_info.added and ("%#GitSignsAdd# " .. git_info.added .. " ") or ""
	local changed = git_info.changed and ("%#GitSignsChange# " .. git_info.changed .. " ") or ""
	local removed = git_info.removed and ("%#GitSignsDelete# " .. git_info.removed .. " ") or ""
	if git_info.added == 0 then
		added = ""
	end
	if git_info.changed == 0 then
		changed = ""
	end
	if git_info.removed == 0 then
		removed = ""
	end
	return table.concat({
		" ",
		"%#GitSignsAdd# ",
		git_info.head,
		" ",
		added,
		changed,
		removed,
		" %#Normal#",
	})
end

local grapple = function()
	local statusline = require("grapple").statusline()
	if statusline then
		return table.concat({
			"%#GrappleStatusLine#", -- Apply the color
			" ",
			statusline,
			"%#Normal#", -- Reset the color
		})
	end

	return ""
end

Statusline = {}

Statusline.active = function()
	return table.concat({
		"%#Statusline#",
		update_mode_colors(),
		mode(),
		"%#Normal#",
		" ",
		vcs(),
		grapple(),
		"%#Normal# ",
		filepath(),
		filename(),
		"%#Normal#",
		lsp(),
		"%=%#StatusLineExtra#",
		filetype(),
		lineinfo(),
	})
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
