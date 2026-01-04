#!/usr/bin/env zsh

[[ "$SHELL:t" == "zsh" ]] || (echo Not zsh; exit 1) \
&& src="${1:h:a}"/firefox \
&& target=("$HOME"/.mozilla/firefox/*.default([1])) \
&& [ ! -s "$target/chrome" ] || (echo "$target/chrome already exists"; exit 1) \
&& echo Glob-linking $src to "$target"/chrome \
&& ln --symbolic "$src" "$target"/chrome
