{
  description = "xieve's nixos flake";

  inputs = {
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixos-hardware-warmplace.url = "github:nixos/nixos-hardware/ca30f8501ab452ca687a7fdcb2d43e1fb1732317";
    nixos-hardware-zerosum.url = "github:nixos/nixos-hardware/19ea375ca73d4ccebd19998cdd4c9b915e0d648c";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    automatic-ripping-machine.url = "github:xieve/automatic-ripping-machine/dev?dir=nixos";

    home-assistant-theme-material-you = {
      url = "github:Nerwyn/material-rounded-theme";
      flake = false;
    };
    home-assistant-lovelace-module-material-you = {
      url = "github:Nerwyn/material-you-utilities";
      flake = false;
    };
    home-assistant-node-red = {
      url = "github:zachowj/hass-node-red";
      flake = false;
    };
    home-assistant-component-scheduler = {
      url = "github:nielsfaber/scheduler-component";
      flake = false;
    };
    home-assistant-card-scheduler = {
      url = "github:nielsfaber/scheduler-card";
      flake = false;
    };
    home-assistant-material-symbols = {
      url = "github:beecho01/material-symbols";
      flake = false;
    };
    # Fasttext language identification model for languagetool
    fasttext-lid = {
      url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin";
      flake = false;
    };
    localtuya = {
      url = "github:rospogrigio/localtuya";
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
      inherit (lib) nixosSystem mapAttrs filterAttrs;
      forEachSystem = import ./systems.nix inputs.nixpkgs;
    in
    {
      nixosConfigurations = {
        zerosum = nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs; # Pass inputs to modules
          modules = [
            ./overlays.nix
            ./gnome.nix
            inputs.nixos-hardware-zerosum.nixosModules.microsoft-surface-pro-intel
            ./zerosum/configuration.nix
          ];
        };
        thegreatbelow = nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;
          modules = [
            inputs.automatic-ripping-machine.nixosModules.default
            ./thegreatbelow/configuration.nix
          ];
        };
        theeaterofdreams = nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;
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
            specialArgs = inputs;
            modules = [
              inputs.nixos-hardware-warmplace.nixosModules.raspberry-pi-4
              ./warmplace/configuration.nix
            ];
          };
      };

      nixosModules = lib.foldl (a: b: a // b) { } (
        map (filename: {
          ${lib.strings.removePrefix "${./modules}/" (lib.strings.removeSuffix ".nix" (toString filename))} =
            args@{ pkgs, ... }: ((import filename) (args // { inherit self; }));
        }) (lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "nix") ./modules))
      );

      packages = forEachSystem (
        { pkgs }:
        filterAttrs (_: lib.isDerivation) (
          lib.packagesFromDirectoryRecursive {
            directory = ./packages;
            callPackage = pkgs.newScope {
              inherit inputs;
            };
          }
        )
      );

      formatter = forEachSystem ({ pkgs }: pkgs.nixfmt-rfc-style);
    };
}
