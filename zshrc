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

ZSH_AUTOSUGGEST_STRATEGY=(
    completion
    match_prev_cmd
    history
)

# If on remote machine, autostart/automagically attach to tmux
[[ "$(hostname)" =~ "server|pi" ]] && ZSH_TMUX_AUTOSTART=true
# TODO: Revert language settings if invoked from inside tmux

# Override KDE's LC_TIME setting (en_SE) because it doesn't exist outside of KDE
export LC_TIME="en_DK.UTF-8"

plugins=(
    zsh-vim-mode
    compleat
    zsh-autosuggestions
    zsh-syntax-highlighting
    alias-finder
    command-not-found
    common-aliases
    git
    mosh
    nmap
    systemd
    tmux
)

# Load zmv, a powerful mv with batch capabilities
autoload -Uz zmv

source $ZSH/oh-my-zsh.sh
