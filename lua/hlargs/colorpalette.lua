local config = require("hlargs.config")

local M = {}

-- https://cp-algorithms.com/string/string-hashing.html
local P = 103
local MAX_INT = 1e9 + 9

local hash_arg = function(arg_name)
  local hash_value = 0
  local p_pow = 1
  for i = 1, #arg_name do
    local ascii = arg_name:byte(i)
    hash_value = (hash_value + ascii * p_pow) % MAX_INT
    p_pow = (p_pow * P) % MAX_INT
  end
  return hash_value
end

M.get_hlgroup = function(arg_name)
  local config = config.opts
  local size = #config.colorpalette
  local idx = hash_arg(arg_name)
  local current_color = idx % size

  return "Hlarg" .. tonumber(current_color)
end

return M
