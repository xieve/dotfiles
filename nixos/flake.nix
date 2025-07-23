{
  description = "xieve's nixos flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nzbr.url = "github:nzbr/nixos";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    systems.url = "github:nix-systems/default";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    automatic-ripping-machine = {
      url = "github:xieve/automatic-ripping-machine/main";
      flake = false;
    };
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
      url = "https://files.latticesemi.com/Diamond/3.13/diamond_3_13-base-56-2-x86_64-linux.rpm";
      flake = false;
    };
    localtuya = {
      url = "github:rospogrigio/localtuya";
      flake = false;
    };
    pydvdid = {
      url = "github:sjwood/pydvdid/v1.1";
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
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, inputs, ... }:
      {
        systems = import inputs.systems;

        imports = [
          inputs.pkgs-by-name-for-flake-parts.flakeModule
        ];

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

          overlays.default =
            final: prev:
            withSystem prev.stdenv.hostPlatform.system (
              { config, ... }:
              {
                xieve = config.packages;
              }
            );

          # Hydra CI: Build all systems for x86_64, cross-compilations sucks (because substituters don't work)
          hydraJobs.nixosConfigurations = mapAttrs (_: { config, ... }: config.system.build.toplevel) (
            filterAttrs (_: { pkgs, ... }: pkgs.system == "x86_64-linux") self.nixosConfigurations
          );
        };

        perSystem =
          { pkgs, config, ... }:
          {
            formatter = pkgs.nixfmt-rfc-style;

            pkgsDirectory = ./packages;
          };
      }
    );
}
