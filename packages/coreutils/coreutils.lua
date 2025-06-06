-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["9.7"] = {
    path = "coreutils/coreutils-9.7.tar.xz";
    hash = "sha256:e8bb26ad0293f9b5a1fc43fb42ba970e312c66ce92c1b0b16713d7500db251bf";
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
    error("coreutils.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "coreutils";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;
    -- stdbuf insists on creating a .so file, which fails. Disable it.
    configureFlags = { "utils_cv_stdbuf_supported=no" };
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
        version = "9.7";
      }
    end;
  }
end

return module
