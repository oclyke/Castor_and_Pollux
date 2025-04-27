{
  description = "castor and pollux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=release-24.11";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      lib = (import nixpkgs { system = "x86_64-linux"; }).lib;
    in
    {
      # Enter a development environment with `nix develop .#<name>`
      # or use the default `nix develop`
      devShells = import ./nix/shells {
        inherit self;
        inherit lib;
        systems = [
          "aarch64-linux"
          "x86_64-linux"
          "aarch64-darwin"
        ];
      };
    };
}
