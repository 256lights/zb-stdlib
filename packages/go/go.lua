-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local bootstrap <const> = import "../../bootstrap/seeds.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["1.4-bootstrap-20171003"] = {
    url = "https://dl.google.com/go/go1.4-bootstrap-20171003.tar.gz";
    hash = "sha256:f4ff5b5eb3a3cae1c993723f3eab519c5bae18866b5e5f96fe1102f0cb5c3e52";
  };
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

---@param makeDerivation function
---@param system string
---@param version string
---@return derivation
function module.new(makeDerivation, system, version)
  local src = module.tarballs[version]
  if not src then
    error("go.new: unsupported version "..version)
  end
  return makeDerivation {
    pname = "go";
    version = version;
    system = system;
    src = src;

    configurePhase = [[export GOROOT_FINAL="$out"]];
    buildPhase = [[( cd src && ./make.bash )]];
    installPhase = [[cp --reflink=auto --archive . "$out"]];
  }
end

for system in pairs(bootstrap) do
  local system <const> = system
  module[system] = tables.lazyMap(function(_, version)
    local stdenv <const> = import "../../stdenv/stdenv.lua"
    return module.new(stdenv.makeDerivation, system, version)
  end, tarballArgs)
end

return module
