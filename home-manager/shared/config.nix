{
  inputs,
  username,
  useremail,
  hostname,
  githubuser,
  githubname,
  gpgkeyid,
  ...
}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bak";
  home-manager.extraSpecialArgs = inputs // {
    inherit
      username
      useremail
      hostname
      githubuser
      githubname
      gpgkeyid
      ;
  };
}
