vimd() { vim $(date +%y%m%d)-$@; }
compose() { grep --no-filename --ignore-case "$@" /usr/share/X11/locale/en_US.UTF-8/Compose ~/.XCompose; }
rex() { echo "$@" | xxd -r -p }
sine() { pactl load-module module-sine frequency=$@; read; pactl unload-module module-sine }
alias_or_name() { alias_value $@ || echo $@ }
