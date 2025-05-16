{
  config,
  pkgs,
  lib,
  ...
}:

let
  system = pkgs.system;

  version = "1.15.5";

  inherit (lib) mkIf;
  cpenvInfo = {
    "x86_64-linux" = {
      url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-linux-amd64";
      # use `nix hash convert --hash-algo sha256 <checksum>`
      sha256 = "sha256-aWeGGI4Q8Xa6g8gE+Nvd6dXAwKAJNZSdN6THaoIeMdw=";
    };
    "aarch64-linux" = {
      url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-linux-arm64";
      sha256 = "sha256-YHRNluj1Gh3C5xVHOhO1E4g4QyuL6azn3zo2go2M+vo=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-darwin-amd64";
      sha256 = "sha256-DeXiZjFt7FIgj01NTJytJOh+Wv0+VJd2Bm9hJMgTNuM=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-darwin-arm64";
      sha256 = "sha256-XeZMarfE3eXG5GcxY4SaGqVeX1/9aPRjeF9TpcU+nng=";
    };
  };

  cpenvMeta = cpenvInfo.${system} or (throw "Unsupported system: ${system}");

  cpenv = pkgs.stdenv.mkDerivation {
    name = "cpenv";
    src = pkgs.fetchurl {
      url = cpenvMeta.url;
      sha256 = cpenvMeta.sha256;
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/cpenv
      chmod +x $out/bin/cpenv
    '';
  };
in
{
  home.packages = [
    cpenv
  ];
}
