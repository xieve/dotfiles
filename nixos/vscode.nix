{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = vscode.override {
        commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
      };
      vscodeExtensions =
        (with vscode-extensions; [
          asvetliakov.vscode-neovim
          christian-kohler.path-intellisense
          davidlday.languagetool-linter
          dbaeumer.vscode-eslint
          eamodio.gitlens
          esbenp.prettier-vscode
          gruntfuggly.todo-tree
          haskell.haskell
          jnoortheen.nix-ide
          justusadam.language-haskell
          mhutchie.git-graph
          ms-python.black-formatter
          ms-python.debugpy
          ms-python.flake8
          ms-python.isort
          ms-python.python
          ms-python.vscode-pylance
          ms-vscode.hexeditor
          pkief.material-icon-theme
          redhat.vscode-yaml
          svelte.svelte-vscode
          tamasfe.even-better-toml
          timonwong.shellcheck
          tomoki1207.pdf
          xadillax.viml
          xyz.local-history
        ])
        ++ (with vscode-marketplace; [
          dozerg.tsimportsorter
          hbohlin.vhdl-ls
          rutger-de-jong.haskell-interactive
        ]);
    })
    nixd # Dependency for nix-ide
  ];
}
