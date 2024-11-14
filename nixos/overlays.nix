{ pkgs, nix-vscode-extensions, ... }:

{
  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
  ];
}
