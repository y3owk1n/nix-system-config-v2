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
      # launchers
      hyper - b : open -a Safari
      hyper - 1 : open -a Safari

      hyper - t : open -a Ghostty
      hyper - 2 : open -a Ghostty

      hyper - n : open -a Notes
      hyper - m : open -a Mail
      hyper - w : open -a WhatsApp
      hyper - f : open -a Finder
      hyper - s : open -a "System Settings"
      hyper - p : open -a Passwords

      # spotlight
      hyper - return : skhd --key "cmd - space"
    '';
  };
}
