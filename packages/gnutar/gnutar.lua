-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["1.35"] = {
    path = "tar/tar-1.35.tar.xz";
    hash = "sha256:4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

---@param args {
---makeDerivation: (fun(args: table<string, any>): any),
---version: string,
---}
---@return any
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("gnutar.new: unsupported version "..args.version)
  end
  return tables.withOutputs(args, function(args, system)
    local sys = systems.parse(system)
    local LDFLAGS = {}
    if sys.isMacOS then
      LDFLAGS[#LDFLAGS + 1] = "-liconv"
    end
    return outputs(args.makeDerivation {
      pname = "gnutar";
      version = args.version;
      src = src;
      LDFLAGS = LDFLAGS;
    }, system)
  end)
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "1.35";
  }
end

return module
