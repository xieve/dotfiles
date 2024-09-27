{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        asvetliakov.vscode-neovim
        christian-kohler.path-intellisense
        davidlday.languagetool-linter
        dbaeumer.vscode-eslint
        eamodio.gitlens
        esbenp.prettier-vscode
        gruntfuggly.todo-tree
        jnoortheen.nix-ide
        mhutchie.git-graph
        ms-python.black-formatter
        ms-python.debugpy
        ms-python.isort
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.hexeditor
        pkief.material-icon-theme
        tamasfe.even-better-toml
        timonwong.shellcheck
        xyz.local-history
      ];
    })
  ];
}
