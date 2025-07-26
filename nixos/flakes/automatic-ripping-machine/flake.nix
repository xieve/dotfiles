{
  description = "Standalone flake for Automatic Ripping Machine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    pydvdid = {
      url = "github:sjwood/pydvdid/v1.1";
      flake = false;
    };
    automatic-ripping-machine = {
      url = "github:xieve/automatic-ripping-machine/main";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, ... }:
    let
      forEachSystem = import ../../systems.nix inputs.nixpkgs;
    in
    {
      packages = forEachSystem (
        { pkgs }:
        rec {
          pydvdid = pkgs.callPackage ./pydvdid.nix { src = inputs.pydvdid; };
          automatic-ripping-machine = pkgs.callPackage ./package.nix {
            inherit pydvdid;
            src = inputs.automatic-ripping-machine;
          };
          default = automatic-ripping-machine;
        }
      );

      nixosModules = rec {
        automatic-ripping-machine = import ./module.nix self;
        default = automatic-ripping-machine;
      };
    };
}
