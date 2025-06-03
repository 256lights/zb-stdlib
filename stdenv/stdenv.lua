-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local strings <const> = import "../strings.lua"
local systems <const> = import "../systems.lua"
local tables <const> = import "../tables.lua"

local module <const> = {}

module.builderScript = path "builder.sh"
module.helpersNix = path "helpers-nix.sh"
module.systems = systems.stdlibSystems

---@param sep string
---@param ... string
---@return string
local function concatStringLists(sep, ...)
  local parts = {}
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    local argType = type(arg)
    if argType == "table" then
      table.move(arg, 1, #arg, #parts + 1, parts)
    elseif argType ~= "nil" then
      for _, part in strings.split(tostring(arg), sep) do
        if part ~= "" then
          parts[#parts+1] = part
        end
      end
    end
  end
  return table.concat(parts, sep)
end

---@param bash string|derivation
---@param deps string|derivation[]
---@param args {
---pname: string?,
---version: string?,
---buildSystem: string,
---builder: string|derivation?,
---realBuilder: string|derivation?,
---args: (string|derivation|number|boolean)[]?,
---[string]: string|derivation|number|boolean|(string|derivation|number|boolean)[],
---}
---@return derivation
local function makeDerivation(bash, deps, args)
  args = tables.clone(args)
  args.system = args.buildSystem
  args.PATH = concatStringLists(":", args.PATH, strings.makeBinPath(deps))
  if not args.name then
    local name = args.pname
    if not name then
      error("makeDerivation: name or pname must be present", 2)
    end
    local version = args.version
    if version and version ~= "" then
      name = name.."-"..version
    end
    args.name = name
  end
  args.helpersNix = args.helpersNix or module.helpersNix
  args.args = args.args or { args.builder or module.builderScript }
  args.builder = args.realBuilder or bash.."/bin/bash"
  if not args.SOURCE_DATE_EPOCH then
    args.SOURCE_DATE_EPOCH = 0
  end
  if not args.KBUILD_BUILD_TIMESTAMP then
    args.KBUILD_BUILD_TIMESTAMP = "@0"
  end
  return derivation(args)
end

---Build a derivation using the bootstrap toolchain.
---@param args {
---pname: string?,
---version: string?,
---buildSystem: string,
---builder: string|derivation?,
---realBuilder: string|derivation?,
---args: (string|derivation|number|boolean)[]?,
---[string]: string|derivation|number|boolean|(string|derivation|number|boolean)[],
---}
---@return derivation
function module.makeBootstrapDerivation(args)
  local buildSystem = systems.parse(args.buildSystem)
  local gnumake = import("../packages/gnumake/gnumake.lua")[args.buildSystem].bootstrap
  local bash = import("../packages/bash/bash.lua")[args.buildSystem].bootstrap
  if buildSystem.isLinux then
    local gcc = import("../packages/gcc/gcc.lua")[args.buildSystem].bootstrap
    local busybox = import("../bootstrap/seeds.lua")[args.buildSystem].busybox
    return makeDerivation(bash, { gcc, gnumake, bash, busybox }, args)
  elseif buildSystem.isMacOS then
    local deps = {
      gnumake,
      bash,
      "/Library/Developer/CommandLineTools/usr",
      "/usr",
      "/",
    }
    args = tables.clone(args)
    args.SDKROOT = args.SDKROOT or "/Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk"
    args.__buildSystemDeps = concatStringLists(" ", args.__buildSystemDeps, {
      "/Library/Developer/CommandLineTools",
      "/usr",
      "/bin",
    })
    return makeDerivation(bash, deps, args)
  else
    error(string.format("unsupported buildSystem = %s", args.buildSystem))
  end
end

local function baseDeps(buildSystem)
  local bash = import("../packages/bash/bash.lua")[buildSystem].stdenv
  return bash, {
    assert(bash),
    assert(import("../packages/bzip2/bzip2.lua")[buildSystem].stdenv),
    assert(import("../packages/coreutils/coreutils.lua")[buildSystem].stdenv),
    assert(import("../packages/diffutils/diffutils.lua")[buildSystem].stdenv),
    assert(import("../packages/findutils/findutils.lua")[buildSystem].stdenv),
    assert(import("../packages/gawk/gawk.lua")[buildSystem].stdenv),
    assert(import("../packages/gnugrep/gnugrep.lua")[buildSystem].stdenv),
    assert(import("../packages/gnumake/gnumake.lua")[buildSystem].stdenv),
    assert(import("../packages/gnupatch/gnupatch.lua")[buildSystem].stdenv),
    assert(import("../packages/gnused/gnused.lua")[buildSystem].stdenv),
    assert(import("../packages/gnutar/gnutar.lua")[buildSystem].stdenv),
    assert(import("../packages/gzip/gzip.lua")[buildSystem].stdenv),
    assert(import("../packages/xz/xz.lua")[buildSystem].stdenv),
  }
end

---Build a derivation using the standard environment without a C compiler.
---@param args {
---pname: string?,
---version: string?,
---buildSystem: string,
---builder: string|derivation?,
---realBuilder: string|derivation?,
---args: (string|derivation|number|boolean)[]?,
---[string]: string|derivation|number|boolean|(string|derivation|number|boolean)[],
---}
---@return derivation
function module.makeDerivationNoCC(args)
  local bash, deps = baseDeps(args.buildSystem)
  return makeDerivation(bash, deps, args)
end

---Build a derivation using the standard environment.
---@param args {
---pname: string?,
---version: string?,
---buildSystem: string,
---builder: string|derivation?,
---realBuilder: string|derivation?,
---args: (string|derivation|number|boolean)[]?,
---[string]: string|derivation|number|boolean|(string|derivation|number|boolean)[],
---}
---@return derivation
function module.makeDerivation(args)
  local bash, deps = baseDeps(args.buildSystem)
  local buildSystem = systems.parse(args.buildSystem)
  if buildSystem.isMacOS then
    deps[#deps+1] = "/Library/Developer/CommandLineTools/usr"
    args = tables.clone(args)
    args.SDKROOT = args.SDKROOT or "/Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk"
    args.__buildSystemDeps = concatStringLists(" ", args.__buildSystemDeps, "/Library/Developer/CommandLineTools")
  else
    deps[#deps+1] = import("../packages/gcc/gcc.lua")[args.buildSystem].bootstrap
  end
  return makeDerivation(bash, deps, args)
end

return module
