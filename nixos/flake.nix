{
  description = "xieve's nixos flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixpkgs.url = "github:numtide/nixpkgs-unfree/nixos-unstable";
    nzbr.url = "github:nzbr/nixos";
  };

  outputs =
    {
      self,
      flake-utils,
      nixos-hardware,
      nixos-wsl,
      nixpkgs,
      nzbr,
    }@attrs:
    let
      inherit (nixpkgs.lib) nixosSystem;
    in
    {
      nixosConfigurations = {
        zerosum = nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-hardware.nixosModules.microsoft-surface-pro-intel
            ./zerosum/configuration.nix
          ];
        };
        thegreatbelow = nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs; # Pass inputs to modules
          modules = [
            nzbr.nixosModules."service/urbackup.nix"
            ./thegreatbelow/configuration.nix
          ];
        };
        theeaterofdreams = nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.wsl
            ./theeaterofdreams/configuration.nix
          ];
        };
        warmplace =
          let
            system = "aarch64-linux";
          in
          nixosSystem {
            inherit system;
            specialArgs = {
              self-pkgs = self.packages.${system};
            };
            modules = [
              nixos-hardware.nixosModules.raspberry-pi-4
              ./warmplace/configuration.nix
            ];
          };
      };
    }

    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        formatter = pkgs.nixfmt-rfc-style;

        packages = nixpkgs.lib.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;
          directory = ./packages;
        };
      }
    );
}
