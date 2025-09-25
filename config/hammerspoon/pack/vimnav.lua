return {
  name = "Vimnav",
  dir = os.getenv("HOME") .. "/.hammerspoon/custom-plugins/Vimnav",
  config = function()
    ---@type Hs.Vimnav.Config
    ---@diagnostic disable-next-line: missing-fields
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
