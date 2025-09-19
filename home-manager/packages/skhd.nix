{ pkgs, ... }:
let
  skhd = pkgs.stdenv.mkDerivation rec {
    pname = "skhd-zig";
    version = "0.0.13";

    src = pkgs.fetchzip {
      url = "https://github.com/jackielii/skhd.zig/releases/download/v${version}/skhd-arm64-macos.tar.gz";
      sha256 = "sha256-ZT8upVH8XDcBGniwuM/Wrj+zlFlwXdsi3bcRPWqTmok=";
      stripRoot = false;
    };

    phases = [ "installPhase" ];

    dontBuild = true; # nothing to compile

    installPhase = ''
      mkdir -p $out/bin
      cp $src/skhd-arm64-macos $out/bin/skhd
      chmod +x $out/bin/skhd
    '';

    meta = {
      mainProgram = "skhd";
    };
  };
in
{
  services.skhd = {
    enable = false;
    package = skhd;
    config = ''
      .shell "/bin/dash"

      .define open_hide : open -a "{{1}}" && until pgrep -f "{{1}}" > /dev/null; do sleep 0.1; done && /etc/profiles/per-user/kylewong/bin/skhd --key "cmd + alt - h"

      # launchers
      hyper - b : @open_hide("safari")
      hyper - 1 : @open_hide("safari")

      hyper - t : @open_hide("ghostty")
      hyper - 2 : @open_hide("ghostty")

      hyper - n : @open_hide("notes")
      hyper - m : @open_hide("mail")
      hyper - w : @open_hide("WhatsApp")
      hyper - f : @open_hide("Finder")
      hyper - s : @open_hide("System Settings")
      hyper - p : @open_hide("Passwords")

      # spotlight
      hyper - return : /etc/profiles/per-user/kylewong/bin/skhd --key "cmd - space"

      # window management
      ctrl + shift - m : /etc/profiles/per-user/kylewong/bin/skhd --key "fn + ctrl - f"
      ctrl + shift - h : osascript -e 'tell application "System Events" to tell (first application process whose frontmost is true) to click menu item "Left" of menu 1 of menu item "Move & Resize" of menu "Window" of menu bar 1'
      ctrl + shift - l : osascript -e 'tell application "System Events" to tell (first application process whose frontmost is true) to click menu item "Right" of menu 1 of menu item "Move & Resize" of menu "Window" of menu bar 1'
      ctrl + shift - j : osascript -e 'tell application "System Events" to tell (first application process whose frontmost is true) to click menu item "Bottom" of menu 1 of menu item "Move & Resize" of menu "Window" of menu bar 1'
      ctrl + shift - k : osascript -e 'tell application "System Events" to tell (first application process whose frontmost is true) to click menu item "Top" of menu 1 of menu item "Move & Resize" of menu "Window" of menu bar 1'
    '';
  };
}
