{ pkgs, config, ... }:
let
  tmuxSessionizer = pkgs.stdenv.mkDerivation {
    pname = "tmux-sessionizer";
    version = "1.0";
    src = ../../scripts/tmux-sessionizer.sh;
    # skip all the build phases, just install
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      install -m755 "$src" $out/bin/tms
    '';
  };
in
{
  environment.systemPackages = [
    tmuxSessionizer
  ];
}
