{
  username,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  homebrew-y3owk1n,
  ...
}:
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "${username}";
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "homebrew/homebrew-bundle" = homebrew-bundle;
      "y3owk1n/tap" = homebrew-y3owk1n;
    };
    mutableTaps = false;
  };
}
