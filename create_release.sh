#!/usr/bin/env bash
# Copyright 2025 The zb Authors
# SPDX-License-Identifier: MIT

set -euo pipefail

tag="$1"
dir_name="zb-stdlib-${tag}"
output_file="${dir_name}.tar.gz"

git archive \
  --format tar.gz \
  -6 \
  --prefix="$dir_name/" \
  --output="$output_file" \
  "$tag"
sha256sum "$output_file"
