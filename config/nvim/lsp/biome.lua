local lsp_utils = require("k92.utils.lsp")

local root_files = { "biome.json", "biome.jsonc" }

local tr = require("tool-resolver")

---@type vim.lsp.Config
return {
  cmd = { tr.get_bin("biome"), "lsp-proxy" },
  filetypes = {
    "astro",
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "jsonc",
    "svelte",
    "typescript",
    "typescript.tsx",
    "typescriptreact",
    "vue",
  },
  workspace_required = true,
  ---@param bufnr integer
  ---@param on_dir fun(root_dir?:string)
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    root_files = lsp_utils.insert_package_json(root_files, "biome", fname)
    local root_dir = vim.fs.dirname(vim.fs.find(root_files, { path = fname, upward = true })[1])
    on_dir(root_dir)
  end,
}
