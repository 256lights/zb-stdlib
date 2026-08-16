-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["1.14"] = {
    path = "gzip/gzip-1.14.tar.xz";
    hash = "sha256:01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

---@generic T
---@param args {
---makeDerivation: (fun(args: table<string, any>): T),
---version: string,
---}
---@return T
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("gzip.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "gzip";
    version = args.version;
    src = src;
  }
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "1.14";
  }
end

return module
