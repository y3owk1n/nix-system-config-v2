{
  config,
  ...
}:
{
  xdg.configFile.glide = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/glide";
    # recursive = true;
  };

}
