local M = {}

---@param opts table
function M.win(opts)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(
		buf,
		0,
		-1,
		false,
		type(opts.text) == "table" and opts.text or vim.split(opts.text or "", "\n")
	)

	if opts.scratch_ft then
		vim.bo[buf].filetype = opts.scratch_ft
	end

	local ft = opts.ft or vim.bo[buf].filetype
	local lang = vim.treesitter.language.get_lang(ft)
	if not (lang and pcall(vim.treesitter.start, buf, lang)) then
		vim.bo[buf].syntax = ft
	end

	if opts.bo then
		for k, v in pairs(opts.bo) do
			vim.bo[buf][k] = v
		end
	end
	vim.bo[buf].modifiable = opts.bo and opts.bo.modifiable or false
	vim.bo[buf].readonly = opts.bo and opts.bo.readonly or true
	vim.bo[buf].bufhidden = "wipe"

	local wo = opts.wo or {}
	wo.spell = wo.spell or false
	wo.wrap = wo.wrap or false
	wo.signcolumn = wo.signcolumn or "yes"
	wo.conceallevel = wo.conceallevel or 3
	wo.concealcursor = wo.concealcursor or "nvic"

	-- 5. geometry & position
	local width = opts.width or 0.8
	local height = opts.height or 0.8
	if width <= 1 then
		width = math.floor(vim.o.columns * width)
	end
	if height <= 1 then
		height = math.floor(vim.o.lines * height)
	end

	local pos = ({ float = "editor", split = "win", vsplit = "win" })[opts.position or "float"]
	local cfg = {
		relative = pos,
		width = width,
		height = height,
		style = opts.minimal and "minimal" or nil,
		border = opts.border or "rounded",
		title = opts.title,
		title_pos = opts.title_pos or "center",
	}

	if opts.position == "float" then
		cfg.row = (vim.o.lines - height) / 2
		cfg.col = (vim.o.columns - width) / 2
	end

	local win = vim.api.nvim_open_win(buf, true, cfg)

	for k, v in pairs(wo) do
		vim.wo[win][k] = v
	end

	local keys = opts.keys or {}
	keys.q = keys.q or "close"
	for lhs, rhs in pairs(keys) do
		vim.keymap.set("n", lhs, rhs == "close" and "<cmd>close<cr>" or rhs, { buffer = buf, nowait = true })
	end

	if opts.on_buf then
		opts.on_buf({ buf = buf, win = win })
	end
end

return M
