
local config = require("hlargs.config")

local M = {}

M.get_color = function(idx)
  local config = config.opts
  local size = #config.colorpalette
  local current_color = idx % size

  local color = { idx = current_color, color = config.colorpalette[current_color], hl_group = "Hlarg" .. current_color }
  return color
end

return M
