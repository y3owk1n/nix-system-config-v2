# TODO: This is a temporary module to install marksman
# We should remove this once the dotnet nonsence is gone for darwin
# https://github.com/NixOS/nixpkgs/pull/449614
{
  pkgs,
  ...
}:

let
  system = pkgs.system;

  version = "2024-12-18";

  marksmanInfo = {
    "aarch64-darwin" = {
      url = "https://github.com/artempyanykh/marksman/releases/download/${version}/marksman-macos";
      sha256 = "sha256-fhiAOWYjGjPuEH0NJvabQfLw3BMyxS3ZcpwuKft3voM=";
    };
  };

  marksmanMeta = marksmanInfo.${system} or (throw "Unsupported system: ${system}");

  marksman = pkgs.stdenv.mkDerivation {
    name = "cpenv";
    src = pkgs.fetchurl {
      url = marksmanMeta.url;
      sha256 = marksmanMeta.sha256;
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/marksman
      chmod +x $out/bin/marksman
    '';
  };
in
{
  home.packages = [
    marksman
  ];
}
