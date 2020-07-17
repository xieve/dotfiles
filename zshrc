# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# OhMyZsh
DOTFILES=$HOME/.dotfiles
ZSH=$DOTFILES/ohmyzsh
ZSH_THEME="powerlevel10k/powerlevel10k"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="true"
HIST_STAMPS="yyyy-mm-dd"
ZSH_CUSTOM=$DOTFILES/zsh
plugins=(
        git
        zsh-autosuggestions
        zsh-syntax-highlighting
        )

# Load zmv, a powerful mv with batch capabilities
autoload -Uz zmv

# Vi mode
bindkey -v

source $ZSH/oh-my-zsh.sh
