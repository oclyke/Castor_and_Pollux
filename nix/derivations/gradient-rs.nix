{
  pkgs,
  system,
  ...
}:
let
  tag = "3.0.1";
  url = "https://github.com/fidian/ansi.git";
in
pkgs.rustPlatform.buildRustPackage {
  pname = "gradient";
  version = "0.4.0";

  cargoHash = "sha256-eVX4FV9a4zuh+y8i2au8uet1urVVrMpTpA6VdVpSGfo=";

  src = pkgs.fetchFromGitHub {
    owner = "mazznoer";
    repo = "gradient-rs";
    rev = "v0.4.0";
    hash = "sha256-I/LOBk/NJZYgPDQZjtBP5n2aSvF4lN+kl/8lLkILGTw=";
  };
}
