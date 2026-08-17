-- Copyright 2026 The zb Authors
-- SPDX-License-Identifier: MIT

return {
  stdenv = import("stdenv/stdenv.lua").makeDerivation {
    name = "stdenv-test";
    dontUnpack = true;
    installPhase = "touch $out";
  };
  go = import("packages/go/go.lua")["1.26"];
}
