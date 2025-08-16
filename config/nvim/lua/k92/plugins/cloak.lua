---@type LazySpec
return {
  "laytan/cloak.nvim",
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "CloakDisable", "CloakEnable", "CloakToggle" },
  opts = {},
}
