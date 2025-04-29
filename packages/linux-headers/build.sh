#!/usr/bin/env bash
# Copyright 2025 The zb Authors
# SPDX-License-Identifier: MIT
set -e

mkdir "${TEMPDIR}/src"
cd "${TEMPDIR}/src"
tar -xJf "${src?}" \
  "linux-${version?}/scripts" \
  "linux-${version?}/include" \
  "linux-${version?}/arch/arm/include" \
  "linux-${version?}/arch/x86/include" \
  "linux-${version?}/arch/x86/entry"
cd "linux-$version"

rm include/uapi/linux/pktcdvd.h \
    include/uapi/linux/hw_breakpoint.h \
    include/uapi/linux/eventpoll.h \
    include/uapi/linux/atmdev.h \
    include/uapi/asm-generic/fcntl.h \
    arch/x86/include/uapi/asm/mman.h \
    arch/x86/include/uapi/asm/auxvec.h

# shellcheck disable=SC2086
"${CC:-gcc}" ${CFLAGS:-} ${LDFLAGS:-} -o scripts/unifdef scripts/unifdef.c

if [[ "${isX86:-}" = 1 ]]; then
  arch_dir=x86
elif [[ "${isARM:-}" = 1 ]]; then
  arch_dir=arm
else
  echo "unknown arch" >&2
  exit 1
fi

for d in include/uapi arch/${arch_dir?}/include/uapi; do
  ( cd "$d" && find . -type d -exec mkdir -p "${out?}/include/{}" \; )
  headers="$(cd "$d" && find . -type f -name "*.h")"
  for h in ${headers}; do
    path="$(dirname "${h}")"
    scripts/headers_install.sh "$out/include/${path}" "${d}/${path}" "$(basename "${h}")"
  done
done

for i in types ioctl termios termbits ioctls sockios socket param; do
  cp "$out/include/asm-generic/${i}.h" "$out/include/asm/${i}.h"
done

if [[ "${isX86:-}" = 1 ]]; then
  bash arch/x86/entry/syscalls/syscallhdr.sh \
    arch/x86/entry/syscalls/syscall_32.tbl \
    "$out/include/asm/unistd_32.h" \
    i386
  bash arch/x86/entry/syscalls/syscallhdr.sh \
    arch/x86/entry/syscalls/syscall_64.tbl \
    "$out/include/asm/unistd_64.h" \
    common,64
fi

# Generate linux/version.h
# Rules are from makefile
VERSION=4
PATCHLEVEL=14
SUBLEVEL=336
VERSION_CODE="$((VERSION * 65536 + PATCHLEVEL * 256 + SUBLEVEL))"
echo '#define LINUX_VERSION_CODE '"${VERSION_CODE}" \
    > "$out/include/linux/version.h"
echo '#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + ((c) > 255 ? 255 : (c)))' \
    >> "$out/include/linux/version.h"
