alias arduino-cli='arduino-cli --config-file ~/Arduino/.cli-config.yml'
alias bat='sudo tpacpi-bat -v'
alias find="noglob $(alias_or_name find)"
alias sed="noglob $(alias_or_name sed)"
alias rg="noglob $(alias_or_name rg)"
alias ccat='pygmentize -g'
# Some applications don't support locales properly
if [ $LC_COLLATE = "en_DE.UTF-8" ]; then
    alias mosh="LC_ALL='en_US.UTF-8' $(alias_or_name mosh)"
    alias tmux="LC_ALL='en_US.UTF-8' $(alias_or_name tmux)"
fi

# zmv
alias zmv='noglob zmv'
alias zcp='noglob zmv -C'
alias zln='noglob zmv -L'
alias zsy='noglob zmv -Ls'

if [ $TERM = "xterm-kitty" ]; then
    alias icat='kitty +kitten icat'
    alias diff='kitty +kitten diff'
    alias klip='kitty +kitten clipboard'
fi

eval $(thefuck --alias)
