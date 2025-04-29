-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local strings <const> = import "../strings.lua"
local tables <const> = import "../tables.lua"

local module <const> = {}

module.builderScript = path "builder.sh"

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
  local binPath = strings.makeBinPath(deps)
  local argsPath = args.PATH
  local argsPathType = type(argsPath)
  if argsPathType == "table" then
    binPath = table.concat(argsPath, ":")..":"..binPath
  elseif argsPathType ~= "nil" then
    binPath = argsPath..":"..binPath
  end

  args = tables.clone(args)
  args.system = args.buildSystem
  args.PATH = binPath
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
  local gcc = import("../packages/gcc/gcc.lua")[args.buildSystem].bootstrap
  local gnumake = import("../packages/gnumake/gnumake.lua")[args.buildSystem].bootstrap
  local busybox = import("../bootstrap/seeds.lua")[args.buildSystem].busybox
  local bash = import("../packages/bash/bash.lua")[args.buildSystem].bootstrap
  return makeDerivation(bash, { gcc, gnumake, bash, busybox }, args)
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
  deps[#deps+1] = import("../packages/gcc/gcc.lua")[args.buildSystem].bootstrap
  return makeDerivation(bash, deps, args)
end

return module
