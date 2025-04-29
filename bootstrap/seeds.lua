-- Copyright 2025 The zb Authors
-- SPDX-License-Identifier: MIT

local tables <const> = import "../tables.lua"

local seeds <const> = {
  ["x86_64-unknown-linux"] = {
    gcc = "/zb/store/9n2ccy3mcsb04q47npp28jwkd9py3wdj-gcc-4.2.1";
    busybox = "/zb/store/z5yrbqk8sjlzyvw8wpicsn2ybk0sc470-busybox-1.36.1";
  };
}

return tables.map(function(t)
  return tables.lazyMap(storePath, t)
end, seeds)
