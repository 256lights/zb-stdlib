/**
 * @license
 * Copyright 2026 The zb Authors
 * SPDX-License-Identifier: MIT
 */

import fs from 'node:fs/promises';
import process from 'node:process';
import path from 'node:path';

import * as core from '@actions/core';
import { exec } from '@actions/exec';
import { getOctokit } from '@actions/github';
import { downloadTool, extractTar, extractZip } from '@actions/tool-cache';

interface Release {
  tagName: string;
  releaseAssets: ReleaseAssetConnection;
}

interface ReleaseAssetConnection {
  nodes: ReleaseAsset[];
}

interface ReleaseAsset {
  name: string;
  downloadUrl: string;
}

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

function extractArchive(file: string, name?: string): Promise<string> {
  if ((name || file).endsWith('.zip')) {
    return extractZip(file);
  } else if ((name || file).endsWith('.tar.bz2')) {
    return extractTar(file, undefined, 'xj');
  } else {
    return extractTar(file);
  }
}

function archiveBaseName(name: string): string {
  return name.match(/^(.*?)(?:\.(?:zip|tar\.gz|tar\.bz2))?$/)![1];
}

(async () => {
  const octokit = getOctokit(core.getInput('github-token', { required: true }));

  const version = core.getInput('zb-version');
  const graphqlRequest =
    version ?
      {
        query:
          `
          query releaseAssetsForVersion($tagName: String!) {
            repository(owner: "256lights", name: "zb") {
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
            repository(owner: "256lights", name: "zb") {
              release: latestRelease {
                ...releaseFields
              }
            }
          }

          ${releaseFragment}
          `,
      };
  const graphqlResponse = await octokit.graphql<{
    repository: {
      release: Release | null;
    }
  }>(graphqlRequest);
  const release = graphqlResponse.repository.release;
  const releaseAssets = release?.releaseAssets?.nodes || [];

  let asset: ReleaseAsset | undefined;
  if (process.platform === 'darwin' && process.arch === 'arm64') {
    asset = releaseAssets.find(({ name }) => name.includes('aarch64-apple-macos'))
  } else if (process.platform === 'linux' && process.arch === 'x64') {
    asset = releaseAssets.find(({ name }) => name.includes('x86_64-unknown-linux'))
  }
  if (!asset) {
    core.setFailed(`No download found for ${process.arch}-${process.platform} version ${release?.tagName || version}`);
    return;
  }

  const zbExtractedFolderPath = await core.group(`Downloading ${asset.downloadUrl}`, async () => {
    const zbArchivePath = await downloadTool(asset.downloadUrl);
    return extractArchive(zbArchivePath, asset.name);
  });

  const installerPath = path.join(zbExtractedFolderPath, archiveBaseName(asset.name), 'install');
  await core.group('Running installer', () => exec(installerPath, [
    '--single-user',
    '--no-systemd',
    '--no-launchd',
  ]));

  const installerStorePath = path.join(zbExtractedFolderPath, archiveBaseName(asset.name), 'store');
  const objectNames = await fs.readdir(installerStorePath);
  const zbStoreDirectory = process.platform === 'win32' ? 'C:\\zb\\store' : '/opt/zb/store';
  const zbBins = await Promise.all(
    objectNames
      .filter((name) => name.match(/-zb-/))
      .map(async (name) => {
        const binPath = path.join(zbStoreDirectory, name, 'bin');
        try {
          await fs.lstat(binPath);
        } catch {
          return null;
        }
        return binPath;
      })
  );
  for (const binPath of zbBins) {
    if (binPath) {
      core.addPath(binPath);
    }
  }
})();
