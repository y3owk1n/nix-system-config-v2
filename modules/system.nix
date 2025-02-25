{
  config,
  pkgs,
  hostname,
  ...
}:
let
  safariKeys =
    if hostname == "Kyles-iMac" then
      {
        # work computer
        "New Toy Garden 2 Window" = "^3";
        "New Toy Garden Window" = "^2";
        "New Traworld Window" = "^1";
      }
    else
      {
        # personal computer
        "New Traworld Window" = "^4";
        "New SKBA Window" = "^3";
        "New MDA Window" = "^2";
        "New Kyle Window" = "^1";
      };
in
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
    stateVersion = 5;
    activationScripts.extraActivation.enable = true;
    activationScripts.extraActivation.text = ''
      echo "Activating extra preferences..."
      # Close any open System Preferences panes, to prevent them from overriding
      # settings we’re about to change
      osascript -e 'tell application "System Settings" to quit'
    '';
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

      # NOTE: Do not delete this! Uncomment this when you want to use spotlight search
      # This will enable spotlight search to index installed apps
      apps_source="${config.system.build.applications}/Applications"
      moniker="Nix Trampolines"
      app_target_base="$HOME/Applications"
      app_target="$app_target_base/$moniker"
      mkdir -p "$app_target"
      ${pkgs.rsync}/bin/rsync --archive --checksum --chmod=-w --copy-unsafe-links --delete "$apps_source/" "$app_target"
    '';

    defaults = {
      universalaccess.reduceMotion = true;

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
        QuitMenuItem = true;
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

      WindowManager = {
        EnableStandardClickToShowDesktop = false; # Click wallpaper to reveal desktop
        GloballyEnabled = false;
        HideDesktop = true; # Do not hide items on desktop & stage manager
        StageManagerHideWidgets = true;
        StandardHideDesktopIcons = true; # Show items on desktop
        StandardHideWidgets = true;
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
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          # AppleSpacesSwitchOnActivate = true;
          "com.apple.mouse.scaling" = 9;
          AppleLanguages = [
            "en-US"
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
          ShowOverlayStatusBar = 1;
          ShowSidebarInNewWindows = 0;
          ShowSidebarInTopSites = 0;
          ShowStandaloneTabBar = 0;
          SidebarSplitViewDividerPosition = 240;
          SidebarTabGroupHeaderExpansionState = 1;
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
          } // safariKeys;
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
        # Basically disable everything and only left a few that I want
        # For keys mapping, see this https://github.com/LnL7/nix-darwin/pull/636/commits/5540307d0e02cf1ee235abf16a8111dfeae5bcde
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Action not defined
            "10" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  96
                  8650752
                ];
                type = "standard";
              };
            };
            "11" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  97
                  8650752
                ];
                type = "standard";
              };
            };
            "118" = {
              enabled = 1;
              value = {
                parameters = [
                  49
                  18
                  1966080
                ];
                type = "standard";
              };
            };
            "119" = {
              enabled = 1;
              value = {
                parameters = [
                  50
                  19
                  1966080
                ];
                type = "standard";
              };
            };
            "12" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  122
                  8650752
                ];
                type = "standard";
              };
            };
            "120" = {
              enabled = 1;
              value = {
                parameters = [
                  51
                  20
                  1966080
                ];
                type = "standard";
              };
            };
            "121" = {
              enabled = 1;
              value = {
                parameters = [
                  52
                  21
                  1966080
                ];
                type = "standard";
              };
            };
            "122" = {
              enabled = 1;
              value = {
                parameters = [
                  53
                  23
                  1966080
                ];
                type = "standard";
              };
            };
            "123" = {
              enabled = 1;
              value = {
                parameters = [
                  54
                  22
                  1966080
                ];
                type = "standard";
              };
            };
            "124" = {
              enabled = 1;
              value = {
                parameters = [
                  55
                  26
                  1966080
                ];
                type = "standard";
              };
            };
            "13" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  98
                  8650752
                ];
                type = "standard";
              };
            };
            # contextual menu
            "159" = {
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
            "162" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  96
                  9961472
                ];
                type = "standard";
              };
            };
            # Action not defined
            "175" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
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
            # quick note
            "190" = {
              enabled = 1;
              value = {
                parameters = [
                  110
                  45
                  1966080
                ];
                type = "standard";
              };
            };
            "21" = {
              enabled = 0;
              value = {
                parameters = [
                  56
                  28
                  1835008
                ];
                type = "standard";
              };
            };
            "215" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "216" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "217" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "218" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "219" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "222" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "223" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "224" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "225" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "226" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "227" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "228" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "229" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "230" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "231" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "232" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  65535
                  0
                ];
                type = "standard";
              };
            };
            "25" = {
              enabled = 0;
              value = {
                parameters = [
                  46
                  47
                  1835008
                ];
                type = "standard";
              };
            };
            "26" = {
              enabled = 0;
              value = {
                parameters = [
                  44
                  43
                  1835008
                ];
                type = "standard";
              };
            };
            "27" = {
              enabled = 1;
              value = {
                parameters = [
                  96
                  50
                  1048576
                ];
                type = "standard";
              };
            };
            "28" = {
              enabled = 1;
              value = {
                parameters = [
                  51
                  20
                  1179648
                ];
                type = "standard";
              };
            };
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
            "32" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  126
                  8650752
                ];
                type = "standard";
              };
            };
            "33" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  125
                  8650752
                ];
                type = "standard";
              };
            };
            "36" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  103
                  8388608
                ];
                type = "standard";
              };
            };
            "52" = {
              enabled = 0;
              value = {
                parameters = [
                  100
                  2
                  1572864
                ];
                type = "standard";
              };
            };
            "53" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  107
                  8388608
                ];
                type = "standard";
              };
            };
            "54" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  113
                  8388608
                ];
                type = "standard";
              };
            };
            "57" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  100
                  8650752
                ];
                type = "standard";
              };
            };
            "59" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  96
                  9437184
                ];
                type = "standard";
              };
            };
            # Switch previous input (ctrl + space)
            "60" = {
              enabled = 1;
              value = {
                parameters = [
                  32
                  49
                  262144
                ];
                type = "standard";
              };
            };
            # Switch next input (ctrl + space)
            "61" = {
              enabled = 0;
              value = {
                parameters = [
                  32
                  49
                  262144
                ];
                type = "standard";
              };
            };
            # Spotlight search (hyper + enter)
            "64" = {
              enabled = 1;
              value = {
                parameters = [
                  65535
                  36
                  1966080
                ];
                type = "standard";
              };
            };
            "65" = {
              enabled = 0;
              value = {
                parameters = [
                  32
                  49
                  1572864
                ];
                type = "standard";
              };
            };
            "7" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  120
                  8650752
                ];
                type = "standard";
              };
            };
            "79" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  123
                  8650752
                ];
                type = "standard";
              };
            };
            "8" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  99
                  8650752
                ];
                type = "standard";
              };
            };
            "81" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  124
                  8650752
                ];
                type = "standard";
              };
            };
            "9" = {
              enabled = 0;
              value = {
                parameters = [
                  65535
                  118
                  8650752
                ];
                type = "standard";
              };
            };
            "98" = {
              enabled = 1;
              value = {
                parameters = [
                  47
                  44
                  1179648
                ];
                type = "standard";
              };
            };
          };
        };
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
        "com.apple.Spotlight" = {
          orderedItems = [
            {
              enabled = 1;
              name = "APPLICATIONS";
            }
            {
              enabled = 0;
              name = "DIRECTORIES";
            }
            {
              enabled = 0;
              name = "PDF";
            }
            {
              enabled = 0;
              name = "DOCUMENTS";
            }
            {
              enabled = 0;
              name = "PRESENTATIONS";
            }
            {
              enabled = 0;
              name = "SPREADSHEETS";
            }
            {
              enabled = 0;
              name = "MENU_OTHER";
            }
            {
              enabled = 0;
              name = "CONTACT";
            }
            {
              enabled = 0;
              name = "IMAGES";
            }
            {
              enabled = 0;
              name = "MESSAGES";
            }
            {
              enabled = 1;
              name = "SYSTEM_PREFS";
            }
            {
              enabled = 0;
              name = "EVENT_TODO";
            }
            {
              enabled = 1;
              name = "MENU_CONVERSION";
            }
            {
              enabled = 1;
              name = "MENU_EXPRESSION";
            }
            {
              enabled = 0;
              name = "FONTS";
            }
            {
              enabled = 0;
              name = "BOOKMARKS";
            }
            {
              enabled = 0;
              name = "MUSIC";
            }
            {
              enabled = 0;
              name = "MOVIES";
            }
            {
              enabled = 0;
              name = "SOURCE";
            }
            {
              enabled = 0;
              name = "TIPS";
            }
            {
              enabled = 0;
              name = "MENU_DEFINITION";
            }
            {
              enabled = 0;
              name = "MENU_WEBSEARCH";
            }
            {
              enabled = 0;
              name = "MENU_SPOTLIGHT_SUGGESTIONS";
            }
          ];
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
  security.pam.services.sudo_local.touchIdAuth = true;

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.fish.enable = true;
  # environment.shells = [ pkgs.fish ];

  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/run/current-system/sw/bin"
  ];

  # Set your time zone.
  time.timeZone = "Asia/Kuala_Lumpur";

  # Fonts
  fonts = {
    packages = with pkgs; [
      poppins
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
    ];
  };
}
