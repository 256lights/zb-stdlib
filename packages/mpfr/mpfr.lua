-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local strings <const> = import "../../strings.lua"
local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["4.1.0"] = {
    path = "mpfr/mpfr-4.1.0.tar.xz";
    hash = "sha256:0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

---@param args {
---makeDerivation: (fun(args: table<string, any>): any),
---version: string,
---gmp: any,
---shared: boolean?,
---}
---@return any
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("mpfr.new: unsupported version "..args.version)
  end
  return tables.withOutputs({
    pname = "mpfr";
    version = args.version;
    src = src;
  }, function(_, system)
    local configureFlags = {
      "--with-gmp="..defaultOutput(args.gmp, system),
    }
    if args.shared == false then
      configureFlags[#configureFlags + 1] = "--disable-shared"
    end
    return args.makeDerivation {
      pname = "mpfr";
      version = args.version;
      src = src;
      configureFlags = configureFlags;
    }
  end)
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  local gmp <const> = import("../gmp/gmp.lua").stdenv
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "4.1.0";
    gmp = gmp;
    shared = false;
  }
end

return module
