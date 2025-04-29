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

Support is planned for `x86_64-pc-windows-msvc` ([#1](https://github.com/256lights/zb-stdlib/issues/1)),
`aarch64-apple-darwin` ([#6](https://github.com/256lights/zb-stdlib/issues/6)),
and `aarch64-unknown-linux`.

## License

Predominantly [MIT](LICENSE),
although individual files may be under different licenses to comply with upstream licensing.
For example, patches for a package covered under the GNU General Public License
are themselves licensed under the same license.
Files in this repository carry a [SPDX license identifier][] where possible.

[SPDX license identifier]: https://spdx.dev/learn/handling-license-info/
