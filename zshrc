if type direnv > /dev/null; then
    eval "$(direnv hook zsh)"
fi

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

export LESS="--quit-if-one-screen --RAW-CONTROL-CHARS"
export SYSTEMD_LESS="$LESS"

if type nvim > /dev/null; then
    export EDITOR=nvim
fi

# If on remote machine, autostart/automagically attach to tmux
[[ "$(hostname)" =~ "server|pi|thegreatbelow" ]] && ZSH_TMUX_AUTOSTART=true

plugins=(
    compleat
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-vim-mode
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

# Overrides vim-modes' settings which seem to be incompatible with syntax-highlighting
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M viins '^[OA' up-line-or-beginning-search
bindkey -M vicmd '^[OA' up-line-or-beginning-search
bindkey -M viins '^[OB' down-line-or-beginning-search
bindkey -M vicmd '^[OB' down-line-or-beginning-search

