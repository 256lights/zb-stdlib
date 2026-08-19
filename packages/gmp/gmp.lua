-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local strings <const> = import "../../strings.lua"
local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["6.2.1"] = {
    path = "gmp/gmp-6.2.1.tar.xz";
    hash = "sha256:fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

---@generic T
---@param args {
---makeDerivation: (fun(args: table): T),
---version: string,
---gnum4: any,
---}
---@return T
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("gmp.new: unsupported version "..args.version)
  end
  return tables.withOutputs(args, function(args, system)
    return args.makeDerivation {
      pname = "gmp";
      version = args.version;
      src = src;
      configureFlags = { "--disable-shared" };
      PATH = strings.makeBinPath(system, {
        args.gnum4,
      });
    }
  end)
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  local gnum4 <const> = import("../gnum4/gnum4.lua").stdenv
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "6.2.1";
    gnum4 = gnum4;
  }
end

return module
