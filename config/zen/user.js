//
/* You may copy+paste this file and use it as it is.
 *
 * If you make changes to your about:config while the program is running, the
 * changes will be overwritten by the user.js when the application restarts.
 *
 * To make lasting changes to preferences, you will have to edit the user.js.
 */

/****************************************************************************
 * BetterZen                                                                *
 * "Ex nihilo nihil fit"                                                    *
 * version: 137                                                             *
 * url: https://github.com/yokoffing/Betterfox                              *
****************************************************************************/

/****************************************************************************
 * SECTION: FASTFOX                                                         *
****************************************************************************/
/** GFX ***/
user_pref("gfx.canvas.accelerated.cache-items", 8192); // DEFAULT FF135+
user_pref("gfx.canvas.accelerated.cache-size", 512);

/** DISK CACHE ***/
user_pref("browser.cache.disk.enable", false);

/** NETWORK ***/
user_pref("network.http.pacing.requests.enabled", false);

/** SPECULATIVE LOADING ***/
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.prefetch-next", false);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-prefetch", false);

/****************************************************************************
 * SECTION: SECUREFOX                                                       *
****************************************************************************/
/** TRACKING PROTECTION ***/
user_pref("browser.contentblocking.category", "strict");
user_pref("browser.download.start_downloads_in_tmp_dir", true);

/** OCSP & CERTS / HPKP ***/
user_pref("security.OCSP.enabled", 0);
user_pref("security.pki.crlite_mode", 2);

/** DISK AVOIDANCE ***/
user_pref("browser.sessionstore.interval", 60000);

/** SHUTDOWN & SANITIZING ***/
user_pref("browser.privatebrowsing.resetPBM.enabled", true);
user_pref("privacy.history.custom", true);

/** SEARCH / URL BAR ***/
user_pref("browser.urlbar.quicksuggest.enabled", false);

/** PASSWORDS ***/
user_pref("signon.formlessCapture.enabled", false);
user_pref("signon.privateBrowsingCapture.enabled", false);
user_pref("network.auth.subresource-http-auth-allow", 1);
user_pref("editor.truncate_user_pastes", false);

/** HEADERS / REFERERS ***/
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);

/** SAFE BROWSING ***/
user_pref("browser.safebrowsing.downloads.remote.enabled", false);

/** MOZILLA ***/
user_pref("permissions.default.desktop-notification", 2);
user_pref("permissions.default.geo", 2);
user_pref("geo.provider.network.url", "https://beacondb.net/v1/geolocate");
user_pref("browser.search.update", false);
user_pref("permissions.manager.defaultsUrl", "");

/****************************************************************************
 * SECTION: PESKYFOX                                                        *
****************************************************************************/
/** MOZILLA UI ***/
user_pref("browser.shell.checkDefaultBrowser", false);

/** NEW TAB PAGE ***/
user_pref("browser.newtabpage.activity-stream.default.sites", "");

/** URL BAR ***/
user_pref("dom.text_fragments.create_text_fragment.enabled", true);

/****************************************************************************
 * START: ZEN-SPECIFIC OVERRIDES                                            *
****************************************************************************/
// Remove the slashes to enable the prefs

// PREF: reduce CPU and GPU use until bug is fixed
// [1] https://github.com/zen-browser/desktop/issues/6302
user_pref("zen.view.experimental-rounded-view", false);

// PREF: re-enable Windows efficiency mode
//user_pref("dom.ipc.processPriorityManager.backgroundUsesEcoQoS", true);

// PREF: disable new tab preload since they are off by default
//user_pref("browser.newtab.preload", false);

// PREF: show Enhance Tracking Protection shield in URL bar
// Currently bugged if you click to view what's blocked
//user_pref("zen.urlbar.show-protections-icon", true);

/****************************************************************************
 * START: MY OVERRIDES                                                      *
****************************************************************************/
// visit https://github.com/yokoffing/Betterfox/wiki/Common-Overrides
// visit https://github.com/yokoffing/Betterfox/wiki/Optional-Hardening
// Enter your personal overrides below this line:

// PREF: disable Firefox Sync
user_pref("identity.fxaccounts.enabled", false);

// PREF: disable the Firefox View tour from popping up
user_pref("browser.firefox-view.feature-tour", "{\"screen\":\"\",\"complete\":true}");

// PREF: disable login manager
user_pref("signon.rememberSignons", false);

// PREF: pop-up to save logins for a new site
user_pref("signon.formlessCapture.enabled", true);

// PREF: disable address and credit card manager
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);

// PREF: do not allow embedded tweets, Instagram, Reddit, and Tiktok posts
user_pref("urlclassifier.trackingSkipURLs", "");
user_pref("urlclassifier.features.socialtracking.skipURLs", "");

// PREF: enable HTTPS-Only Mode
// Warn me before loading sites that don't support HTTPS
// in both Normal and Private Browsing windows.
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_error_page_user_suggestions", true);

// PREF: enforce certificate pinning
// [ERROR] MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE
user_pref("security.cert_pinning.enforcement_level", 2);

// PREF: set DoH provider
// user_pref("network.trr.uri", "https://dns.dnswarden.com/00000000000000000000048"); // Hagezi Light + TIF
// user_pref("network.trr.uri", "https://dns.quad9.net/dns-query");
// user_pref("network.trr.uri", "https://mozilla.cloudflare-dns.com/dns-query");

// PREF: enforce DNS-over-HTTPS (DoH)
// user_pref("network.trr.mode", 3); // Max Protection - use this if no system configured DoH
user_pref("network.trr.mode", 5); // Disabled - use this if you have a system configured DoH
// user_pref("network.dns.skipTRR-when-parental-control-enabled", false);

// PREF: ask where to save every file
user_pref("browser.download.useDownloadDir", false);

// PREF: ask whether to open or save new file types
user_pref("browser.download.always_ask_before_handling_new_types", true);

// PREF: display the installation prompt for all extensions
user_pref("extensions.postDownloadThirdPartyPrompt", false);

// PREF: require safe SSL negotiation
// [ERROR] SSL_ERROR_UNSAFE_NEGOTIATION
user_pref("security.ssl.require_safe_negotiation", true);

// PREF: make Strict ETP less aggressive
user_pref("browser.contentblocking.features.strict", "tp,tpPrivate,cookieBehavior5,cookieBehaviorPBM5,cm,fp,stp,emailTP,emailTPPrivate,-lvl2,rp,rpTop,ocsp,qps,qpsPBM,fpp,fppPrivate,3pcd,btp");

// Disable Safe Browsing
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);

// WebGL is a security risk, but sometimes break things on Google Maps
user_pref("webgl.disabled", true);

// Do not track
user_pref("privacy.donottrackheader", true);

// PREF: improve font rendering by using DirectWrite everywhere like Chrome [WINDOWS]
user_pref("gfx.font_rendering.cleartype_params.rendering_mode", 5);
user_pref("gfx.font_rendering.cleartype_params.cleartype_level", 100);
user_pref("gfx.font_rendering.directwrite.use_gdi_table_loading", false);
//user_pref("gfx.font_rendering.cleartype_params.enhanced_contrast", 50); // 50-100 [OPTIONAL]

// user_pref("font.name.serif.x-western", "Roboto Slab"); // serif font

/****************************************************************************
 * SECTION: SMOOTHFOX                                                       *
 ****************************************************************************/
// visit https://github.com/yokoffing/Betterfox/blob/main/Smoothfox.js
// Enter your scrolling overrides below this line:
user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaRatio", 2);
user_pref("general.smoothScroll.currentVelocityWeighting", 1);
user_pref("general.smoothScroll.stopDecelerationWeighting", 1);
user_pref("mousewheel.default.delta_multiplier_y", 300); // 250-400; adjust this number to your liking

/****************************************************************************
 * END: BETTERFOX                                                           *
 ****************************************************************************/
