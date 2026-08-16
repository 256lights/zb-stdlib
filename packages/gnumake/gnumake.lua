-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local gcc <const> = import "../gcc/gcc.lua"
local seeds <const> = import "../../bootstrap/seeds.lua"
local fetchGNU <const> = import "../../fetchgnu.lua"
local strings <const> = import "../../strings.lua"
local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local getters <const> = {}
local module <const> = setmetatable({}, { __index = tables.lazyModule(getters) })

local tarballArgs <const> = {
  ["3.82"] = {
    path = "make/make-3.82.tar.bz2";
    hash = "sha256:e2c1a73f179c40c71e2fe8abf8a8a0688b8499538512984da4a76958d0402966";
  };
  ["4.4.1"] = {
    path = "make/make-4.4.1.tar.gz";
    hash = "sha256:dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

local patches <const> = {
  ["3.82"] = {
    path "patches/3.82/01-include-limits.diff",
  };
}

---@generic T
---@param args {
---makeDerivation: (fun(args: table<string, any>): T),
---version: string,
---}
---@return T
function module.new(args)
  local src = module.tarballs[args.version]
  if not src then
    error("gnumake.new: unsupported version "..args.version)
  end
  local configureFlags
  if args.version == "4.4.1" then
    configureFlags = { "--disable-load" }
  end
  return args.makeDerivation {
    pname = "gnumake";
    version = args.version;
    src = src;
    patches = patches[args.version];
    configureFlags = configureFlags;
  }
end

module.bootstrap = tables.withOutputs({ version = "3.82" }, function(self, system)
  local sys <const> = systems.parse(system)

  if sys and sys.isLinux then
    return outputs(derivation {
      name = "gnumake-"..self.version;
      pname = "gnumake";
      version = self.version;

      system = system;
      builder = strings.defaultOutput(seeds[system].busybox, system).."/bin/sh";
      args = { path "build.sh" };

      src = module.tarballs[self.version];
      sourceRoot = "make-"..self.version;
      patches = patches[self.version];

      PATH = strings.makeBinPath(system, {
        gcc.bootstrap,
        seeds[system].busybox,
      });
      SOURCE_DATE_EPOCH = 0;
      KBUILD_BUILD_TIMESTAMP = "@0";
    }, system)
  elseif sys and sys.isMacOS then
    return outputs(derivation {
      name = "gnumake-"..self.version;
      pname = "gnumake";
      version = self.version;

      system = system;
      builder = "/bin/sh";
      args = { path "build.sh" };

      src = module.tarballs[self.version];
      sourceRoot = "make-"..self.version;
      patches = patches[self.version];

      PATH = strings.makeBinPath(system, {
        "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr",
        "/Library/Developer/CommandLineTools/usr",
        "/usr",
        "/",
      });
      __buildSystemDeps = { "/usr", "/bin", "/Library/Developer/CommandLineTools" };
      SOURCE_DATE_EPOCH = 0;
      KBUILD_BUILD_TIMESTAMP = "@0";
    }, system)
  else
    error("gnumake.bootstrap: unsupported system "..system)
  end
end)

function getters.stdenv()
  local stdenv <const> = import "../../stdenv/stdenv.lua"
  return module.new {
    makeDerivation = stdenv.makeBootstrapDerivation;
    version = "4.4.1";
  }
end

return module
