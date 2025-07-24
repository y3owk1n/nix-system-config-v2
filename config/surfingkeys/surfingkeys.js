// Compatibility Prefix
const {
  Clipboard,
  Front,
  Hints,
  Normal,
  RUNTIME,
  Visual,
  aceVimMap,
  addSearchAlias,
  cmap,
  getClickableElements,
  imap,
  imapkey,
  iunmap,
  map,
  mapkey,
  readText,
  removeSearchAlias,
  tabOpenLink,
  unmap,
  unmapAllExcept,
  vmapkey,
  vunmap,
} = api;

// ---- Settings ----
Hints.setCharacters("aoeuidhtns");

settings.hintAlign = "left";
settings.omnibarPosition = "bottom";
settings.focusFirstCandidate = false;
settings.focusAfterClosed = "last";
settings.stealFocusOnLoad = false;
settings.scrollStepSize = 200;
settings.tabsThreshold = 0;
settings.modeAfterYank = "Normal";

// ---- Unmap -----
// Proxy Stuff
unmap("spa");
unmap("spb");
unmap("spc");
unmap("spd");
unmap("sps");
unmap("cp");
unmap(";cp");
unmap(";ap");

unmap("H"); // just in case
unmap("L"); // just in case
unmap("J"); // just in case
unmap("K"); // just in case
unmap("d"); // just in case

unmap("i");
unmap("t");
unmap("x");
unmap(":");
unmap("gf");
unmap("af");
unmap("C");
unmap("I");
unmap("u");
unmap("F"); // Go one tab history forward
unmap("d"); // Scroll half page down
unmap("e"); // Scroll half page up
unmap("U"); // Scroll full page up
unmap("P"); // Scroll full page down

// Emoji
iunmap(":");

unmap("<Ctrl-j>")

// ---- Map ----
map("H", "S");
map("L", "D");
// map("J", "R"); <-- Using arc default keymap to switch tabs
// map("K", "E"); <-- Using arc default keymap to switch tabs
map("F", "gf");
mapkey("<Ctrl-d>", "Scroll down", () => {
  Normal.scroll("pageDown");
});
mapkey("<Ctrl-u>", "Scroll up", () => {
  Normal.scroll("pageUp");
});

// ---- Post Unmap ----
unmap("S");
unmap("D");
unmap("R");
unmap("E");

// ---- Search Engines -----
removeSearchAlias("b", "s");
removeSearchAlias("d", "s");
removeSearchAlias("g", "s");
removeSearchAlias("h", "s");
removeSearchAlias("w", "s");
removeSearchAlias("y", "s");
removeSearchAlias("s", "s");
