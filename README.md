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

