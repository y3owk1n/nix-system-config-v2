{ pkgs, ... }:
let
  skhd-zig = pkgs.stdenv.mkDerivation rec {
    pname = "skhd-zig";
    version = "0.0.12";

    src = pkgs.fetchzip {
      url = "https://github.com/jackielii/skhd.zig/releases/download/v${version}/skhd-arm64-macos.tar.gz";
      sha256 = "sha256-qJt2wWfM7YYVfWPbaGJ5w2LbWDhhN2MBvs+m0PCeLqM=";
      stripRoot = false;
    };

    phases = [ "installPhase" ];

    dontBuild = true; # nothing to compile

    installPhase = ''
      mkdir -p $out/bin
      cp $src/skhd-arm64-macos $out/bin/skhd
      chmod +x $out/bin/skhd
    '';
  };
in
{
  # NOTE: Needs to re-grant accessibility permissions after hash updated
  #
  # ensure the service is running
  # launchctl list | grep skhd
  #
  # use the following commands to restart the service or `just relaunch-skhd`
  # launchctl bootout gui/$(id -u)/org.nixos.skhd && \
  # launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nixos.skhd.plist
  services.skhd = {
    enable = true;
    package = skhd-zig; # <-- Zig rewrite
    skhdConfig = ''
      # launchers
      hyper - b : open -a Safari
      hyper - t : open -a Ghostty
      hyper - n : open -a Notes
      hyper - m : open -a Mail
      hyper - w : open -a WhatsApp
      hyper - f : open ~
      hyper - s : open -a "System Settings"

      # spotlight
      hyper - return : skhd --key "cmd - space"
    '';
  };
}
