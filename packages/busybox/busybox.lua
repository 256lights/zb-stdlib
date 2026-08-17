-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local strings <const> = import "../../strings.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["1.36.1"] = {
    url = "https://busybox.net/downloads/busybox-1.36.1.tar.bz2";
    hash = "sha256:b8cc24c9574d809e7279c3be349795c5d5ceb6fdf19ca709f80cde50e47de314";
  };
}

module.tarballs = tables.lazyMap(fetchurl, tarballArgs)

local patches <const> = {
  ["1.36.1"] = {
    path "patches/1.36.1/01-ldflags.diff",
  };
}

---@param args {
---makeDerivation: (fun(args: table<string, any>): derivation),
---version: string,
---configFile: any,
---linuxHeaders: any,
---}
---@return derivation
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("busybox.new: unsupported version "..args.version)
  end
  return tables.withOutputs({
    pname = "busybox";
    version = args.version;
    src = src;
    patches = patches[args.version];
  }, function(self, system)
    return args.makeDerivation {
      pname = self.pname;
      version = self.version;
      src = self.src;
      patches = self.patches;

      CONFIG_INSTALL_NO_USR = "y";
      configFile = defaultOutput(args.configFile, system);
      configurePhase = "cp $configFile .config";

      C_INCLUDE_PATH = strings.makeIncludePath(system, {
        defaultOutput(args.linuxHeaders, system),
      });

      installPhase = [[make CONFIG_PREFIX="$out" ${makeFlags:-} ${installFlags:-} install]];
    }
  end)
end

return module
