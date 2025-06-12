-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local fetchGNU <const> = import "../../fetchgnu.lua"
local gcc <const> = import "../gcc/gcc.lua"
local gnumake <const> = import "../gnumake/gnumake.lua"
local strings <const> = import "../../strings.lua"
local systems <const> = import "../../systems.lua"
local tables <const> = import "../../tables.lua"

local module <const> = {}

local tarballArgs <const> = {
  ["5.2.15"] = {
    path = "bash/bash-5.2.15.tar.gz";
    hash = "sha256:13720965b5f4fc3a0d4b61dd37e7565c741da9a5be24edc2ae00182fc1b3588c";
  };
}

module.tarballs = tables.lazyMap(fetchGNU, tarballArgs)

local patches <const> = {
  path "patches/5.2.15/01-strtoimax.diff",
  path "patches/5.2.15/02-omit-rdynamic.diff",
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
    error("bash.new: unsupported version "..args.version)
  end
  local buildSystem = systems.parse(args.buildSystem)
  local configureFlags = {
    "--without-bash-malloc",
    "--disable-nls",
  }
  if buildSystem.isLinux then
    configureFlags[#configureFlags+1] = "--enable-static-link"
  end
  return args.makeDerivation {
    pname = "bash";
    version = args.version;
    buildSystem = args.buildSystem;
    src = src;
    patches = patches;
    postInstall = [[ln -s bash "$out/bin/sh"]];

    configureFlags = configureFlags;
  }
end

for _, system in ipairs(systems.stdlibSystems) do
  local system <const> = system
  module[system] = tables.lazyModule {
    bootstrap = function()
      local version <const> = "5.2.15"

      local sys <const> = systems.parse(system)
      if sys and sys.isLinux then
        local seeds <const> = import "../../bootstrap/seeds.lua"
        return derivation {
          name = "bash-"..version;
          pname = "bash";
          version = version;

          system = system;
          builder = seeds[system].busybox.."/bin/sh";
          args = { path "build.sh" };

          src = module.tarballs[version];
          patches = patches;

          PATH = strings.makeBinPath {
            gnumake[system].bootstrap,
            seeds[system].busybox,
            gcc[system].bootstrap,
          };
          LDFLAGS = { "-static" };
          SOURCE_DATE_EPOCH = 0;
          KBUILD_BUILD_TIMESTAMP = "@0";
        }
      elseif sys and sys.isMacOS then
        return derivation {
          name = "bash-"..version;
          pname = "bash";
          version = version;

          system = system;
          builder = "/bin/sh";
          args = { path "build.sh" };

          src = module.tarballs[version];
          patches = patches;

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
        version = "5.2.15";
      }
    end;
  }
end

return module
