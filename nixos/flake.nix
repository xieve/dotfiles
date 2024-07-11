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
    {
      nixosConfigurations = {
        despacito3 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./despacito3/configuration.nix ];
        };
        thegreatbelow = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs; # Pass inputs to modules
          modules = [
            nzbr.nixosModules."service/urbackup.nix"
            ./thegreatbelow/configuration.nix
          ];
        };
        theeaterofdreams = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.wsl
            ./theeaterofdreams/configuration.nix
          ];
        };
        warmplace = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-4
            ./warmplace/configuration.nix
          ];
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    });
}
