# zb standard library Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

[Unreleased]: https://github.com/256lights/zb-stdlib/compare/v0.1.1...main

## [Unreleased][]

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
