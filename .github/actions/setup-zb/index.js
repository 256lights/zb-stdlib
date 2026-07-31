// Copyright 2026 The zb Authors
// SPDX-License-Identifier: MIT

import * as process from 'node:process';
import path from 'node:path';

import * as core from '@actions/core';
import { exec } from '@actions/exec';
import { getOctokit } from '@actions/github';
import { downloadTool, extractTar, extractZip } from '@actions/tool-cache';

const releaseFragment =
  `
    fragment releaseFields on Release {
      tagName
      releaseAssets(first: 50) {
        nodes {
          name
          downloadUrl
        }
      }
    }
  `;

(async () => {
  const octokit = getOctokit('');

  const version = core.getInput('zb-version');
  const graphqlRequest =
    version ?
    {
      query:
        `
          query releaseAssetsForVersion($tagName: String!) {
            repository(owner: "256lights", repo: "zb") {
              release(tagName: $tagName) {
                ...releaseFields
              }
            }
          }

          ${releaseFragment}
        `,
      tagName: 'v' + version,
    } :
    {
      query:
        `
          query releaseAssetsForLatest {
            repository(owner: "256lights", repo: "zb") {
              release: latestRelease {
                ...releaseFields
              }
            }
          }

          ${releaseFragment}
        `,
    };

  const release = (await octokit.graphql(graphqlRequest)).repository.release;
  /** @type {{name: string, downloadUrl: string}[] | undefined} */
  const releaseAssets = release?.releaseAssets?.nodes;

  /** @type {{name: string, downloadUrl: string} | undefined} */
  let asset;
  if (process.platform === 'darwin' && process.arch === 'arm64') {
    const asset = releaseAssets.find(({ name }) => name.includes('aarch64-apple-macos'))
  } else if (process.platform === 'linux' && process.arch === 'x64') {
    const asset = releaseAssets.find(({ name }) => name.includes('x86_64-unknown-linux'))
  }
  if (!asset) {
    core.setFailed(`No download found for ${process.arch}-${process.platform} version ${release?.tagName || version}`);
    return;
  }

  const zbArchivePath = await downloadTool(asset.downloadUrl);
  const zbExtractedFolderPath = asset.downloadUrl.endsWith('.zip') ?
    await extractZip(zbArchivePath) :
    await extractTar(zbArchivePath);
  await exec(path.join(zbArchivePath, 'install'), ['--single-user', '--no-systemd', '--no-launchd']);
})();
