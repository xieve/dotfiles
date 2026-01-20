{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      self,
      ...
    }:
    let
      inherit (inputs.nixpkgs) lib;
      forEachSystem = import ./systems.nix inputs.nixpkgs;
    in
    {
      packages = forEachSystem (
        { pkgs }:
        {
          default = pkgs.callPackage ./package.nix { };
        }
      );

      devShells = forEachSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.default ];
            packages = with pkgs; [];
          };
        }
      );

      formatter = forEachSystem ({ pkgs }: pkgs.nixfmt);
    };
}
