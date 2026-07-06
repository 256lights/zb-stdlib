-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local tables <const> = import "../../tables.lua"
local systems <const> = import "../../systems.lua"
local module <const> = {}

local tarballArgs <const> = {
  ["6.0"] = {
    url = "https://src.fedoraproject.org/repo/pkgs/unzip/unzip60.tar.gz/62b490407489521db863b523a7f86375/unzip60.tar.gz";
    hash = "sha256:0dxx11knh3nk95p2gg2ak777dd11pr7jx5das2g49l262scrcv83";
  };
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

---@param args {
---makeDerivation: function,
---buildSystem: string,
---version: string,
---shared: boolean?,
---}
---@return derivation
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("unzip.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "unzip";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;
    makeFile = "unix/Makefile";
    makeFlags = "CC=gcc";
    buildFlags = {"generic"};
    installPhase = '\z
      mkdir -p "$out/bin"\n\z
      mv unzip "$out/bin/unzip"\n';
  }
end

for _, system in ipairs(systems.stdlibSystems) do
  local system <const> = system
  module[system] = tables.lazyModule {
    stdenv = function()
      local stdenv <const> = import "../../stdenv/stdenv.lua"
      return module.new {
        makeDerivation = stdenv.makeBootstrapDerivation;
        buildSystem = system;
        version = "6.0";
      }
    end;
  }
end

return module
