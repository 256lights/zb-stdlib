-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local tables <const> = import "../tables.lua"

local seeds <const> = {
  ["x86_64-unknown-linux"] = {
    gcc = "/opt/zb/store/6ssl5z26zmr9dn2iz4xi17a13ia7qz8y-gcc-4.2.1";
    busybox = "/opt/zb/store/hpsxd175dzfmjrg27pvvin3nzv3yi61k-busybox-1.36.1";
  };
}

return tables.map(function(t)
  return tables.lazyMap(storePath, t)
end, seeds)
