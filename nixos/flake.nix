{
  description = "xieve's nixos flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixpkgs.url = "github:numtide/nixpkgs-unfree/nixos-unstable";
    nzbr.url = "github:nzbr/nixos";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

    automatic-ripping-machine = {
      url = "github:automatic-ripping-machine/automatic-ripping-machine";
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
      inherit (lib) nixosSystem;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
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

          pkgsDirectory = ./packages;
        };
    };
}
