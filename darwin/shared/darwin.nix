{
  config,
  pkgs,
  safariKeys,
  username,
  ...
}:
{

  system = {
    primaryUser = "${username}";
    stateVersion = 5;
    activationScripts.extraActivation.enable = true;
    activationScripts.extraActivation.text = ''
      echo "Activating extra preferences..."
      # Close any open System Preferences panes, to prevent them from overriding
      # settings we’re about to change
      osascript -e 'tell application "System Settings" to quit'
    '';
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
    startup.chime = false; # MUTE STARTUP CHIME!
    defaults = {
      # universalaccess.reduceMotion = true;
      menuExtraClock = {
        Show24Hour = false;
        ShowAMPM = true;
        ShowDate = 0;
      };

      # customize dock
      dock = {
        # auto show and hide dock
        autohide = true;
        # remove delay for showing dock
        autohide-delay = 0.0;
        # how fast is the dock showing animation
        autohide-time-modifier = 0.2;
        expose-animation-duration = 0.2;
        tilesize = 48;
        launchanim = false;
        static-only = false;
        showhidden = true;
        show-recents = false;
        show-process-indicators = true;
        orientation = "left";
        mru-spaces = false;
        expose-group-apps = true;
      };

      # customize finder
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        # When performing a search, search the current folder by default
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        # Use list view in all Finder windows by default
        FXPreferredViewStyle = "Nlsv";
        QuitMenuItem = false;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        _FXSortFoldersFirst = true;
      };

      # customize trackpad
      trackpad = {
        # silent clicking = 0, default = 1
        ActuationStrength = 0;
        # enable tap to click
        Clicking = true;
        Dragging = true; # tap and a half to drag
        # three finger click and drag
        TrackpadThreeFingerDrag = true;
      };

      # `man configuration.nix` on mac is useful in seeing available options
      # `defaults read -g` on mac is useful to see current settings
      LaunchServices = {
        # quarantine downloads until approved
        LSQuarantine = true;
      };

      # login window settings
      loginwindow = {
        # disable guest account
        GuestEnabled = false;
        # show name instead of username
        SHOWFULLNAME = false;
        # Disables the ability for a user to access the console by typing “>console” for a username at the login window.
        DisableConsoleAccess = true;
      };

      spaces.spans-displays = true; # separate spaces on each display

      screencapture = {
        disable-shadow = true;
        include-date = true;
        location = "~/Downloads";
        type = "jpg";
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      WindowManager = {
        EnableStandardClickToShowDesktop = false; # Click wallpaper to reveal desktop
        GloballyEnabled = false;
        HideDesktop = true; # Do not hide items on desktop & stage manager
        StageManagerHideWidgets = true;
        StandardHideDesktopIcons = true; # Show items on desktop
        StandardHideWidgets = true;
        EnableTiledWindowMargins = true;
        EnableTilingByEdgeDrag = false;
        EnableTilingOptionAccelerator = false;
        EnableTopTilingByEdgeDrag = false;
      };

      controlcenter = {
        BatteryShowPercentage = true;
      };

      # customize settings that not supported by nix-darwin directly
      # Incomplete list of macOS `defaults` commands :
      #   https://github.com/yannbertrand/macos-defaults
      NSGlobalDomain = {
        AppleEnableSwipeNavigateWithScrolls = true;
        # 2 = heavy font smoothing; if text looks blurry, back this down to 1
        AppleFontSmoothing = 2;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        # Dark mode
        AppleInterfaceStyle = "Dark";
        # auto switch between light/dark mode
        AppleInterfaceStyleSwitchesAutomatically = false;
        "com.apple.sound.beep.feedback" = 1;
        "com.apple.sound.beep.volume" = 0.606531; # 50%
        "com.apple.mouse.tapBehavior" = 1; # tap to click
        "com.apple.swipescrolldirection" = true; # "natural" scrolling
        "com.apple.keyboard.fnState" = false;
        "com.apple.springing.enabled" = false;
        "com.apple.trackpad.scaling" = 3.0; # fast
        "com.apple.trackpad.enableSecondaryClick" = true;
        # enable full keyboard control
        # (e.g. enable Tab in modal dialogs)
        AppleKeyboardUIMode = 3;
        AppleTemperatureUnit = "Celsius";
        AppleMeasurementUnits = "Centimeters";
        # no popup menus when holding down letters
        ApplePressAndHoldEnabled = false;
        # delay before repeating keystrokes
        InitialKeyRepeat = 14;
        # delay between repeated keystrokes upon holding a key
        KeyRepeat = 1;
        AppleShowScrollBars = "Automatic";
        NSScrollAnimationEnabled = true; # smooth scrolling
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        # speed up animation on open/save boxes (default:0.2)
        NSWindowResizeTime = 1.0e-3;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
      };

      # Customize settings that not supported by nix-darwin directly
      # see the source code of this project to get more undocumented options:
      #    https://github.com/rgcr/m-cli
      #
      # All custom entries can be found by running `defaults read` command.
      # or `defaults read xxx` to read a specific domain.
      CustomUserPreferences = {
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          # AppleSpacesSwitchOnActivate = true;
          "com.apple.mouse.scaling" = 9;
          AppleLanguages = [
            "en-SG"
            "ms-MY"
            "zh-Hant-MY"
          ];
          # NSUserKeyEquivalents = {
          #   Bottom = "^$j";
          #   Fill = "^$m";
          #   Left = "^$h";
          #   Right = "^$l";
          #   Top = "^$k";
          # };
        };
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
          AppleMiniaturizeOnDoubleClick = false;
          NSAutomaticTextCompletionEnabled = true;
          "com.apple.sound.beep.flash" = false;
        };
        "com.apple.dock" = {
          # mouse in top left corner will (13) start lock screen
          # set it here, nix-darwin does not support modifier
          wvous-tl-corner = 13; # lock screen
          wvous-tl-modifier = 131072; # shift key
          wvous-br-corner = 1;
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
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
        "com.apple.Safari" = {
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
            "Go to Next Tab Group" = "^j";
            "Go to Previous Tab Group" = "^k";
            "Show Next Tab" = "^l";
            "Show Previous Tab" = "^h";
            "Move Tab to New Window" = "^\\";
            "Merge All Windows" = "^-";
            "Pin Tab" = "@d";
            "Unpin Tab" = "@d";
          }
          // safariKeys;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.print.PrintingPrefs" = {
          # Automatically quit printer app once the print jobs complete
          "Quit When Finished" = true;
        };
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          # Check for software updates daily, not just once per week
          ScheduleFrequency = 1;
          # Download newly available updates in background
          AutomaticDownload = 1;
          # Install System data files & security updates
          CriticalUpdateInstall = 1;
        };
        "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
        # Turn on app auto-update
        "com.apple.commerce".AutoUpdate = true;
        # Macos hotkeys
        # "com.apple.symbolichotkeys" = {
        #   AppleSymbolicHotKeys = {
        #     # Window -> Fill (control + shift + m)
        #     "237" = {
        #       enabled = 1;
        #       value = {
        #         parameters = [
        #           109
        #           46 # m
        #           393216
        #         ];
        #         type = "standard";
        #       };
        #     };
        #     # Window -> Move & resize left (control + shift + h)
        #     "240" = {
        #       enabled = 1;
        #       value = {
        #         parameters = [
        #           104
        #           4
        #           393216
        #         ];
        #         type = "standard";
        #       };
        #     };
        #     # Window -> Move & resize right (control + shift + l)
        #     "241" = {
        #       enabled = 1;
        #       value = {
        #         parameters = [
        #           108
        #           37
        #           393216
        #         ];
        #         type = "standard";
        #       };
        #     };
        #     # Window -> Move & resize top (control + shift + k)
        #     "242" = {
        #       enabled = 1;
        #       value = {
        #         parameters = [
        #           107
        #           40
        #           393216
        #         ];
        #         type = "standard";
        #       };
        #     };
        #     # Window -> Move & resize bottom (control + shift + j)
        #     "243" = {
        #       enabled = 1;
        #       value = {
        #         parameters = [
        #           106
        #           38
        #           393216
        #         ];
        #         type = "standard";
        #       };
        #     };
        #     # Window -> Move & resize left & right (control + shift + \)
        #     "248" = {
        #       enabled = 1;
        #       value = {
        #         parameters = [
        #           92
        #           42
        #           393216
        #         ];
        #         type = "standard";
        #       };
        #     };
        #     # Window -> Move & resize top & bottom (control + shift + -)
        #     "250" = {
        #       enabled = 1;
        #       value = {
        #         parameters = [
        #           45
        #           27
        #           393216
        #         ];
        #         type = "standard";
        #       };
        #     };
        #   };
        # };
        "com.apple.Siri" = {
          CustomizedKeyboardShortcutSAE = {
            enabled = 1;
            value = {
              parameters = [
                115
                1
                1966080
              ];
              type = "SAE1.0";
            };
          };
        };
      };
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
}
