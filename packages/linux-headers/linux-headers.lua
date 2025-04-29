-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["4.14.336"] = {
    url = "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.14.336.tar.xz";
    hash = "sha256:0820fdb7971c6974338081c11fbf2dc869870501e7bdcac4d0ed58ba1f57b61c";
  };
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

local builderScript <const> = path "build.sh"

---@param args {
---makeDerivation: (fun(args: table<string, any>): derivation),
---buildSystem: string,
---version: string,
---}
---@return derivation
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("linux-headers.new: unsupported version "..args.version)
  end
  local sys = assert(systems.parse(args.buildSystem), "invalid buildSystem "..args.buildSystem)
  assert(sys.isX86 or sys.isARM, "unsupported system "..args.buildSystem)
  return args.makeDerivation {
    pname = "linux-headers";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;
    builder = builderScript;

    isX86 = sys.isX86;
    isARM = sys.isARM;
  }
end

return module
