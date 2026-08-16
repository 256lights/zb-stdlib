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
          parts[#parts + 1] = part
        end
      end
    end
  end
  return table.concat(parts, sep)
end

---@param system string
---@param bash string|derivation
---@param deps string|derivation[]
---@param args {
---pname: string?,
---version: string?,
---builder: string|derivation?,
---realBuilder: string|derivation?,
---args: (string|derivation|number|boolean)[]?,
---[string]: string|derivation|number|boolean|(string|derivation|number|boolean)[],
---}
---@return table<string, string>
local function makeDerivation(system, bash, deps, args)
  args = tables.clone(args)
  args.system = system
  args.PATH = concatStringLists(":", args.PATH, strings.makeBinPath(system, deps))
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
  args.builder = args.realBuilder or strings.defaultOutput(bash, system).."/bin/bash"
  if not args.SOURCE_DATE_EPOCH then
    args.SOURCE_DATE_EPOCH = 0
  end
  if not args.KBUILD_BUILD_TIMESTAMP then
    args.KBUILD_BUILD_TIMESTAMP = "@0"
  end
  return outputs(derivation(args), system)
end

---Build a derivation using the bootstrap toolchain.
---@param args {
---pname: string?,
---version: string?,
---builder: string|derivation?,
---realBuilder: string|derivation?,
---args: (string|derivation|number|boolean)[]?,
---[string]: string|derivation|number|boolean|(string|derivation|number|boolean)[],
---}
---@return table
function module.makeBootstrapDerivation(args)
  return tables.withOutputs(args, function(args, buildSystemString)
    local buildSystem = systems.parse(buildSystemString)
    local gnumake = import("../packages/gnumake/gnumake.lua").bootstrap
    local bash = import("../packages/bash/bash.lua").bootstrap
    if buildSystem.isLinux then
      local gcc = import("../packages/gcc/gcc.lua").bootstrap
      local busybox = import("../bootstrap/seeds.lua")[buildSystemString].busybox
      return makeDerivation(buildSystemString, bash, { gcc, gnumake, bash, busybox }, args)
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
      return makeDerivation(buildSystemString, bash, deps, args)
    else
      error(string.format("unsupported system = %s", buildSystemString))
    end
  end)
end

local function baseDeps()
  local bash = import("../packages/bash/bash.lua").stdenv
  return bash, {
    assert(bash),
    assert(import("../packages/bzip2/bzip2.lua").stdenv),
    assert(import("../packages/coreutils/coreutils.lua").stdenv),
    assert(import("../packages/diffutils/diffutils.lua").stdenv),
    assert(import("../packages/findutils/findutils.lua").stdenv),
    assert(import("../packages/gawk/gawk.lua").stdenv),
    assert(import("../packages/gnugrep/gnugrep.lua").stdenv),
    assert(import("../packages/gnumake/gnumake.lua").stdenv),
    assert(import("../packages/gnupatch/gnupatch.lua").stdenv),
    assert(import("../packages/gnused/gnused.lua").stdenv),
    assert(import("../packages/gnutar/gnutar.lua").stdenv),
    assert(import("../packages/gzip/gzip.lua").stdenv),
    assert(import("../packages/unzip/unzip.lua").stdenv),
    assert(import("../packages/xz/xz.lua").stdenv),
  }
end

---Build a derivation using the standard environment without a C compiler.
---@param args {
---pname: string?,
---version: string?,
---builder: string|derivation?,
---realBuilder: string|derivation?,
---args: (string|derivation|number|boolean)[]?,
---[string]: string|derivation|number|boolean|(string|derivation|number|boolean)[],
---}
---@return table
function module.makeDerivationNoCC(args)
  return tables.withOutputs(args, function(args, system)
    local bash, deps = baseDeps()
    return makeDerivation(system, bash, deps, args)
  end)
end

---Build a derivation using the standard environment.
---@param args {
---pname: string?,
---version: string?,
---builder: string|derivation?,
---realBuilder: string|derivation?,
---args: (string|derivation|number|boolean)[]?,
---[string]: string|derivation|number|boolean|(string|derivation|number|boolean)[],
---}
---@return table
function module.makeDerivation(args)
  return tables.withOutputs(args, function(args, buildSystemString)
    local bash, deps = baseDeps()
    local buildSystem = systems.parse(buildSystemString)
    if buildSystem.isMacOS then
      deps[#deps + 1] = "/Library/Developer/CommandLineTools/usr"
      args = tables.clone(args)
      args.SDKROOT = args.SDKROOT or "/Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk"
      args.__buildSystemDeps = concatStringLists(" ", args.__buildSystemDeps, "/Library/Developer/CommandLineTools")
    else
      deps[#deps + 1] = import("../packages/gcc/gcc.lua").bootstrap
    end
    return makeDerivation(buildSystemString, bash, deps, args)
  end)
end

return module
