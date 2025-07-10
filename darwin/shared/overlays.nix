{
  nixos-npm-ls,
  ...
}:
{
  nixpkgs.overlays = [ ] ++ nixos-npm-ls.overlays;
}
