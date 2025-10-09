{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    # kanata
    # NOTE: Do not delete this, just comment it out
    # This is the right way to override a rust package after all the researches
    (kanata.overrideAttrs (
      finalAttrs: prevAttrs: {
        cargoHash = "sha256-U6qBHWp4Hh2XRH9XR32CYeGbuKTIaEk2NDCQU5obMGc=";
        src = fetchFromGitHub {
          owner = "jtroo";
          repo = "kanata";
          rev = "v1.10.0-prerelease-1";
          sha256 = "sha256-8CpHz7bHHhzsR8bLu0GGH+vzHGZvdosrKpHepo9iHDM=";
        };
        version = "1.10.0-prerelease-1";
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
