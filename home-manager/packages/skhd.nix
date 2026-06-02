{ pkgs, ... }:
let
  skhd = pkgs.stdenv.mkDerivation rec {
    pname = "skhd-zig";
    version = "0.1.7";

    src = pkgs.fetchurl {
      url = "https://github.com/jackielii/skhd.zig/releases/download/v${version}/skhd-arm64-macos.tar.gz";
      sha256 = "sha256-pk1/rj20tQ1BFwCln7SCa42WVxlOw5NY1hrinvkDlWE=";
    };

    nativeBuildInputs = [
      pkgs.installShellFiles
    ];

    phases = [
      "unpackPhase"
      "installPhase"
    ];

    unpackPhase = ''
      tar -xvf $src
    '';

    dontBuild = true; # nothing to compile

    installPhase = ''
      mkdir -p $out/Applications
      mv skhd.app $out/Applications

      mkdir -p $out/bin
      ln -s $out/Applications/skhd.app/Contents/MacOS/skhd $out/bin/skhd
      ln -s $out/Applications/skhd.app/Contents/MacOS/skhd-grabber $out/bin/skhd-grabber
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
      hyper - b : @open("safari")
      hyper - t : @open("ghostty")
      hyper - n : @open("notes")
      hyper - r : @open("reminders")
      hyper - m : @open("mail")
      hyper - c : @open("calendar")
      hyper - w : @open("WhatsApp")
      hyper - p : @open("Passwords")
      hyper - s : @open("System Settings")
      hyper - a : @open("Activity Monitor")

      hyper - 1 : yabai -m space --focus 1
      hyper - 2 : yabai -m space --focus 2
      hyper - 3 : yabai -m space --focus 3
      hyper - 4 : yabai -m space --focus 4
      hyper - 5 : yabai -m space --focus 5
      hyper - 6 : yabai -m space --focus 6
      hyper - 7 : yabai -m space --focus 7
      hyper - 8 : yabai -m space --focus 8
      hyper - 9 : yabai -m space --focus 9

      alt + shift - 1 : yabai -m window --space 1; yabai -m space --focus 1
      alt + shift - 2 : yabai -m window --space 2; yabai -m space --focus 2
      alt + shift - 3 : yabai -m window --space 3; yabai -m space --focus 3
      alt + shift - 4 : yabai -m window --space 4; yabai -m space --focus 4
      alt + shift - 5 : yabai -m window --space 5; yabai -m space --focus 5
      alt + shift - 6 : yabai -m window --space 6; yabai -m space --focus 6
      alt + shift - 7 : yabai -m window --space 7; yabai -m space --focus 7
      alt + shift - 8 : yabai -m window --space 8; yabai -m space --focus 8
      alt + shift - 9 : yabai -m window --space 9; yabai -m space --focus 9

      alt - h : yabai -m window --focus west
      alt - j : yabai -m window --focus south
      alt - k : yabai -m window --focus north
      alt - l : yabai -m window --focus east

      alt + shift - h : yabai -m window --swap west
      alt + shift - j : yabai -m window --swap south
      alt + shift - k : yabai -m window --swap north
      alt + shift - l : yabai -m window --swap east

      alt - m : yabai -m window --toggle zoom-fullscreen
      alt - f : yabai -m window --toggle float
    '';
  };
}
