-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local strings <const> = import "../../strings.lua"
local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["1.2.1"] = {
    path = "mpc/mpc-1.2.1.tar.gz";
    hash = "sha256:17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

---@param args {
---makeDerivation: (fun(args: table<string, any>): any),
---version: string,
---gmp: derivation|string,
---mpfr: derivation|string,
---shared: boolean?,
---}
---@return any
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("libmpc.new: unsupported version "..args.version)
  end
  return tables.withOutputs({
    pname = "libmpc";
    version = args.version;
    src = src;
  }, function(_, system)
    local configureFlags = {
      "--with-gmp="..strings.defaultOutput(args.gmp, system),
      "--with-mpfr="..strings.defaultOutput(args.mpfr, system),
    }
    if args.shared == false then
      configureFlags[#configureFlags + 1] = "--disable-shared"
    end
    return outputs(args.makeDerivation {
      pname = "libmpc";
      version = args.version;
      src = src;
      configureFlags = configureFlags;
    }, system)
  end)
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  local gmp <const> = import("../gmp/gmp.lua").stdenv
  local mpfr <const> = import("../mpfr/mpfr.lua").stdenv
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "1.2.1";
    gmp = gmp;
    mpfr = mpfr;
    shared = false;
  }
end

return module
