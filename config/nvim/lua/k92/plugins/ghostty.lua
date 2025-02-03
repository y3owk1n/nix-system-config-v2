---@type LazySpec
return {
	"ghostty",
	dir = "/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/",
	ft = { "ghostty" },
	enabled = vim.fn.executable("ghostty") == 1,
}
