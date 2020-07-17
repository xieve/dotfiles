vimd() { vim $(date +%y%m%d)-$@; }
compose() { grep --no-filename --ignore-case "$@" /usr/share/X11/locale/en_US.UTF-8/Compose ~/.XCompose; }
rex() { echo "$@" | xxd -r -p }

