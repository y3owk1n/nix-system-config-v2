{ pkgs, ... }:
let
  skhd = pkgs.stdenv.mkDerivation rec {
    pname = "skhd-zig";
    version = "0.0.15";

    src = pkgs.fetchzip {
      url = "https://github.com/jackielii/skhd.zig/releases/download/v${version}/skhd-arm64-macos.tar.gz";
      sha256 = "sha256-6ffSUWdEhtSnZOxb8lYxtHAoJaPIbojl/C1C19J4BIU=";
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

      .define open : open -a "{{1}}"

      # launchers
      hyper - f : @open("finder")
      hyper - b : @open("firefox")
      hyper - t : @open("ghostty")
      hyper - n : @open("notes")
      hyper - m : @open("mail")
      hyper - c : @open("calendar")
      hyper - w : @open("WhatsApp")
      hyper - s : @open("System Settings")
      hyper - p : @open("Passwords")
      hyper - a : @open("Activity Monitor")
    '';
  };
}
