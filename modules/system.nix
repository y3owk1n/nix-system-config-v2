{ pkgs, username, ... }:

###################################################################################
#
#  macOS's System configuration
#
#  All the configuration options are documented here:
#    https://daiderd.com/nix-darwin/manual/index.html#sec-options
#  Incomplete list of macOS `defaults` commands :
#    https://github.com/yannbertrand/macos-defaults
#
###################################################################################
{

  system = {
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
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
        # # mouse in top right corner will (5) start screensaver
        # wvous-tr-corner = 5;
        # # mouse in top left corner will (13) start lock screen
        # wvous-tl-corner = 13;
      };

      # customize finder
      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
        _FXShowPosixPathInTitle = true;
        # Use list view in all Finder windows by default
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
        ShowStatusBar = true;
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

      # firewall settings
      alf = {
        # 0 = disabled 1 = enabled 2 = blocks all connections except for essential services
        globalstate = 1;
        loggingenabled = 0;
        stealthenabled = 1;
      };

      spaces.spans-displays = false; # separate spaces on each display

      screencapture = {
        disable-shadow = true;
        location = "~/Downloads";
        type = "jpg";
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
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
        NSAutomaticPeriodSubstitutionEnabled = false;
        # no automatic smart quotes
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
        # ".GlobalPreferences" = {
        #   # automatically switch to a new space when switching to the application
        #   AppleSpacesSwitchOnActivate = true;
        # };
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
          wvous-tl-corner = 13;
          wvous-tl-modifier = 131072; # shift key
        };
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          # When performing a search, search the current folder by default
          FXDefaultSearchScope = "SCcf";
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.spaces" = {
          "spans-displays" = 0; # Display have seperate spaces
        };
        "com.apple.SafariTechnologyPreview" = {
          AlwaysRestoreSessionAtLaunch = 1;
          AutoFillCreditCardData = 1;
          AutoFillMiscellaneousForms = 1;
          AutoOpenSafeDownloads = 0;
          EnableNarrowTabs = 1;
          ExcludePrivateWindowWhenRestoringSessionAtLaunch = 1;
          ExtensionsEnabled = 1;
          HideHighlightsEmptyItemViewPreferenceKey = 1;
          HideStartPageFrecentsEmptyItemView = 1;
          HomePage = "";
          NeverUseBackgroundColorInToolbar = 0;
          NewTabBehavior = 1;
          NewTabPageSetByUserGesture = 1;
          NewWindowBehavior = 1;
          OpenPrivateWindowWhenNotRestoringSessionAtLaunch = 0;
          PrivateBrowsingRequiresAuthentication = 1;
          PrivateSearchEngineUsesNormalSearchEngineToggle = 1;
          SearchProviderShortName = "DuckDuckGo";
          ShowFavoritesUnderSmartSearchField = 0;
          ShowFullURLInSmartSearchField = 1;
          ShowOverlayStatusBar = 1;
          ShowSidebarInNewWindows = 0;
          ShowSidebarInTopSites = 0;
          ShowStandaloneTabBar = 0;
          SidebarSplitViewDividerPosition = 240;
          SidebarTabGroupHeaderExpansionState = 1;
          SuppressSearchSuggestions = 1;
          TechnologyPreviewSafariSyncEnabled = 1;
          UserStyleSheetEnabled = 0;
          WebKitDefaultTextEncodingName = "utf-8";
          WebKitDeveloperExtrasEnabledPreferenceKey = 1;
          WebKitMinimumFontSize = 9;
          "WebKitPreferences.allowsPictureInPictureMediaPlayback" = 1;
          "WebKitPreferences.applePayEnabled" = 1;
          "WebKitPreferences.defaultTextEncodingName" = "utf-8";
          "WebKitPreferences.developerExtrasEnabled" = 1;
          "WebKitPreferences.hiddenPageDOMTimerThrottlingAutoIncreases" = 1;
          "WebKitPreferences.invisibleMediaAutoplayNotPermitted" = 1;
          "WebKitPreferences.javaScriptCanOpenWindowsAutomatically" = 1;
          "WebKitPreferences.minimumFontSize" = 9;
          "WebKitPreferences.needsSiteSpecificQuirks" = 1;
          "WebKitPreferences.needsStorageAccessFromFileURLsQuirk" = 0;
          "WebKitPreferences.pushAPIEnabled" = 1;
          "WebKitPreferences.shouldAllowUserInstalledFonts" = 0;
          "WebKitPreferences.shouldSuppressKeyboardInputDuringProvisionalNavigation" = 1;
          WebKitRespectStandardStyleKeyEquivalents = 1;
          WebKitUseSiteSpecificSpoofing = 1;
          "com.apple.Safari.WebInspectorPageGroupIdentifier.WebKit2InspectorAttachedWidth" = 1098;
          "com.apple.Safari.WebInspectorPageGroupIdentifier.WebKit2InspectorAttachmentSide" = 1;
        };
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
          StandardHideDesktopIcons = 0; # Show items on desktop
          HideDesktop = 0; # Do not hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
          GloballyEnabled = 0;
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
        # For keys mapping, see this https://github.com/LnL7/nix-darwin/pull/636/commits/5540307d0e02cf1ee235abf16a8111dfeae5bcde
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Save picture of selected area as file (shift + cmd + 4)
            "30" = {
              enabled = 1;
              value = {
                parameters = [
                  52
                  21
                  1179648
                ];
                type = "standard";
              };
            };
            # Screenshot and recording options (shift + cmd + 5)
            "184" = {
              enabled = 1;
              value = {
                parameters = [
                  53
                  23
                  1179648
                ];
                type = "standard";
              };
            };
            # Switch next input (ctrl + enter)
            "60" = {
              enabled = 1;
              value = {
                parameters = [
                  65535
                  36
                  262144
                ];
                type = "standard";
              };
            };
            # Disable Spotlight search (cmd + enter)
            "64" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  36
                  1048576
                ];
                type = "standard";
              };
            };
          };
        };
        # To find out all of the available settings, use
        # `defaults read com.raycast.macos``
        "com.raycast.macos" = {
          "NSStatusItem Visible raycastIcon" = 1;
          commandsPreferencesExpandedItemIds = [
            # "builtin_package_navigation"
            "builtin_package_scriptCommands"
            "builtin_package_floatingNotes"
          ];
          "emojiPicker_skinTone" = "light"; # normal | light | mediumLight
          initialSpotlightHotkey = "Command-Control-Option-Shift-36";
          navigationCommandStyleIdentifierKey = "vim"; # legacy | vim
          "onboarding_canShowActionPanelHint" = 0;
          "onboarding_canShowBackNavigationHint" = 0;
          "onboarding_completedTaskIdentifiers" = [
            "startWalkthrough"
            "calendar"
            "setHotkeyAndAlias"
            "snippets"
            "quicklinks"
            "installFirstExtension"
            "floatingNotes"
            "windowManagement"
            "calculator"
            "raycastShortcuts"
            "openActionPanel"
          ];
          organizationsPreferencesTabVisited = 1;
          popToRootTimeout = 60;
          useHyperKeyIcon = true;
          raycastAPIOptions = 8;
          raycastGlobalHotkey = "Command-Control-Option-Shift-36";
          raycastPreferredWindowMode = "compact"; # compact | default
          raycastShouldFollowSystemAppearance = 1;
          raycastWindowPresentationMode = 1;
          showGettingStartedLink = 0;
          "store_termsAccepted" = 1;
          suggestedPreferredGoogleBrowser = 1;
          "permissions.folders.read:/Users/${username}/Desktop" = 1;
          "permissions.folders.read:/Users/${username}/Documents" = 1;
          "permissions.folders.read:/Users/${username}/Downloads" = 1;
          "permissions.folders.read:cloudStorage" = 1;
        };
        "com.superultra.Homerow" = {
          "enable-hyper-key" = 0;
          "is-auto-click-enabled" = 0;
          "label-characters" = "aoeuidhtns";
          "launch-at-login" = 1;
          "non-search-shortcut" = "\\U2303\\U2325\\U21e7\\U2318U";
          "scroll-keys" = "hjkl";
          "scroll-shortcut" = "\\U2303\\U2325\\U21e7\\U2318E";
          "search-shortcut" = "";
          "show-menubar-icon" = 0;
          "theme-id" = "dark";
        };
      };

    };

    # keyboard settings is not very useful on macOS
    # the most important thing is to remap option key to alt key globally,
    # but it's not supported by macOS yet.
    keyboard = {
      enableKeyMapping = false; # enable key mapping so that we can use `option` as `control`

      # NOTE: do NOT support remap capslock to both control and escape at the same time
      remapCapsLockToControl = false; # remap caps lock to control, useful for emac users
      remapCapsLockToEscape = false; # remap caps lock to escape, useful for vim users

      # swap left command and left alt 
      # so it matches common keyboard layout: `ctrl | command | alt`
      #
      # disabled, caused only problems!
      swapLeftCommandAndLeftAlt = false;
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  environment.loginShell = pkgs.fish;
  environment.loginShellInit = ''
    export SHELL=${pkgs.fish}/bin/fish
  '';
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/run/current-system/sw/bin"
  ];
  environment.pathsToLink = [
    "/Applications"
    "/share/fish"
  ];

  # Set your time zone.
  time.timeZone = "Asia/Kuala_Lumpur";

  # Fonts
  fonts = {
    packages = with pkgs; [
      # # icon fonts
      # material-design-icons
      # font-awesome

      # nerdfonts
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/data/fonts/nerdfonts/shas.nix
      (nerdfonts.override {
        fonts = [
          # symbols icon only
          "NerdFontsSymbolsOnly"
          # Characters
          # "FiraCode"
          "JetBrainsMono"
          # "Iosevka"
        ];
      })
    ];
  };
}
