---@type Hs.Pack.PluginSpec
return {
  name = "Vimnav",
  url = "https://github.com/y3owk1n/vimnav.spoon.git",
  config = function()
    local vimnavConfig = {
      excludedApps = {
        "Terminal",
        "Ghostty",
        "Screen Sharing",
        "RustDesk",
      },
    }

    spoon.Vimnav:start(vimnavConfig)
  end,
}
