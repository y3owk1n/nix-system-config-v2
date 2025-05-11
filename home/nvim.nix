{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    lua51Packages.lua
    luajitPackages.luarocks
    panvimdoc
  ];

  xdg.configFile.nvim = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/nvim";
    recursive = true;
  };
}
