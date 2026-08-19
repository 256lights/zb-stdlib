-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["3.12"] = {
    path = "grep/grep-3.12.tar.xz";
    hash = "sha256:2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9";
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
    error("gnugrep.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "gnugrep";
    version = args.version;
    src = src;
  }
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "3.12";
  }
end

return module
