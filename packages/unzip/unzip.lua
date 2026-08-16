-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["6.0"] = {
    url = "https://src.fedoraproject.org/repo/pkgs/unzip/unzip60.tar.gz/62b490407489521db863b523a7f86375/unzip60.tar.gz";
    hash = "sha256:0dxx11knh3nk95p2gg2ak777dd11pr7jx5das2g49l262scrcv83";
  };
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

---@generic T
---@param args {
---makeDerivation: (fun(args: table<string, any>): T),
---version: string,
---shared: boolean?,
---}
---@return T
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("unzip.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "unzip";
    version = args.version;
    src = src;
    makeFlags = { "-f", "unix/Makefile", "CC=gcc", "prefix=" };
    buildFlags = { "generic" };
    installPhase = "make install ${makeFlags:-} ${installFlags:-} prefix=${out?}";
  }
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "6.0";
  }
end

return module
