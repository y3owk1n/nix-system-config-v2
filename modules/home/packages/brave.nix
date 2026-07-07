{ pkgs, ... }: {
  programs.chromium = {
    enable = true;
    package = pkgs.brave;

    extensions = [
      { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React DevTools
      { id = "pejdijmoenmkgeppbflobdenhhabjlaj"; } # iCloud Passwords
      { id = "ldgfbffkinooeloadekpmfoklnobpien"; } # Raindrop.io
      { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
    ];

    commandLineArgs = [
      "--disable-features=BraveRewards,BraveNews,AIChat,BraveVPN,IPFS,Solana"
    ];

    dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
  };
}
