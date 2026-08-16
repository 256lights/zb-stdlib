-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["9.7"] = {
    path = "coreutils/coreutils-9.7.tar.xz";
    hash = "sha256:e8bb26ad0293f9b5a1fc43fb42ba970e312c66ce92c1b0b16713d7500db251bf";
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
    error("coreutils.new: unsupported version "..args.version)
  end
  return args.makeDerivation {
    pname = "coreutils";
    version = args.version;
    src = src;
    -- stdbuf insists on creating a .so file, which fails. Disable it.
    configureFlags = { "utils_cv_stdbuf_supported=no" };
  }
end

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "9.7";
  }
end

return module
