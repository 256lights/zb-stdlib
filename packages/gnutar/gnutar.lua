-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["1.35"] = {
    path = "tar/tar-1.35.tar.xz";
    hash = "sha256:4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

---@param args {
---makeDerivation: function,
---buildSystem: string,
---version: string,
---}
---@return derivation
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("gnutar.new: unsupported version "..args.version)
  end
  local buildSystem = systems.parse(args.buildSystem)
  local LDFLAGS = {}
  if buildSystem.isMacOS then
    LDFLAGS[#LDFLAGS+1] = "-liconv"
  end
  return args.makeDerivation {
    pname = "gnutar";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;
    LDFLAGS = LDFLAGS;
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
        version = "1.35";
      }
    end;
  }
end

return module
