{
  pkgs,
  system,
  ...
}:
let
  tag = "3.0.1";
  url = "https://github.com/fidian/ansi.git";
in
pkgs.stdenv.mkDerivation rec {
  pname = "ansi";
  version = tag;
  src = pkgs.fetchFromGitHub {
    owner = "fidian";
    repo = "ansi";
    rev = tag;
    sha256 = "sha256-udZ24zsRci0XNfXFb6Nmckzi22EaBVV/51AFkfad5eE=";
  };

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r * $out
    cp $out/ansi $out/bin
    chmod +x $out/bin/ansi
  '';
}
