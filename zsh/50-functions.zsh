vimd() { vim $(date +%y%m%d)-$@; }
compose() { grep --no-filename --ignore-case "$@" /usr/share/X11/locale/en_US.UTF-8/Compose ~/.XCompose; }
rex() { echo "$@" | xxd -r -p }
sine() { pactl load-module module-sine frequency=$@; read; pactl unload-module module-sine }
alias_or_name() { alias_value $@ || echo $@ }
cd() { pushd $@ > /dev/null }
nix-tree() { echo "$(nix build --print-out-paths --no-link $@)" | xargs tree }

ansi_colors() {
  # source: https://tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
  #
  #   This function echoes a bunch of color codes to the
  #   terminal to demonstrate what's available.  Each
  #   line is the color code of one forground color,
  #   out of 17 (default + 16 escapes), followed by a
  #   test use of that color on all nine background
  #   colors (default + 8 escapes).
  #

  T='gYw'   # The test text

  echo -e "\n                 40m     41m     42m     43m\
	   44m     45m     46m     47m";

  for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
			 '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
			 '  36m' '1;36m' '  37m' '1;37m';
	do FG=${FGs// /}
	echo -en " $FGs \033[$FG  $T  "
	for BG in 40m 41m 42m 43m 44m 45m 46m 47m;
	  do echo -en "$EINS \033[$FG\033[$BG  $T  \033[0m";
	done
	echo;
  done
  echo
}
