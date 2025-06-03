-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["3.12"] = {
    path = "diffutils/diffutils-3.12.tar.xz";
    hash = "sha256:7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd";
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
    error("diffutils.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "diffutils";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;
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
        version = "3.12";
      }
    end;
  }
end

return module
