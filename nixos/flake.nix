{
  description = "xieve's nixos flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
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
    inputs@{
      self,
      ...
    }:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (lib) nixosSystem;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        nixosConfigurations = {
          zerosum = nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs; # Pass inputs to modules
            modules = [
              ./overlays.nix
              ./gnome.nix
              inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
              ./zerosum/configuration.nix
            ];
          };
          thegreatbelow = nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs;
            modules = [
              inputs.nzbr.nixosModules."service/urbackup.nix"
              ./thegreatbelow/configuration.nix
            ];
          };
          theeaterofdreams = nixosSystem {
            system = "x86_64-linux";
            modules = [
              inputs.nixos-wsl.nixosModules.wsl
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
                inputs.nixos-hardware.nixosModules.raspberry-pi-4
                ./warmplace/configuration.nix
              ];
            };
        };

        nixosModules = lib.foldl (a: b: a // b) { } (
          map (filename: {
            ${lib.strings.removePrefix "${toString ./modules}/" (lib.strings.removeSuffix ".nix" (toString filename))} =
              import filename;
          }) (lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "nix") ./modules))
        );
      };

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-rfc-style;

          packages = lib.packagesFromDirectoryRecursive {
            inherit (pkgs) callPackage;
            directory = ./packages;
          };
        };
    };
}
