# zb Standard Library

This repository contains the standard library for [zb](https://github.com/256lights/zb),
a tool for hermetic, reproducible builds.
The standard library's aim is to include a baseline userspace for all platforms that zb is supported on
so that users of zb can use common programming language tools without having to bootstrap compilers themselves.

The zb standard library is versioned and released separately from zb
so that users of zb can receive updates to userspace programs without having to update zb itself.
This also ensures that zb is decoupled from its standard library:
users with highly specific requirements can bootstrap their own userspace without using the standard library.

The zb standard library currently supports:

- `x86_64-unknown-linux`
- `aarch64-apple-macos`

Support is planned for:

- `x86_64-pc-windows-msvc` ([#1](https://github.com/256lights/zb-stdlib/issues/1))
- `aarch64-unknown-linux` ([#24](https://github.com/256lights/zb-stdlib/issues/24))

## System Dependencies

The goal for the zb standard library is to be fully hermetic,
but it's not quite there yet.
For now, each platform requires some minimal software to be installed on builder system.

### x86_64-unknown-linux

Under `x86_64-unknown-linux`, the standard library requires a specific copy of GCC and BusyBox to be present in the zb store.
The exact paths are listed in [bootstrap/seeds.lua](bootstrap/seeds.lua).
The binary releases of zb for x86_64-unknown-linux include these store paths in their installation,
so in most cases, you should not need to download these tools yourself.

### aarch64-apple-macos

Under `aarch64-apple-macos`, the standard library uses the compilers provided by Xcode Command Line Tools.
To ensure these are installed, run the following:

```shell
xcode-select --install
```

## License

Predominantly [MIT](LICENSE),
although individual files may be under different licenses to comply with upstream licensing.
For example, patches for a package covered under the GNU General Public License
are themselves licensed under the same license.
Files in this repository carry a [SPDX license identifier][] where possible.

[SPDX license identifier]: https://spdx.dev/learn/handling-license-info/
