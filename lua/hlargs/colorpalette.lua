local current_color = 1

local config = require("hlargs.config")

local M = {}

M.get_color = function()
  local config = config.opts
  if current_color > #config.colorpalette then
    current_color = 1
  end
  print(current_color)
  local color = { idx = current_color, color = config.colorpalette[current_color], hl_group = "Hlarg" .. current_color }
  current_color = current_color + 1
  print(vim.inspect(color))
  return color
end

return M
