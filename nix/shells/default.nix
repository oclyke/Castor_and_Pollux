{
  self,
  systems,
  lib,
  ...
}:
let
  cfg = rec {
    default = "hardware";
    names = [
      default
    ];
  };
in
lib.genAttrs systems (
  system:
  let
    pkgs = import self.inputs.nixpkgs { inherit system; };
    shells = lib.genAttrs cfg.names (
      name:
      import ./${name}.nix {
        inherit self;
        inherit system;
        inherit lib;
        pkgs = pkgs;
      }
    );
    defaultShell = shells.${cfg.default};
  in
  shells // { default = defaultShell; }
)
