export LANG="en_US.UTF-8"

DOTFILES=$HOME/.dotfiles

# Path to your oh-my-zsh installation.
ZSH=$DOTFILES/ohmyzsh

ZSH_THEME="promptline"
#ZSH_THEME="powerlevel9k/powerlevel9k"
#POWERLEVEL9K_MODE='nerdfont-complete'

# Set list of themes to pick from when loading at random
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# History command timestamp format
HIST_STAMPS="yyyy-mm-dd"

ZSH_CUSTOM=$DOTFILES/zsh

plugins=(git)

# User configuration # export MANPATH="/usr/local/man:$MANPATH" # You may need to manually set your language environment # export LANG=en_US.UTF-8 # Preferred editor export EDITOR='vim' # Compilation flags # export ARCHFLAGS="-arch x86_64" # Set personal aliases, overriding those provided by oh-my-zsh libs, # plugins, and themes. Aliases can be placed here, though oh-my-zsh # users are encouraged to define aliases within the ZSH_CUSTOM folder.  # For a full list of active aliases, run `alias`.  # # Example aliases # alias zshconfig="mate ~/.zshrc" # alias ohmyzsh="mate ~/.oh-my-zsh" ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
# if [[ ! -d $ZSH_CACHE_DIR ]]; then
#   mkdir $ZSH_CACHE_DIR
# fi

# Load zmv, a powerful mv with batch capabilities
autoload -U zmv

source $ZSH/oh-my-zsh.sh
source $DOTFILES/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
