---@type LazySpec
return {
  {
    "y3owk1n/tool-resolver.nvim",
    -- dir = "~/Dev/tool-resolver.nvim", -- Your path
    cmd = {
      "ToolResolverGetTool",
      "ToolResolverGetTools",
    },
    ---@module "tool-resolver"
    ---@type ToolResolver.Config
    opts = {
      tools = {
        biome = {
          type = "node",
        },
        prettier = {
          type = "node",
          fallback = "prettierd",
        },
      },
    },
  },
}
