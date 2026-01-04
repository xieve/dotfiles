#!/usr/bin/env zsh

set -euo pipefail

[[ "$SHELL:t" == "zsh" ]] || (echo Not zsh; exit 1)

src="${0:h:a}"/firefox
target=("$HOME"/.mozilla/firefox/*.default([1]))

echo Recursively glob-linking $src to "$target"

pushd "$src"
fd --type=d --exec mkdir -p "$target/{}"
fd --type=f --exclude="*.user.js" --exec ln --symbolic "$src/{}" "$target/{}"
popd
