{
  pkgs,
  ...
}:

let
  inherit (pkgs) system;

  version = "1.15.6";

  cpenvInfo = {
    "x86_64-linux" = {
      url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-linux-amd64";
      # use `nix hash convert --hash-algo sha256 <checksum>`
      # even better "awk '{print $1}' <checksum> | xagrs nix hash convert --hash-algo sha256"
      sha256 = "sha256-irWG6iLNxDAgbe7M21iT7cnXyZZlP82miAURK2kzpUg=";
    };
    "aarch64-linux" = {
      url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-linux-arm64";
      sha256 = "sha256-mHxd8eXFDnES1olcw1D+jKH3TeKtHZUb0r0SHzhZwfw=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-darwin-amd64";
      sha256 = "sha256-bb231Ur5ckIniQRupjyObS2SdGdIxOU6slfcrWXlPFc=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-darwin-arm64";
      sha256 = "sha256-mxb5cVZ2/ycAFW/gz+SjX7Ru9FfoguaL08VsXKaX+Ys=";
    };
  };

  cpenvMeta = cpenvInfo.${system} or (throw "Unsupported system: ${system}");

  cpenv = pkgs.stdenv.mkDerivation {
    name = "cpenv";
    src = pkgs.fetchurl {
      inherit (cpenvMeta) url sha256;
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/cpenv
      chmod +x $out/bin/cpenv

      mkdir -p $out/share/fish/vendor_completions.d
      HOME=$(mktemp -d) $out/bin/cpenv completion fish > $out/share/fish/vendor_completions.d/cpenv.fish
    '';
  };
in
{
  home.packages = [
    cpenv
  ];
}
