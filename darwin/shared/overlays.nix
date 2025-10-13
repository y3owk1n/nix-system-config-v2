{
  nixos-npm-ls,
  ...
}:
{
  nixpkgs.overlays = [
    (final: prev: {
      hammerspoon = final.callPackage ../overlays/hammerspoon.nix { };
    })
  ]
  ++ nixos-npm-ls.overlays;
}
