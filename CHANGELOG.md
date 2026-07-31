# zb standard library Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

[Unreleased]: https://github.com/256lights/zb-stdlib/compare/v0.2.0...main

## [0.2.0][] - 2026-07-30

Version 0.2 upgrades Go to 1.26
and includes the [UnZip utility](https://infozip.sourceforge.net/UnZip.html).
It's a release designed to prepare for [zb 0.2](https://github.com/256lights/zb/milestone/3).

[0.2.0]: https://github.com/256lights/zb-stdlib/releases/tag/v0.2.0

### Added

- `unzip` is now included in the standard environment.
  ([#35](https://github.com/256lights/zb-stdlib/pull/35))
  Sources to the standard environment can now be zip archives.
  Thank you to [@Abdiramen](https://github.com/Abdiramen)!

### Changed

- Go packages are now keyed by major release
  (the number immediately after the "1.")
  instead of the minor version.
- The `lazy` function in `tables.lua`
  now uses the [built-in `lazy` function](https://zb.256lights.llc/lua/extensions#lazy)
  if available.

## [0.1.1][] - 2025-06-12

Version 0.1.1 adds a `sh` binary into the standard environment.

[0.1.1]: https://github.com/256lights/zb-stdlib/releases/tag/v0.1.1

### Added

- Added a script to create release tarballs.

### Fixed

- Add `sh` symlink in `bash.stdenv` derivation.
  Ensures that an `sh` binary is in the `PATH`.

## [0.1.0][] - 2025-06-03

Initial public release.

[0.1.0]: https://github.com/256lights/zb-stdlib/releases/tag/v0.1.0
