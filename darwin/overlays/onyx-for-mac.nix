{
  fetchurl,
  stdenv,
}:
let
  appName = "OnyX.app";
  version = "4.9.1";
in
stdenv.mkDerivation {
  pname = "onyx-for-mac";
  inherit version;

  src = fetchurl {
    url = "https://www.titanium-software.fr/download/26/OnyX.dmg";
    sha256 = "sha256-n686ar10tiFLEBX0d5oA6LHvekq0f8BQTn19DDe3xUo="; # Add your hash here
  };

  sourceRoot = ".";

  unpackCmd = ''
    echo "Creating temp directory"
    mnt=$(TMPDIR=/tmp mktemp -d -t nix-XXXXXXXXXX)
    function finish {
      echo "Ejecting temp directory"
      /usr/bin/hdiutil detach $mnt -force
      rm -rf $mnt
    }
    trap finish EXIT
    echo "Mounting DMG file into \"$mnt\""
    yes | PAGER=cat /usr/bin/hdiutil attach -nobrowse -noverify -noautoopen -mountpoint $mnt $curSrc
    echo 'Copying extracted content'
    cp -a $mnt/${appName} $PWD/
  '';

  installPhase = ''
    mkdir -p "$out/Applications"
    mv ${appName} $out/Applications/
  '';
}
