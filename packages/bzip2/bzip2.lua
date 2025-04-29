-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local bootstrap <const> = import "../../bootstrap/seeds.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["1.0.8"] = {
    url = "https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz";
    -- TODO(someday): Mirrored at https://mirror.bazel.build/sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
    hash = "sha256:ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269";
  };
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

---@param args {
---makeDerivation: (fun(args: table<string, any>): derivation),
---buildSystem: string,
---version: string,
---}
---@return derivation
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("bzip2.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "bzip2";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;

    dontConfigure = true;
    buildPhase = [[make "-j${ZB_BUILD_CORES:-1}" LDFLAGS="${LDFLAGS:-}" ${makeFlags:-} ${buildFlags:-}]];
    installPhase = [[make install ${makeFlags:-} PREFIX="$out" ${installFlags:-}]];
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
        version = "1.0.8";
      }
    end;
  }
end

return module
