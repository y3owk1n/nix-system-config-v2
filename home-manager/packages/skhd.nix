{ pkgs, ... }:
let
  skhd = pkgs.stdenv.mkDerivation rec {
    pname = "skhd-zig";
    version = "0.1.9";

    src = pkgs.fetchurl {
      url = "https://github.com/jackielii/skhd.zig/releases/download/v${version}/skhd-arm64-macos.tar.gz";
      sha256 = "sha256-CE5qZkDkm37iAtQwueiitmIQ/4RcdmZKJ4pUqDgam9Q=";
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
    enable = true;
    package = skhd;
    config = ''
      .shell "/bin/dash"

      .define open : open -a "{{1}}"
      .define mimi_space : mimi action space "{{1}}"
      .define mimi_move : mimi action move_window_to_space "{{1}}" && mimi action space "{{1}}"
      .define mimi_resize : mimi action resize_window "{{1}}"
      .define mimi_focus : mimi action focus_window "{{1}}"

      # launchers
      hyper - f : @open("finder")
      hyper - b : @open("safari")
      # hyper - b : @open("helium")
      # hyper - b : @open("Brave Browser")
      hyper - t : @open("ghostty")
      hyper - n : @open("notes")
      hyper - r : @open("reminders")
      hyper - m : @open("mail")
      hyper - c : @open("calendar")
      hyper - w : @open("WhatsApp")
      hyper - p : @open("Passwords")
      hyper - s : @open("System Settings")
      hyper - a : @open("Activity Monitor")

      hyper - 1 : @mimi_space("1")
      hyper - 2 : @mimi_space("2")
      hyper - 3 : @mimi_space("3")
      hyper - 4 : @mimi_space("4")
      hyper - 5 : @mimi_space("5")
      hyper - 6 : @mimi_space("6")
      hyper - 7 : @mimi_space("7")
      hyper - 8 : @mimi_space("8")
      hyper - 9 : @mimi_space("9")

      alt + shift - 1 : @mimi_move("1")
      alt + shift - 2 : @mimi_move("2")
      alt + shift - 3 : @mimi_move("3")
      alt + shift - 4 : @mimi_move("4")
      alt + shift - 5 : @mimi_move("5")
      alt + shift - 6 : @mimi_move("6")
      alt + shift - 7 : @mimi_move("7")
      alt + shift - 8 : @mimi_move("8")
      alt + shift - 9 : @mimi_move("9")

      alt - h : @mimi_focus("--left")
      alt - l : @mimi_focus("--right")
      alt - j : @mimi_focus("--down")
      alt - k : @mimi_focus("--up")
      alt - tab : @mimi_focus("")
      alt + shift - tab : @mimi_focus("--backward")

      alt + shift - c : @mimi_resize("center")
      alt + shift - f : @mimi_resize("fill")
      alt + shift - h : @mimi_resize("left-half")
      alt + shift - l : @mimi_resize("right-half")
      alt + shift - j : @mimi_resize("bottom-half")
      alt + shift - k : @mimi_resize("top-half")
    '';
  };
}
