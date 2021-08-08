alias arduino-cli='arduino-cli --config-file ~/Arduino/.cli-config.yml'
alias bat='sudo tpacpi-bat -v'
alias find='noglob find'
alias sed='noglob sed'
alias ccat='pygmentize -g'

# zmv
alias zmv='noglob zmv'
alias zcp='noglob zmv -C'
alias zln='noglob zmv -L'
alias zsy='noglob zmv -Ls'

if [ "$TERM" = "xterm-kitty" ]; then
    alias icat='kitty +kitten icat'
    alias diff='kitty +kitten diff'
    alias klip='kitty +kitten clipboard'
fi

eval $(thefuck --alias)
