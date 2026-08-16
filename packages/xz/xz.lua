-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["5.6.3"] = {
    url = "https://github.com/tukaani-project/xz/releases/download/v5.6.3/xz-5.6.3.tar.xz";
    hash = "sha256:db0590629b6f0fa36e74aea5f9731dc6f8df068ce7b7bafa45301832a5eebc3a";
  };
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

---@generic T
---@param args {
---makeDerivation: (fun(args: table<string, any>): T),
---version: string,
---shared?: boolean,
---}
---@return T
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("xz.new: unsupported version "..args.version)
  end
  local configureFlags = {}
  if args.shared == false then
    configureFlags[#configureFlags + 1] = "--disable-shared"
  end
  return args.makeDerivation {
    pname = "xz";
    version = args.version;
    src = src;
    configureFlags = configureFlags;
  }
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "5.6.3";
    shared = false;
  }
end

return module
