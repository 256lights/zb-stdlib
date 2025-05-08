-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local bootstrap <const> = import "../../bootstrap/seeds.lua"
local strings <const> = import "../../strings.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["1.4-bootstrap-20171003"] = {
    url = "https://dl.google.com/go/go1.4-bootstrap-20171003.tar.gz";
    hash = "sha256:f4ff5b5eb3a3cae1c993723f3eab519c5bae18866b5e5f96fe1102f0cb5c3e52";
  };
  ["1.17.13"] = {
    url = "https://go.dev/dl/go1.17.13.src.tar.gz";
    hash = "sha256:a1a48b23afb206f95e7bbaa9b898d965f90826f6f1d1fc0c1d784ada0cd300fd";
  };
  ["1.19.13"] = {
    url = "https://go.dev/dl/go1.19.13.src.tar.gz";
    hash = "sha256:ccf36b53fb0024a017353c3ddb22c1f00bc7a8073c6aac79042da24ee34434d3";
  };
  ["1.21.13"] = {
    url = "https://go.dev/dl/go1.21.13.src.tar.gz";
    hash = "sha256:71fb31606a1de48d129d591e8717a63e0c5565ffba09a24ea9f899a13214c34d";
  };
  ["1.23.7"] = {
    url = "https://go.dev/dl/go1.23.7.src.tar.gz";
    hash = "sha256:7cfabd46b73eb4c26b19d69515dd043d7183a6559acccd5cfdb25eb6b266a458";
  };
  ["1.24.2"] = {
    url = "https://go.dev/dl/go1.24.2.src.tar.gz";
    hash = "sha256:9dc77ffadc16d837a1bf32d99c624cb4df0647cee7b119edd9e7b1bcc05f2e00";
  };
}

local bootstrapVersion <const> = "1.4-bootstrap-20171003"

local bootstrapSequence <const> = {
  ["1.5"] = bootstrapVersion;
  ["1.6"] = bootstrapVersion;
  ["1.7"] = bootstrapVersion;
  ["1.8"] = bootstrapVersion;
  ["1.9"] = bootstrapVersion;
  ["1.10"] = bootstrapVersion;
  ["1.11"] = bootstrapVersion;
  ["1.12"] = bootstrapVersion;
  ["1.13"] = bootstrapVersion;
  ["1.14"] = bootstrapVersion;
  ["1.15"] = bootstrapVersion;
  ["1.16"] = bootstrapVersion;
  ["1.17"] = bootstrapVersion;
  ["1.18"] = bootstrapVersion;
  ["1.19"] = bootstrapVersion;
  ["1.20"] = "1.19.13"; -- >1.17
  ["1.21"] = "1.19.13"; -- >1.17
  ["1.22"] = "1.21.13"; -- >1.20
  ["1.23"] = "1.21.13"; -- >1.20
  ["1.24"] = "1.23.7";  -- >1.22
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

---@param args {
---makeDerivation: function,
---buildSystem: string,
---version: string,
---go: derivation|string?,
---}
---@return derivation
function module.new(args)
  if args.version ~= bootstrapVersion and not args.go then
    error("go.new: missing go")
  end
  local src = module.tarballs[args.version]
  if not src then
    error("go.new: unsupported version "..args.version)
  end
  local PATH
  if args.go then
    PATH = strings.makeBinPath { args.go }
  end
  return args.makeDerivation {
    pname = "go";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;

    postPatch = [[
patchShebangs src/make.bash
]];

    -- TODO(#14): CGO_ENABLED=0 because cgo requires gcc 4.6 or newer.
    -- https://go.dev/wiki/MinimumRequirements
    configurePhase = [[
export GOROOT_FINAL="$out/share/go"
export GOPATH="$ZB_BUILD_TOP/gopath"
export GOCACHE="$ZB_BUILD_TOP/cache"
export CGO_ENABLED=0
mkdir "$GOPATH" "$GOCACHE"
]];
    buildPhase = [[( cd src && ./make.bash )]];
    installPhase = [=[
mkdir -p "$out/share/go"
cp --reflink=auto --archive bin pkg src lib misc api doc "$out/share/go/"
if [[ -e go.env ]]; then
  cp --reflink=auto --archive go.env "$out/share/go"
fi
mkdir -p "$out/bin"
ln -s "$out/share/go/bin"/* "$out/bin/"
]=];
    PATH = PATH;
  }
end

for system in pairs(bootstrap) do
  local system <const> = system
  module[system] = tables.lazyMap(function(_, version)
    local stdenv <const> = import "../../stdenv/stdenv.lua"
    local minorVersion = version:match("^([0-9]+%.[0-9]+)")
    local go
    if version ~= bootstrapVersion then
      go = module[system][bootstrapSequence[minorVersion]]
    end
    return module.new {
      makeDerivation = stdenv.makeDerivation;
      buildSystem = system;
      version = version;
      go = go;
    }
  end, tarballArgs)
end

return module
