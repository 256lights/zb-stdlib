#!/usr/bin/env bash
# Copyright 2025 The zb Authors
# SPDX-License-Identifier: MIT

set -euo pipefail

if [[ -n "${helpersNix:-}" ]]; then
  #shellcheck source=helpers-nix.sh
  . "$helpersNix"
fi

runHook() {
  local hookName="$1"
  shift
  eval "${!hookName:-}"
}
unpackFile() {
  local src="$1" dst
  if [[ -d "$src" ]]; then
    dst="$(stripHash "$src")"
    cp -r --preserve=mode --reflink=auto -- "$src" "$dst"
  else
    case "$src" in
      *.tar.bz2)
        tar -xjf "$src"
        ;;
      *.tar.gz)
        tar -xzf "$src"
        ;;
      *.tar.xz)
        tar -xJf "$src"
        ;;
      *)
        echo "unhandled source $src" >&2
        return 1
        ;;
    esac
  fi
}

if [[ "${dontUnpack:-}" -ne 1 ]]; then
  runHook preUnpack
  if [[ -n "${unpackPhase:-}" ]]; then
    eval "$unpackPhase"
  else
    if [[ -n "${srcs:-}" ]]; then
      for i in $srcs; do
        unpackFile "$i"
      done
    elif [[ -n "${src:-}" ]]; then
      unpackFile "$src"
    else
      echo "must set src or srcs" >&2
      exit 1
    fi

    : "${sourceRoot=}"
    if [[ -z "$sourceRoot" ]]; then
      for i in *; do
        if [[ -d "$i" ]]; then
          if [[ -n "$sourceRoot" ]]; then
            echo "unpacker produced multiple directories" >&2
            exit 1
          fi
          sourceRoot="$i"
        fi
      done
      if [[ -z "$sourceRoot" ]]; then
        echo "unpacker appears to have produced no directories" >&2
        exit 1
      fi
    fi

    # Make build directory writable and searchable.
    # (Usually needed if copied from a store directory.)
    chmod -R u+w "$sourceRoot"
    chmod +x "$sourceRoot"

    cd "$sourceRoot"
  fi
  runHook postUnpack
fi


if [[ "${dontPatch:-}" -ne 1 ]]; then
  runHook prePatch
  if [[ -n "${patchPhase:-}" ]]; then
    eval "$patchPhase"
  elif [[ -n "${patches:-}" ]]; then
    for i in $patches; do
      # shellcheck disable=SC2086
      patch ${patchFlags:--p1} < "$i"
    done
  fi
  runHook postPatch
fi

if [[ "${dontConfigure:-}" -ne 1 ]]; then
  runHook preConfigure
  if [[ -n "${configurePhase:-}" ]]; then
    eval "$configurePhase"
  elif [[ -x ./configure ]]; then
    patchShebangs ./configure
    # shellcheck disable=SC2086
    ./configure --prefix="${out?}" ${configureFlags:-}
  else
    echo "no configure script, doing nothing"
  fi
  runHook postConfigure
fi

if [[ "${dontBuild:-}" -ne 1 ]]; then
  runHook preBuild
  if [[ -n "${buildPhase:-}" ]]; then
    eval "$buildPhase"
  elif [[ -z "${makeFlags:-}" && ! ( -e Makefile || -e makefile || -e GNUmakefile ) ]]; then
    echo "no Makefile or custom buildPhase, doing nothing"
  else
    # shellcheck disable=SC2086
    make "-j${ZB_BUILD_CORES:-1}" ${makeFlags:-} ${buildFlags:-}
  fi
  runHook postBuild
fi

if [[ "${dontInstall:-}" -ne 1 ]]; then
  runHook preInstall
  if [[ -n "${installPhase:-}" ]]; then
    eval "$installPhase"
  elif [[ -z "${makeFlags:-}" && ! ( -e Makefile || -e makefile || -e GNUmakefile ) ]]; then
    echo "no Makefile or custom installPhase, doing nothing"
  else
    make install ${makeFlags:-} ${installFlags:-}
  fi
  runHook postInstall
fi
