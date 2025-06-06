-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

--- baseNameOf returns the last element of path.
--- Trailing slashes are removed before extracting the last element.
--- If the path is empty, baseNameOf returns "".
--- If the path consists entirely of slashes, baseNameOf returns "/".
---@param path string slash-separated path
---@return string
function baseNameOf(path)
  if path == "" then return "." end
  local base = path:match("([^/]*)/*$")
  -- If empty now, it had only slashes.
  if base == "" then return path:sub(1, 1) end
  return base
end

---Returns a function that, each time it is called,
---returns the next substring separated by a separator
---along with its index in the string.
---@param s string
---@param sep string
---@return fun(string, number): number|nil,string|nil
---@return string
---@return number
function split(s, sep)
  ---@param s string
  ---@param i number
  ---@return number|nil
  ---@return string|nil
  local function next(s, i)
    if i > #s + 1 then return end
    local j = s:find(sep, i, true)
    if j then
      return j + #sep, s:sub(i, j - 1)
    else
      return #s + 2, s:sub(i)
    end
  end
  return next, s, 1
end

---Construct a Unix-style search path by appending `subDir`
---to the specified `output` of each of the packages.
---@param output string
---@param subDir string
---@param paths (derivation|string)[]
---@return string
function makeSearchPathOutput(output, subDir, paths)
  local parts = {}
  for i, x in ipairs(paths) do
    local xout
    if type(x) == "string" then
      xout = x
    else
      xout = x[output] or x.out
    end
    if xout then
      if #parts > 0 then
        parts[#parts + 1] = ":"
      end
      parts[#parts + 1] = tostring(xout)
      parts[#parts + 1] = "/"
      parts[#parts + 1] = subDir
    end
  end
  return table.concat(parts)
end

---Construct a binary search path (such as `$PATH`)
---containing the binaries for a set of packages.
---@param pkgs derivation[]
---@return string # colon-separated paths
function makeBinPath(pkgs)
  return makeSearchPathOutput("out", "bin", pkgs)
end

---@param pkgs derivation[]
---@return string
function makeIncludePath(pkgs)
  return makeSearchPathOutput("dev", "include", pkgs)
end

---@param pkgs derivation[]
---@return string
function makeLibraryPath(pkgs)
  return makeSearchPathOutput("out", "lib", pkgs)
end

---@param name string
---@return {name: string, version: string}
local function parseDrvName(name)
  local base, version = name:match("(.*)-([^a-zA-Z].*)")
  return {
    name = base or name;
    version = version or "";
  }
end

---Extracts the derivation's base name from the argument.
---@param drvOrName derivation|string a derivation or a derivation's name field
---@return string
function getName(drvOrName)
  local name
  if type(drvOrName) == "string" then
    name = drvOrName
  else
    name = drvOrName.name
  end
  return parseDrvName(name).name
end

---Extracts the derivation's version from the argument.
---@param drvOrName derivation|string a derivation or a derivation's name field
---@return string
function getVersion(drvOrName)
  local name
  if type(drvOrName) == "string" then
    name = drvOrName
  else
    name = drvOrName.name
  end
  return parseDrvName(name).version
end
