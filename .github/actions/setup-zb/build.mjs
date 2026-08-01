/**
 * @license
 * Copyright 2026 The zb Authors
 * SPDX-License-Identifier: MIT
 */

import { platform } from '@actions/core';
import * as esbuild from 'esbuild';

await esbuild.build({
  entryPoints: ['src/main.ts'],
  bundle: true,
  minify: false,
  platform: 'node',
  target: ['node24.0'],
  format: 'cjs',
  outfile: 'dist/main.js',
});
