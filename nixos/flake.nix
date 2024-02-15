{
  description = "xieve's nixos flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      despacito3 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./despacito3.nix
        ];
      };
      thegreatbelow = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./thegreatbelow.nix
        ];
      };
    };
  };
}

