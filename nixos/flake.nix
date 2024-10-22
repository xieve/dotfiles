{
  description = "xieve's nixos flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixpkgs.url = "github:numtide/nixpkgs-unfree/nixos-unstable";
    nzbr.url = "github:nzbr/nixos";
    # Fasttext language identification model for languagetool
    fasttext-lid = {
      url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin";
      flake = false;
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixos-hardware,
      nixos-wsl,
      nixpkgs,
      nzbr,
      fasttext-lid,
    }@attrs:
    let
      inherit (nixpkgs.lib) nixosSystem;
    in
    {
      nixosConfigurations = {
        zerosum = nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs; # Pass inputs to modules
          modules = [
            ./gnome.nix
            nixos-hardware.nixosModules.microsoft-surface-pro-intel
            ./zerosum/configuration.nix
          ];
        };
        thegreatbelow = nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs;
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
        inherit (nixpkgs) lib;
      in
      {
        formatter = pkgs.nixfmt-rfc-style;

        packages = lib.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;
          directory = ./packages;
        };

        nixosModules = lib.foldl (a: b: a // b) {} (
          map (filename: {
            ${lib.strings.removePrefix "${toString ./modules}/" (lib.strings.removeSuffix ".nix" (toString filename))} = import filename;
          }) (lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "nix") ./modules))
        );
      }
    );
}
