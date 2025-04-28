-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

---@param s string
---@param prefix string
---@return boolean
local function hasPrefix(s, prefix)
  return s:sub(1, #prefix) == prefix
end

---@param s string
---@return boolean
local function isUnknown(s)
  return s == "" or s == "unknown"
end

---@param arch string
---@return boolean
local function isX8632(arch)
  return arch == "i386" or
      arch == "i486" or
      arch == "i586" or
      arch == "i686" or
      arch == "i786" or
      arch == "i886" or
      arch == "i986"
end

---@param arch string
---@return boolean
local function isX8664(arch)
  return arch == "x86_64" or
      arch == "amd64" or
      arch == "x86_64h"
end

---@param arch string
---@return boolean
local function isARM32(arch)
  return arch == "arm"
end

---@param arch string
---@return boolean
local function isARM64(arch)
  return arch == "aarch64" or arch == "arm64"
end

---@param arch string
---@return boolean
local function isRISCV32(arch)
  return arch == "riscv32"
end

---@param arch string
---@return boolean
local function isRISCV64(arch)
  return arch == "riscv64"
end

---@param os string
---@return boolean
local function isMacOS(os)
  return hasPrefix(os, "darwin") or hasPrefix(os, "macos")
end

---@param os string
---@return boolean
local function isiOS(os)
  return hasPrefix(os, "ios")
end

---@param os string
---@return boolean
local function isDarwin(os)
  return isMacOS(os) or isiOS(os)
end

---@param os string
---@return boolean
local function isWindows(os)
  return hasPrefix(os, "windows") or hasPrefix(os, "win32")
end

---@param os string
---@return boolean
local function isLinux(os)
  return hasPrefix(os, "linux")
end

---@param os string
---@return boolean
local function isKnownOS(os)
  return isLinux(os) or isWindows(os) or isDarwin(os)
end

---@param os string
---@return string
local function defaultVendor(os)
  if isDarwin(os) then
    return "apple"
  elseif isWindows(os) then
    return "pc"
  else
    return "unknown"
  end
end

---@param os string
---@return string
local function defaultEnvironment(os)
  if isWindows(os) then
    return "msvc"
  else
    return "unknown"
  end
end

---@param x any
---@return boolean
local function isEmptyOrNil(x)
  return x == nil or x == ""
end

---@param s string
---@return boolean
local function isCygwin(s)
  return hasPrefix(s, "cygwin")
end

---@param s string
---@return boolean
local function isMinGW32(s)
  return hasPrefix(s, "mingw")
end

---@class system
---@field arch string
---@field vendor string
---@field os string
---@field env string
---@field is32Bit boolean
---@field is64Bit boolean
---@field isX86 boolean
---@field isARM boolean
---@field isRISCV boolean
---@field isMacOS boolean
---@field isiOS boolean
---@field isDarwin boolean
---@field isLinux boolean
---@field isWindows boolean
local systemMetatable = {
  __name = "system";
}

---Parses a system string into a system,
---or returns nil if the string is not a valid system value.
---@param s string
---@return system|nil
function parse(s)
  local parts = {}
  for part in s:gmatch("[^-]*") do
    if #parts >= 4 then
      return nil
    end
    parts[#parts + 1] = part
  end
  local hasTrailing = false
  for i = #parts, 1, -1 do
    if isCygwin(parts[i]) or isMinGW32(parts[i]) then
      if hasTrailing then return nil end
      hasTrailing = true
    elseif isEmptyOrNil(parts[i]) then
      hasTrailing = true
    end
  end

  if #parts == 1 then
    return nil
  elseif #parts == 2 then
    parts[2], parts[3] = "", parts[2]
  elseif #parts == 3 and (isKnownOS(parts[2]) or parts[2] == "none") then
    parts[2], parts[3], parts[4] = "", parts[2], parts[3]
  end

  -- Expand Cygwin/MinGW first, since that can trigger other implications.
  if isCygwin(parts[3]) then
    parts[3] = "windows"
    parts[4] = "cygnus"
  elseif isMinGW32(parts[3]) then
    parts[3] = "windows"
    parts[4] = "gnu"
  end

  -- Now fill in the system based on the parts.
  local arch = "unknown"
  local vendor = "unknown"
  local os = "unknown"
  local env = "unknown"
  if not isEmptyOrNil(parts[1]) then
    arch = parts[1]
  end
  if not isEmptyOrNil(parts[3]) then
    os = parts[3]
  end
  if not isEmptyOrNil(parts[2]) then
    vendor = parts[2]
  else
    vendor = defaultVendor(os)
  end
  if not isEmptyOrNil(parts[4]) then
    env = parts[4]
  else
    env = defaultEnvironment(os)
  end

  return setmetatable({
    arch = arch;
    os = os;
    vendor = vendor;
    env = env;

    is32Bit = isX8632(arch) or isARM32(arch) or isRISCV32(arch);
    is64Bit = isX8664(arch) or isARM64(arch) or isRISCV64(arch);
    isX86 = isX8632(arch) or isX8664(arch);
    isARM = isARM32(arch) or isARM64(arch);
    isRISCV = isRISCV32(arch) or isRISCV64(arch);

    isMacOS = isMacOS(os);
    isiOS = isiOS(os);
    isDarwin = isDarwin(os);
    isLinux = isLinux(os);
    isWindows = isWindows(os);
  }, systemMetatable)
end

local function toUnknown(x)
  if x == nil or x == "" then
    return "unknown"
  end
  return x
end

---Converts a system-like table into a system string value.
---@param sys {
---arch: string,
---vendor: string,
---os: string,
---env: string,
---}
---@return string
function tostring(sys)
  if isLinux(sys.os) and isUnknown(sys.vendor) and isUnknown(sys.env) then
    return toUnknown(sys.arch).."-"..toUnknown(sys.os)
  elseif isWindows(sys.os) and hasPrefix(sys.env, "cygnus") then
    return toUnknown(sys.arch).."-"..toUnknown(sys.vendor).."-cygwin"
  elseif toUnknown(sys.env) == defaultEnvironment(sys.os) then
    return toUnknown(sys.arch).."-"..toUnknown(sys.vendor).."-"..toUnknown(sys.os)
  else
    return toUnknown(sys.arch).."-"..toUnknown(sys.vendor).."-"..toUnknown(sys.os).."-"..toUnknown(sys.env)
  end
end

systemMetatable.__tostring = tostring
