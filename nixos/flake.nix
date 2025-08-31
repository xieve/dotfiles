{
  description = "xieve's nixos flake";

  inputs = {
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixos-hardware-warmplace.url = "github:nixos/nixos-hardware/ca30f8501ab452ca687a7fdcb2d43e1fb1732317";
    nixos-hardware-zerosum.url = "github:nixos/nixos-hardware/6aabf68429c0a414221d1790945babfb6a0bd068";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    automatic-ripping-machine.url = "github:xieve/automatic-ripping-machine/dev?dir=nixos";

    home-assistant-card-big-slider = {
      url = "github:nicufarmache/lovelace-big-slider-card";
      flake = false;
    };
    home-assistant-theme-bubble = {
      url = "github:Clooos/Bubble";
      flake = false;
    };
    home-assistant-theme-material-you = {
      url = "github:Nerwyn/material-rounded-theme";
      flake = false;
    };
    home-assistant-node-red = {
      url = "github:zachowj/hass-node-red";
      flake = false;
    };
    # Fasttext language identification model for languagetool
    fasttext-lid = {
      url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin";
      flake = false;
    };
    lattice-diamond = {
      url = "https://files.latticesemi.com/Diamond/3.13/diamond_3_13-base-56-2-x86_64-linux.rpm?narHash=sha256-T2b5ulnJJwyljoFc1VvqAOoqPMyyhLKMDe7JrXojs28=";
      flake = false;
    };
    localtuya = {
      url = "github:rospogrigio/localtuya";
      flake = false;
    };
    robobrowser = {
      url = "github:jmcarp/robobrowser/v0.5.3";
      flake = false;
    };
    tinydownload = {
      url = "github:ritiek/tinydownload/d470623b9de4a7469dac2deaf08b73e687fc4cb9";
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
