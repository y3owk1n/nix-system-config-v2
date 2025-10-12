{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    # kanata
    (kanata.overrideAttrs (
      finalAttrs: prevAttrs: {
        cargoHash = "sha256-pEA1i7abdfBjAHwSAjwO4RKlmTMHgeDLBbbfzMbB2xg=";
        src = fetchFromGitHub {
          owner = "jtroo";
          repo = "kanata";
          rev = "v1.10.0-prerelease-2";
          sha256 = "sha256-aQDeMfkb6wjwQ40wP0XE2JcaOrHArvItVfB6QsmVpuc=";
        };
        version = "1.10.0-prerelease-2";
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (finalAttrs) pname src version;
          hash = finalAttrs.cargoHash;
        };
      }
    ))
  ];

  xdg.configFile.kanata = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/kanata";
    # recursive = true;
  };
}
