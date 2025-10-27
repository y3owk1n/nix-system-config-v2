/*******************************************************************************
 Options
 ******************************************************************************/

glide.o.hint_chars = "aoeuidhtns";
glide.o.hint_size = "14px";

/*******************************************************************************
 Keymaps
 ******************************************************************************/

const modes: Record<"ni", GlideMode[]> = {
  ni: ["normal", "insert"],
};

// map
glide.keymaps.set("normal", "H", "back");
glide.keymaps.set("normal", "L", "forward");
glide.keymaps.set(modes.ni, "<C-h>", "tab_prev");
glide.keymaps.set(modes.ni, "<C-l>", "tab_next");
glide.keymaps.set(
  "normal",
  ">>",
  async () => {
    const tab = await glide.tabs.active();
    assert(tab && tab.id);

    const tabs = await browser.tabs.query({ currentWindow: true });
    const tabsCount = tabs.length;

    if (tab.index + 1 < tabsCount) {
      await browser.tabs.move(tab.id, { index: tab.index + 1 });
    }
  },
  { description: "Move current tab to the right" },
);
glide.keymaps.set(
  "normal",
  "<<",
  async () => {
    const tab = await glide.tabs.active();
    assert(tab && tab.id);

    if (tab.index - 1 >= 0) {
      await browser.tabs.move(tab.id, { index: tab.index - 1 });
    }
  },
  { description: "Move current tab to the left" },
);

/*******************************************************************************
 Prefs
 ******************************************************************************/

// PREF: improve font rendering by using DirectWrite everywhere like Chrome [WINDOWS]
glide.prefs.set("gfx.font_rendering.cleartype_params.rendering_mode", 5);
glide.prefs.set("gfx.font_rendering.cleartype_params.cleartype_level", 100);
glide.prefs.set("gfx.font_rendering.directwrite.use_gdi_table_loading", false);
glide.prefs.set("gfx.font_rendering.cleartype_params.enhanced_contrast", 50); // 50-100 [OPTIONAL]

// PREF: allow websites to ask you for your location
glide.prefs.set("permissions.default.geo", 0);

// PREF: disable login manager
glide.prefs.set("signon.rememberSignons", false);

// PREF: disable address and credit card manager
glide.prefs.set("extensions.formautofill.addresses.enabled", false);
glide.prefs.set("extensions.formautofill.creditCards.enabled", false);

// PREF: enable HTTPS-Only Mode
// Warn me before loading sites that don't support HTTPS
// in both Normal and Private Browsing windows.
glide.prefs.set("dom.security.https_only_mode", true);
glide.prefs.set("dom.security.https_only_mode_error_page_user_suggestions", true);

// PREF: disable captive portal detection
// [WARNING] Do NOT use for mobile devices!
glide.prefs.set("captivedetect.canonicalURL", "");
glide.prefs.set("network.captive-portal-service.enabled", false);
glide.prefs.set("network.connectivity-service.enabled", false);

// PREF: hide site shortcut thumbnails on New Tab page
glide.prefs.set("browser.newtabpage.activity-stream.feeds.topsites", false);

// PREF: hide weather on New Tab page
glide.prefs.set("browser.newtabpage.activity-stream.showWeather", false);

// PREF: hide dropdown suggestions when clicking on the address bar
glide.prefs.set("browser.urlbar.suggest.topsites", false);

// PREF: display the installation prompt for all extensions
glide.prefs.set("extensions.postDownloadThirdPartyPrompt", false);

// PREF: enforce certificate pinning
// [ERROR] MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE
// 1 = allow user MiTM (such as your antivirus) (default)
// 2 = strict
glide.prefs.set("security.cert_pinning.enforcement_level", 2);

// PREF: enable container tabs
glide.prefs.set("privacy.userContext.enabled", true);

// PREF: enable PIP on tab switch
glide.prefs.set("media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled", true);

// credit: https://github.com/AveYo/fox/blob/cf56d1194f4e5958169f9cf335cd175daa48d349/Natural%20Smooth%20Scrolling%20for%20user.js
// recommended for 120hz+ displays
// largely matches Chrome flags: Windows Scrolling Personality and Smooth Scrolling
glide.prefs.set("apz.overscroll.enabled", true); // DEFAULT NON-LINUX
glide.prefs.set("general.smoothScroll", true); // DEFAULT
glide.prefs.set("general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS", 12);
glide.prefs.set("general.smoothScroll.msdPhysics.enabled", true);
glide.prefs.set("general.smoothScroll.msdPhysics.motionBeginSpringConstant", 600);
glide.prefs.set("general.smoothScroll.msdPhysics.regularSpringConstant", 650);
glide.prefs.set("general.smoothScroll.msdPhysics.slowdownMinDeltaMS", 25);
glide.prefs.set("general.smoothScroll.msdPhysics.slowdownMinDeltaRatio", "2");
glide.prefs.set("general.smoothScroll.msdPhysics.slowdownSpringConstant", 250);
glide.prefs.set("general.smoothScroll.currentVelocityWeighting", "1");
glide.prefs.set("general.smoothScroll.stopDecelerationWeighting", "1");
glide.prefs.set("mousewheel.default.delta_multiplier_y", 300); // 250-400; adjust this number to your liking
