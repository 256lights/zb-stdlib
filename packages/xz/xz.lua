-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local bootstrap <const> = import "../../bootstrap/seeds.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["5.6.3"] = {
    url = "https://github.com/tukaani-project/xz/releases/download/v5.6.3/xz-5.6.3.tar.xz";
    hash = "sha256:db0590629b6f0fa36e74aea5f9731dc6f8df068ce7b7bafa45301832a5eebc3a";
  };
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

---@param args {
---makeDerivation: function,
---buildSystem: string,
---version: string,
---shared?: boolean,
---}
---@return derivation
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("xz.new: unsupported version "..args.version)
  end
  local configureFlags = {}
  if args.shared == false then
    configureFlags[#configureFlags + 1] = "--disable-shared"
  end
  return args.makeDerivation {
    pname = "xz";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;

    configureFlags = configureFlags;
  }
end

for system in pairs(bootstrap) do
  local system <const> = system
  module[system] = tables.lazyModule {
    stdenv = function()
      local stdenv <const> = import "../../stdenv/stdenv.lua"
      return module.new {
        makeDerivation = stdenv.makeBootstrapDerivation;
        buildSystem = system;
        version = "5.6.3";
        shared = false;
      }
    end;
  }
end

return module
