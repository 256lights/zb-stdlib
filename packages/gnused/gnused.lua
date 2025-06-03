-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local patchDir48 <const> = path {
  path = "patches/4.8";
  name = "gnused-patches-4.8";
  filter = function (name) return name:find(".diff$") ~= nil end
}
local patches <const> = {
  ["4.8"] = {
    patchDir48.."/01-noreturn.diff"
  };
}

local tarballArgs <const> = {
  ["4.8"] = {
    path = "sed/sed-4.8.tar.xz";
    hash = "sha256:f79b0cfea71b37a8eeec8490db6c5f7ae7719c35587f21edb0617f370eeff633";
  };
  ["4.9"] = {
    path = "sed/sed-4.9.tar.xz";
    hash = "sha256:6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

---@param args {
---makeDerivation: function,
---buildSystem: string,
---version: string,
---i18n?: boolean,
---}
---@return derivation
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("gnused.new: unsupported version "..args.version)
  end
  local configureFlags = {}
  if not args.i18n then
    configureFlags[#configureFlags+1] = "--disable-nls"
    configureFlags[#configureFlags+1] = "--disable-i18n"
  end
  return args.makeDerivation {
    pname = "gnused";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;
    patches = patches[args.version];
    configureFlags = configureFlags;
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
        version = "4.8";
      }
    end;
  }
end

return module
