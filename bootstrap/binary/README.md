# Binary bootstrap

Files in this directory are used to build the bootstrap C compiler and shell for each platform.
These intentionally use the system's toolchain to produce,
so you will need to either run `zb serve` with `--sandbox=0`,
or include the appropriate tools using `--sandbox-path`.
If you're using the Nix flake, the paths you will need to include in sandbox are:

- `/bin/sh`
- `/usr`
- `/lib`
- `/lib64`
- `/nix/store`

Then you can run:

```shell
zb build --allow-all-env 'linux.lua#gcc' 'linux.lua#busybox'
```
