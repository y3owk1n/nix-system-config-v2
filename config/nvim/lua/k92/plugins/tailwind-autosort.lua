---@type LazySpec
return {
  {
    "y3owk1n/tailwind-autosort.nvim",
    -- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
    -- version = "*",
    init = function()
      local allowed_clients = { "tailwindcss" }
      require("k92.utils.lazy").lazy_load_lsp_attach(allowed_clients, "tailwind-autosort.nvim")
    end,
    ---@module "tailwind-autosort"
    ---@type TailwindAutoSort.Config
    opts = {},
  },
}
