{
  inputs,
  ...
}:

{
  flake.homeModules.shared =
    {
      username,
      useremail,
      hostname,
      githubuser,
      githubname,
      gpgkeyid,
      needsNixGL ? false,
      ...
    }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
      };
      home-manager.extraSpecialArgs = (builtins.removeAttrs inputs [ "self" ]) // {
        inherit
          username
          useremail
          hostname
          githubuser
          githubname
          gpgkeyid
          needsNixGL
          ;
      };
    };
}
