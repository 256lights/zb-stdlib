-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local bootstrap <const> = import "../../bootstrap/seeds.lua"
local fetchGNU <const> = import "../../fetchgnu.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["1.4.7"] = {
    path = "m4/m4-1.4.7.tar.bz2";
    hash = "sha256:a88f3ddaa7c89cf4c34284385be41ca85e9135369c333fdfa232f3bf48223213";
  };
  ["1.4.19"] = {
    path = "m4/m4-1.4.19.tar.xz";
    hash = "sha256:63aede5c6d33b6d9b13511cd0be2cac046f2e70fd0a07aa9573a04a82783af96";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

---@param args {
---makeDerivation: (fun(args: table<string, any>): derivation),
---buildSystem: string,
---version: string,
---}
---@return derivation
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("gnum4.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "gnum4";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;
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
        version = "1.4.19";
      }
    end;
  }
end

return module
