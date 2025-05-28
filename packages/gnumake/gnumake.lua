-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local gcc <const> = import "../gcc/gcc.lua"
local seeds <const> = import "../../bootstrap/seeds.lua"
local fetchGNU <const> = import "../../fetchgnu.lua"
local strings <const> = import "../../strings.lua"
local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

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

---@param args {
---makeDerivation: function,
---buildSystem: string,
---version: string,
---}
---@return derivation
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
    buildSystem = args.buildSystem;
    src = src;
    patches = patches[args.version];

    configureFlags = configureFlags;
  }
end

for _, system in ipairs(systems.stdlibSystems) do
  local system <const> = system
  module[system] = tables.lazyModule {
    bootstrap = function()
      local version <const> = "3.82"
      local sys <const> = systems.parse(system)

      if sys and sys.isLinux then
        return derivation {
          name = "gnumake-"..version;
          pname = "gnumake";
          version = version;

          system = system;
          builder = seeds[system].busybox.."/bin/sh";
          args = { path "build.sh" };

          src = module.tarballs[version];
          sourceRoot = "make-"..version;
          patches = patches[version];

          PATH = strings.makeBinPath {
            gcc[system].bootstrap,
            seeds[system].busybox,
          };
          SOURCE_DATE_EPOCH = 0;
          KBUILD_BUILD_TIMESTAMP = "@0";
        }
      elseif sys and sys.isMacOS then
        return derivation {
          name = "gnumake-"..version;
          pname = "gnumake";
          version = version;

          system = system;
          builder = "/bin/sh";
          args = { path "build.sh" };

          src = module.tarballs[version];
          sourceRoot = "make-"..version;
          patches = patches[version];

          PATH = strings.makeBinPath {
            "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr",
            "/Library/Developer/CommandLineTools/usr",
            "/usr",
            "/",
          };
          __buildSystemDeps = { "/usr", "/bin", "/Library/Developer/CommandLineTools" };
          SOURCE_DATE_EPOCH = 0;
          KBUILD_BUILD_TIMESTAMP = "@0";
        }
      else
        return nil
      end
    end;

    stdenv = function()
      local stdenv <const> = import "../../stdenv/stdenv.lua"
      return module.new {
        makeDerivation = stdenv.makeBootstrapDerivation;
        buildSystem = system;
        version = "4.4.1";
      }
    end;
  }
end

return module
