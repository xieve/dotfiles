{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions =
        (with vscode-extensions; [
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
          redhat.vscode-yaml
          svelte.svelte-vscode
          tamasfe.even-better-toml
          timonwong.shellcheck
          xadillax.viml
          xyz.local-history
        ])
        ++ (with vscode-marketplace; [
        ]);
    })
  ];
}
