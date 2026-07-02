{ username, safariWorkspaces, ... }:
let
  safariSettings = {
    AllowJavaScriptFromAppleEvents = 0;
    AlwaysRestoreSessionAtLaunch = 1;
    AutoFillCreditCardData = 0;
    AutoFillMiscellaneousForms = 0;
    AutoOpenSafeDownloads = 0;
    EnableEnhancedPrivacyInRegularBrowsing = 1;
    EnableNarrowTabs = 1;
    ExcludePrivateWindowWhenRestoringSessionAtLaunch = 1;
    ExtensionsEnabled = 1;
    HideHighlightsEmptyItemViewPreferenceKey = 1;
    HideStartPageFrecentsEmptyItemView = 1;
    HomePage = "";
    IncludeDevelopMenu = 1;
    NewTabBehavior = 1;
    NewTabPageSetByUserGesture = 1;
    NewWindowBehavior = 1;
    OpenPrivateWindowWhenNotRestoringSessionAtLaunch = 0;
    PrivateBrowsingRequiresAuthentication = 1;
    PrivateSearchEngineUsesNormalSearchEngineToggle = 1;
    SearchProviderShortName = "DuckDuckGo";
    ShowFavoritesUnderSmartSearchField = 0;
    ShowFullURLInSmartSearchField = 1;
    ShowOverlayStatusBar = 0;
    ShowSidebarInNewWindows = 0;
    ShowSidebarInTopSites = 0;
    ShowStandaloneTabBar = 0;
    SidebarSplitViewDividerPosition = 240;
    SidebarTabGroupHeaderExpansionState = 1;
    UseHTTPSOnly = 0;
    SuppressSearchSuggestions = 1;
    UserStyleSheetEnabled = 0;
    WebKitDeveloperExtrasEnabledPreferenceKey = 1;
    WebKitJavaScriptEnabled = 1;
    WebKitMinimumFontSize = 9;
    "WebKitPreferences.allowsPictureInPictureMediaPlayback" = 1;
    "WebKitPreferences.applePayEnabled" = 1;
    "WebKitPreferences.developerExtrasEnabled" = 1;
    "WebKitPreferences.hiddenPageDOMTimerThrottlingAutoIncreases" = 1;
    "WebKitPreferences.invisibleMediaAutoplayNotPermitted" = 1;
    "WebKitPreferences.javaScriptCanOpenWindowsAutomatically" = 1;
    "WebKitPreferences.javaScriptEnabled" = 1;
    "WebKitPreferences.minimumFontSize" = 9;
    "WebKitPreferences.needsStorageAccessFromFileURLsQuirk" = 0;
    "WebKitPreferences.pushAPIEnabled" = 1;
    "WebKitPreferences.shouldAllowUserInstalledFonts" = 0;
    "WebKitPreferences.shouldSuppressKeyboardInputDuringProvisionalNavigation" = 1;
    WebKitRespectStandardStyleKeyEquivalents = 1;
    "com.apple.Safari.WebInspectorPageGroupIdentifier.WebKit2InspectorAttachedWidth" = 1098;
    "com.apple.Safari.WebInspectorPageGroupIdentifier.WebKit2InspectorAttachmentSide" = 1;
    NSUserKeyEquivalents = {
      "Go To Next Tab Group" = "^j";
      "Go To Previous Tab Group" = "^k";
      "Show Next Tab" = "^l";
      "Show Previous Tab" = "^h";
      "Move Tab to New Window" = "^\\";
      "Merge All Windows" = "^-";
      "Pin Tab" = "@d";
      "Unpin Tab" = "@d";
    }
    // safariWorkspaces;
  };
in
{
  # ============================================================================
  # System Configuration
  # ============================================================================

  system = {
    primaryUser = "${username}";
    stateVersion = 6;

    activationScripts = {
      extraActivation = {
        enable = true;
        text = ''
          echo "Activating extra preferences..."
          osascript -e 'tell application "System Settings" to quit'
        '';
      };
      postActivation = {
        text = ''
          sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
          echo "Reloading settings and applying to current session..."

          if [ -e "/Users/${username}/Applications/Home Manager Apps/Neru.app" ]; then
              echo "Codesigning Neru.app..."
              /usr/bin/codesign --force --deep --sign - --timestamp=none "/Users/${username}/Applications/Home Manager Apps/Neru.app"
              pkill -9 neru > /dev/null 2>&1 || true
          fi
        '';
      };
    };

    startup.chime = false;

    defaults = {
      # ============================================================================
      # Clock
      # ============================================================================

      menuExtraClock = {
        FlashDateSeparators = false;
        Show24Hour = false;
        ShowAMPM = true;
        ShowDate = 0;
        ShowDayOfMonth = false;
        ShowDayOfWeek = false;
        ShowSeconds = false;
      };

      # ============================================================================
      # Dock
      # ============================================================================

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        expose-animation-duration = 0.1;
        expose-group-apps = true;
        launchanim = false;
        magnification = false;
        mru-spaces = false;
        orientation = "left";
        show-recents = false;
        show-process-indicators = true;
        showAppExposeGestureEnabled = true;
        showDesktopGestureEnabled = true;
        showLaunchpadGestureEnabled = true;
        showMissionControlGestureEnabled = true;
        showhidden = true;
        static-only = true;
        tilesize = 48;
      };

      # ============================================================================
      # Finder
      # ============================================================================

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        NewWindowTarget = "Other";
        NewWindowTargetPath = "file:///Users/${username}/Downloads";
        QuitMenuItem = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowPathbar = true;
        ShowRemovableMediaOnDesktop = false;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
      };

      # ============================================================================
      # Trackpad
      # ============================================================================

      trackpad = {
        ActuationStrength = 0;
        Clicking = true;
        Dragging = true;
        TrackpadFourFingerHorizSwipeGesture = 2;
        TrackpadFourFingerPinchGesture = 2;
        TrackpadFourFingerVertSwipeGesture = 2;
        TrackpadPinch = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
        TrackpadThreeFingerHorizSwipeGesture = 0;
        TrackpadThreeFingerTapGesture = 2;
        TrackpadThreeFingerVertSwipeGesture = 0;
        TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      };

      # ============================================================================
      # Magic Mouse
      # ============================================================================

      magicmouse = {
        MouseButtonMode = "TwoButton";
      };

      # ============================================================================
      # Launch Services
      # ============================================================================

      LaunchServices = {
        LSQuarantine = true;
      };

      # ============================================================================
      # Login Window
      # ============================================================================

      loginwindow = {
        DisableConsoleAccess = true;
        GuestEnabled = false;
        SHOWFULLNAME = false;
      };

      # ============================================================================
      # Spaces
      # ============================================================================

      spaces.spans-displays = false;

      # ============================================================================
      # Screen Capture
      # ============================================================================

      screencapture = {
        disable-shadow = true;
        include-date = true;
        location = "~/Downloads";
        type = "jpg";
      };

      # ============================================================================
      # Screen Saver
      # ============================================================================

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      # ============================================================================
      # Window Manager
      # ============================================================================

      WindowManager = {
        EnableStandardClickToShowDesktop = false;
        EnableTiledWindowMargins = true;
        EnableTilingByEdgeDrag = true;
        EnableTilingOptionAccelerator = true;
        EnableTopTilingByEdgeDrag = true;
        GloballyEnabled = false;
        HideDesktop = true;
        StageManagerHideWidgets = true;
        StandardHideDesktopIcons = true;
        StandardHideWidgets = true;
      };

      # ============================================================================
      # Control Center
      # ============================================================================

      controlcenter = {
        BatteryShowPercentage = true;
      };

      # ============================================================================
      # Global Domain
      # ============================================================================

      NSGlobalDomain = {
        AppleEnableSwipeNavigateWithScrolls = true;
        AppleEnableMouseSwipeNavigateWithScrolls = true;
        AppleFontSmoothing = 2;
        AppleIconAppearanceTheme = null;
        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = false;
        AppleKeyboardUIMode = 3;
        AppleMeasurementUnits = "Centimeters";
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Automatic";
        AppleSpacesSwitchOnActivate = true;
        AppleTemperatureUnit = "Celsius";
        InitialKeyRepeat = 10;
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSScrollAnimationEnabled = true;
        NSWindowResizeTime = 0.001;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        "com.apple.keyboard.fnState" = false;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.feedback" = 1;
        "com.apple.sound.beep.volume" = 0.606531;
        "com.apple.springing.enabled" = false;
        "com.apple.swipescrolldirection" = true;
        "com.apple.trackpad.enableSecondaryClick" = true;
        "com.apple.trackpad.scaling" = 3.0;
      };

      # ============================================================================
      # Custom User Preferences
      # ============================================================================

      CustomUserPreferences = {
        ".GlobalPreferences" = {
          "com.apple.mouse.scaling" = 9.0;
          AppleLanguages = [
            "en-SG"
            "ms-MY"
            "zh-Hant-MY"
          ];
        };
        NSGlobalDomain = {
          WebKitDeveloperExtras = true;
          AppleMiniaturizeOnDoubleClick = false;
          NSAutomaticTextCompletionEnabled = true;
          "com.apple.sound.beep.flash" = false;
          NSTextMovementDefaultKeyTimeout = 0.03;
          NSToolbarTitleViewRolloverDelay = 0;
        };
        "com.apple.dock" = {
          wvous-tl-corner = 13;
          wvous-tl-modifier = 131072;
          wvous-br-corner = 1;
          springboard-show-duration = 0;
          springboard-hide-duration = 0;
          springboard-page-duration = 0;
        };
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "net.imput.helium" = {
          NSUserKeyEquivalents = {
            "Pin Tab" = "@d";
            "Select Next Tab" = "^l";
            "Select Previous Tab" = "^h";
          };
        };
        "com.apple.Safari" = safariSettings;
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.print.PrintingPrefs" = {
          "Quit When Finished" = true;
        };
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          ScheduleFrequency = 1;
          AutomaticDownload = 1;
          CriticalUpdateInstall = 1;
        };
        "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
        "com.apple.ImageCapture".disableHotPlug = true;
        "com.apple.commerce".AutoUpdate = true;
      };
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
