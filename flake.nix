# Copyright 2025 The zb Authors
# SPDX-License-Identifier: MIT

{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        inherit (pkgs.lib.strings) concatStringsSep makeIncludePath makeLibraryPath;

        gcc = pkgs.gcc-unwrapped;
        libc_dev = gcc.libc_dev;

        gccVersion = "14.2.1"; # name used in directory, which sadly != gcc.version.
        cIncludePath = [
          "${gcc}/lib/gcc/${pkgs.targetPlatform.config}/${gccVersion}/include"
          "${gcc}/include"
          "${gcc}/lib/gcc/${pkgs.targetPlatform.config}/${gccVersion}/include-fixed"
          (makeIncludePath [libc_dev])
        ];
        cplusIncludePath = [
          "${gcc}/include/c++/${gcc.version}/"
          "${gcc}/include/c++/${gcc.version}//${pkgs.targetPlatform.config}"
          "${gcc}/include/c++/${gcc.version}//backward"
        ] ++ cIncludePath;
      in
      {
        devShells.default = pkgs.mkShellNoCC {
          packages = [
            gcc
            (libc_dev.bin or libc_dev)
            pkgs.binutils-unwrapped
          ];

          shellHook = ''
            export C_INCLUDE_PATH='${concatStringsSep ":" cIncludePath}'
            export CPLUS_INCLUDE_PATH='${concatStringsSep ":" cplusIncludePath}'
            export LIBRARY_PATH='${makeLibraryPath [ gcc (libc_dev.lib or libc_dev.out or libc_dev) ]}'
          '';

          hardeningDisable = [ "fortify" ];
        };
      }
    );
}
