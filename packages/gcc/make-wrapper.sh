#!/bin/sh
# Copyright 2025 The zb Authors
# SPDX-License-Identifier: MIT
set -eu

makeWrapper() {
  tool="$1"
  if ! [ -e "${gcc?}/bin/$tool" ]; then
    echo "${gcc?}/bin/$tool does not exist" >&2
    return 1
  fi
  sed \
    -e "s @tool@ $tool g" \
    -e "s @gcc@ ${gcc?} g" \
    -e "s @targetSystem@ ${targetSystem?} g" \
    -e "s @version@ ${version?} g" \
    -e "s @runtimeShell@ ${runtimeShell:-/bin/sh} g" \
    "${template?}" > "$tool"
}
makeWrapper gcc
makeWrapper g++
makeWrapper c++
makeWrapper "${targetSystem?}-gcc"
makeWrapper "${targetSystem?}-g++"
makeWrapper "${targetSystem?}-cc"
makeWrapper "${targetSystem?}-c++"
makeWrapper "${targetSystem?}-gcc-${version?}"

mkdir "${out?}"
for i in * ; do
  install -D -m 755 "$i" "$out/bin/$i"
done
for i in "$gcc"/bin/* ; do
  name="$(basename "$i")"
  if ! [ -e "$out/bin/$name" ]; then
    ln -s "$i" "$out/bin/$name"
  fi
done
