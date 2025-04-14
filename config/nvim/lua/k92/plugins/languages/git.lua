if not vim.g.has_git then
	return {}
end

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"git_config",
				"gitcommit",
				"git_rebase",
				"gitignore",
				"gitattributes",
			},
		},
	},
}
