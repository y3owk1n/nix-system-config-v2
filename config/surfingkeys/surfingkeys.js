const { Hints, map, unmap } = api;

// ---- Settings ----
Hints.setCharacters("aoeuidhtns");

settings.omnibarPosition = "bottom";
settings.focusFirstCandidate = false;
settings.focusAfterClosed = "last";
settings.scrollStepSize = 200;
settings.tabsThreshold = 0;
settings.modeAfterYank = "Normal";

// ---- Styles ----
const hintsCss =
  "font-size: 10pt; font-family: JetBrains Mono NL, Cascadia Code, SauceCodePro Nerd Font, Consolas, Menlo, monospace;";

api.Hints.style(hintsCss);
api.Hints.style(hintsCss, "text");

// ---- Mappings ----

// Go one tab left
map("<Ctrl-h>", "E");
unmap("E");

// Go one tab right
map("<Ctrl-l>", "R");
unmap("R");

// Go back in history
map("H", "S");
unmap("S");

// Go forward in history
map("L", "D");
unmap("D");

// Go one tab history back
map("<Ctrl-o>", "B");
unmap("B");

// Go one tab history forward
map("<Ctrl-i>", "F");
unmap("F");

// Scroll half page up
map("<Ctrl-u>", "e");
unmap("e");

// Scroll half page down
map("<Ctrl-d>", "d");
unmap("d");
unmap("u");

// Scroll full page up
unmap("U");

// Scroll full page down
unmap("P");
