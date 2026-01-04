# Setup
```bash
cd ~
git pull https://gitlab.com/xieve/dotfiles .dotfiles
.dotfiles/install
# if on nixos:
    sudo nixos-rebuild --flake .dotfiles/nixos#hostname switch
# else:
    chsh -s $(which zsh)
```

# Theming
## [Flavours](https://github.com/Misterio77/flavours)
Was used to generate all theming in this repo. I am using `base16-material-vivid`.

Currently [somewhat unmaintained](https://github.com/Misterio77/flavours/issues/79), workaround was established. Use
```bash
flavours update templates && flavours update schemes
```
instead of `flavours update all`, otherwise the workaround will be overwritten.

## [Tmuxline](https://github.com/edkolev/tmuxline.vim)
In case the Tmux theme is broken, you can regenerate it with:
```bash
tmux new "vim -c \"packadd tmuxline.vim\" -c \"Tmuxline airline\" -c \"TmuxlineSnapshot! ~/.dotfiles/tmuxline.theme\" -c q"
```
This is automatically executed by flavours and should usually not be necessary.

## Firefox transparency fix
This script needs to be installed via Violentmonkey:

1. Install the Violentmonkey extension (other userscript frameworks like
GreaseMonkey might work, but aren't tested.)
2. Open [firefox/transparent-browser-fix.user.js](https://gitlab.com/xieve/dotfiles/-/raw/master/firefox/transparent-browser-fix.user.js)
3. Click "Install"

